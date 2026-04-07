import 'dart:async';

import 'package:app/models/app_notification.dart';
import 'package:app/screens/add_transaction_screen.dart';
import 'package:app/screens/budget_screen.dart';
import 'package:app/screens/notifications_screen.dart';
import 'package:app/screens/saving_goals_screen.dart';
import 'package:app/utils/app_navigation.dart';
import 'package:app/utils/runtime_schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationService extends ChangeNotifier with WidgetsBindingObserver {
  static const Duration _headsUpInitialDelay = Duration(milliseconds: 2500);
  static const Duration _headsUpVisibleDuration = Duration(milliseconds: 2500);
  static const Duration _headsUpGapDuration = Duration(milliseconds: 2500);

  NotificationService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance {
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = _auth.authStateChanges().listen(_handleAuthChanged);
    _handleAuthChanged(_auth.currentUser);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notificationSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _broadcastSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _budgetSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _transactionSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _savingGoalSubscription;
  Timer? _syncDebounceTimer;
  Timer? _broadcastTransitionTimer;
  Timer? _headsUpTimer;
  Timer? _headsUpGateTimer;
  Timer? _dayRolloverTimer;

  String? _currentUserId;
  List<AppNotification> _notifications = const <AppNotification>[];
  AppNotification? _currentHeadsUp;
  bool _appNotificationsEnabled = true;
  DateTime? _headsUpBlockedUntil;
  final List<AppNotification> _headsUpQueue = <AppNotification>[];
  final Set<String> _queuedHeadsUpIds = <String>{};
  final Set<String> _sessionShownIds = <String>{};

  List<AppNotification> get notifications => _notifications;
  AppNotification? get currentHeadsUp => _currentHeadsUp;
  bool get hasUnread =>
      _notifications.any((item) => item.isUnread && _isNotificationVisible(item));
  bool get isSignedIn => _currentUserId != null;
  bool get appNotificationsEnabled => _appNotificationsEnabled;

  List<AppNotification> get activeNotifications {
    final now = DateTime.now();
    final items = _notifications
        .where((item) => item.isActiveAt(now))
        .where(_isNotificationVisible)
        .toList(growable: false);
    items.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return items;
  }

  Future<void> openNotificationsScreen({String? initialNotificationId}) async {
    await syncNow();
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          initialNotificationId: initialNotificationId,
        ),
      ),
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final ref = _notificationDoc(notificationId);
    if (ref == null) return;
    final readAt = DateTime.now();
    await ref.set(<String, dynamic>{
      'readAt': Timestamp.fromDate(readAt),
    }, SetOptions(merge: true));
    _updateLocalNotification(
      notificationId,
      (current) => current.copyWith(readAt: readAt),
    );
  }

  Future<void> suppressForToday(String notificationId) async {
    final ref = _notificationDoc(notificationId);
    if (ref == null) return;
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day + 1);
    await ref.set(<String, dynamic>{
      'suppressedUntil': Timestamp.fromDate(endOfDay),
    }, SetOptions(merge: true));
    _updateLocalNotification(
      notificationId,
      (current) => current.copyWith(suppressedUntil: endOfDay),
    );
  }

  Future<void> openNotificationAction(AppNotification notification) async {
    Widget? screen;
    switch (notification.actionType) {
      case AppNotificationActionType.budget:
        screen = const BudgetScreen();
        break;
      case AppNotificationActionType.savings:
        screen = const SavingGoalsScreen();
        break;
      case AppNotificationActionType.addTransaction:
        screen = const AddTransactionScreen();
        break;
      case AppNotificationActionType.none:
        screen = null;
        break;
    }

    final navigator = appNavigatorKey.currentState;
    if (screen == null || navigator == null) return;
    await navigator.push(MaterialPageRoute(builder: (_) => screen!));
  }

  Future<void> syncNow() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _syncBroadcastNotifications(userId);
      if (_appNotificationsEnabled) {
        await _syncBudgetNotifications(userId);
        await _syncDailyNotifications(userId);
      }
      _scheduleDayRolloverSync();
    } catch (error, stackTrace) {
      debugPrint('Notification sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _notificationSubscription?.cancel();
    _userSubscription?.cancel();
    _broadcastSubscription?.cancel();
    _budgetSubscription?.cancel();
    _transactionSubscription?.cancel();
    _savingGoalSubscription?.cancel();
    _syncDebounceTimer?.cancel();
    _broadcastTransitionTimer?.cancel();
    _headsUpTimer?.cancel();
    _headsUpGateTimer?.cancel();
    _dayRolloverTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyHeadsUpEntryDelay();
      unawaited(syncNow());
    }
  }

  Future<void> _handleAuthChanged(User? user) async {
    await _clearListeners();

    _currentUserId = user?.uid;
    _notifications = const <AppNotification>[];
    _currentHeadsUp = null;
    _appNotificationsEnabled = true;
    _headsUpBlockedUntil = null;
    _headsUpQueue.clear();
    _queuedHeadsUpIds.clear();
    _sessionShownIds.clear();
    notifyListeners();

    if (user == null) {
      return;
    }

    _applyHeadsUpEntryDelay();

    _notificationSubscription = _notificationsCollection(user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(_handleNotificationSnapshot);

    _userSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(_handleUserSnapshot);

    _broadcastSubscription = _firestore
        .collection('system_broadcasts')
        .snapshots()
        .listen((_) => _scheduleSync());

    _budgetSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .snapshots()
        .listen((_) => _scheduleSync());

    _transactionSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .snapshots()
        .listen((_) => _scheduleSync());

    _savingGoalSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saving_goals')
        .snapshots()
        .listen((_) => _scheduleSync());

    _scheduleSync(immediate: true);
  }

  Future<void> _clearListeners() async {
    await _notificationSubscription?.cancel();
    await _userSubscription?.cancel();
    await _broadcastSubscription?.cancel();
    await _budgetSubscription?.cancel();
    await _transactionSubscription?.cancel();
    await _savingGoalSubscription?.cancel();
    _notificationSubscription = null;
    _userSubscription = null;
    _broadcastSubscription = null;
    _budgetSubscription = null;
    _transactionSubscription = null;
    _savingGoalSubscription = null;
    _syncDebounceTimer?.cancel();
    _broadcastTransitionTimer?.cancel();
    _headsUpTimer?.cancel();
    _headsUpGateTimer?.cancel();
    _dayRolloverTimer?.cancel();
  }

  void _scheduleSync({bool immediate = false}) {
    _syncDebounceTimer?.cancel();
    if (immediate) {
      unawaited(syncNow());
      return;
    }
    _syncDebounceTimer = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(syncNow()),
    );
  }

  void _handleNotificationSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final items = snapshot.docs
        .map((doc) => AppNotification.fromFirestore(doc.id, doc.data()))
        .toList(growable: false);
    _notifications = items;
    _enqueueHeadsUpNotifications();
    notifyListeners();
  }

  void _handleUserSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final preferences =
        data['notificationPreferences'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final enabled = preferences['appNotificationsEnabled'] != false;
    if (_appNotificationsEnabled == enabled) {
      return;
    }

    _appNotificationsEnabled = enabled;
    _headsUpQueue.removeWhere((item) => !_isNotificationVisible(item));
    _queuedHeadsUpIds
      ..clear()
      ..addAll(_headsUpQueue.map((item) => item.id));
    if (_currentHeadsUp != null && !_isNotificationVisible(_currentHeadsUp!)) {
      _currentHeadsUp = null;
      _headsUpTimer?.cancel();
    }
    _processHeadsUpQueue();
    notifyListeners();
  }

  void _enqueueHeadsUpNotifications() {
    final now = DateTime.now();
    final blockedUntil = _headsUpBlockedUntil;
    if (blockedUntil != null && now.isBefore(blockedUntil)) {
      _scheduleHeadsUpGate(blockedUntil.difference(now));
      return;
    }
    for (final item in _notifications) {
      if (!item.isActiveAt(now) ||
          item.isSuppressedAt(now) ||
          !_isNotificationVisible(item)) {
        continue;
      }
      final alreadyShown = item.isSystemNotification
          ? item.headsUpShownAt != null
          : _sessionShownIds.contains(item.id);
      if (alreadyShown || _queuedHeadsUpIds.contains(item.id)) {
        continue;
      }
      _headsUpQueue.add(item);
      _queuedHeadsUpIds.add(item.id);
      if (!item.isSystemNotification) {
        _sessionShownIds.add(item.id);
      }
    }
    _processHeadsUpQueue();
  }

  void _processHeadsUpQueue() {
    if (_currentHeadsUp != null || _headsUpQueue.isEmpty) {
      return;
    }

    final next = _headsUpQueue.removeAt(0);
    _currentHeadsUp = next;
    notifyListeners();
    unawaited(_markHeadsUpShown(next.id));

    _headsUpTimer?.cancel();
    _headsUpTimer = Timer(_headsUpVisibleDuration, () {
      _currentHeadsUp = null;
      notifyListeners();
      _scheduleHeadsUpGate(_headsUpGapDuration);
    });
  }

  Future<void> _markHeadsUpShown(String notificationId) async {
    final ref = _notificationDoc(notificationId);
    if (ref == null) return;
    await ref.set(<String, dynamic>{
      'headsUpShownAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  CollectionReference<Map<String, dynamic>> _notificationsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('notifications');
  }

  DocumentReference<Map<String, dynamic>>? _notificationDoc(String notificationId) {
    final userId = _currentUserId;
    if (userId == null) return null;
    return _notificationsCollection(userId).doc(notificationId);
  }

  Future<void> _syncBroadcastNotifications(String userId) async {
    final snapshot = await _firestore.collection('system_broadcasts').get();
    final activeNotificationIds = <String>{};
    final now = DateTime.now();
    final transitionCandidates = <DateTime?>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      transitionCandidates.add(nextBroadcastTransitionAt(data, now: now));
      if (!isBroadcastVisible(data, now: now)) {
        continue;
      }
      final broadcastId = doc.id;
      final title = (data['title']?.toString().trim() ?? '');
      final body = (data['content']?.toString().trim() ?? '');
      final createdAt =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final updatedAt =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? createdAt;
      final fingerprint = _slug(
        '${title.toLowerCase()}|${body.toLowerCase()}|${data['type']?.toString() ?? 'info'}',
      );
      final notificationId = 'system_$fingerprint';
      final sourceEventKey = '$broadcastId:${updatedAt.millisecondsSinceEpoch}';
      final notification = AppNotification(
        id: notificationId,
        sourceType: AppNotificationSourceType.system,
        shortTitle: 'Thông báo từ hệ thống',
        detailTitle: title.isNotEmpty ? title : 'Thông báo từ hệ thống',
        body: body,
        severity: _mapBroadcastSeverity(data['type']?.toString()),
        createdAt: updatedAt,
        actionType: _inferBroadcastAction(body),
        actionLabel: _inferBroadcastActionLabel(body),
        broadcastId: broadcastId,
        sourceEventKey: sourceEventKey,
      );
      activeNotificationIds.add(notificationId);
      await _upsertBroadcastNotification(userId, notification);
    }

    final staleSystemNotifications = _notifications.where(
      (item) => item.isSystemNotification && !activeNotificationIds.contains(item.id),
    );
    for (final item in staleSystemNotifications) {
      await _hideNotification(userId, item.id);
    }

    _scheduleBroadcastTransitionSync(earliestTransition(transitionCandidates));
  }

  Future<void> _syncBudgetNotifications(String userId) async {
    final now = DateTime.now();
    final dayKey = _dayKey(now);
    final startOfDay = DateTime(now.year, now.month, now.day);
    final monthyear = '${now.month} ${now.year}';
    final budgetsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .where('monthyear', isEqualTo: monthyear)
        .get();
    final txSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('monthyear', isEqualTo: monthyear)
        .where('type', isEqualTo: 'debit')
        .get();

    final spentByCategory = <String, int>{};
    for (final doc in txSnapshot.docs) {
      final data = doc.data();
      final category = data['category']?.toString() ?? 'Khác';
      final amount = (data['amount'] as num?)?.toInt() ?? 0;
      spentByCategory.update(category, (value) => value + amount, ifAbsent: () => amount);
    }

    for (final doc in budgetsSnapshot.docs) {
      final data = doc.data();
      final category = data['categoryName']?.toString() ?? 'Khác';
      final limit = (data['limitAmount'] as num?)?.toInt() ?? 0;
      final spent = spentByCategory[category] ?? 0;
      if (limit <= 0) continue;

      final baseId = _slug('${dayKey}_${monthyear}_$category');
      final warningId = 'budget_warning_$baseId';
      final exceededId = 'budget_exceeded_$baseId';
      final percentage = spent / limit;

      if (spent > limit) {
        await _expireNotificationById(userId, warningId);
        await _upsertNotification(
          userId,
          AppNotification(
            id: exceededId,
            sourceType: AppNotificationSourceType.budgetExceeded,
            shortTitle: 'Cảnh báo ngân sách',
            detailTitle: 'Bạn đã vượt ngân sách $category',
            body:
                'Chi tiêu cho $category đã vượt ${spent - limit} VND so với hạn mức tháng này.',
            severity: AppNotificationSeverity.danger,
            createdAt: now,
            actionType: AppNotificationActionType.budget,
            actionLabel: 'Xem ngân sách',
            effectiveDate: startOfDay,
          ),
        );
      } else if (percentage >= 0.8) {
        await _expireNotificationById(userId, exceededId);
        await _upsertNotification(
          userId,
          AppNotification(
            id: warningId,
            sourceType: AppNotificationSourceType.budgetWarning,
            shortTitle: 'Cảnh báo ngân sách',
            detailTitle: 'Ngân sách $category sắp chạm mức',
            body:
                'Bạn đã dùng ${(percentage * 100).round()}% ngân sách $category trong tháng này.',
            severity: AppNotificationSeverity.warning,
            createdAt: now,
            actionType: AppNotificationActionType.budget,
            actionLabel: 'Xem ngân sách',
            effectiveDate: startOfDay,
          ),
        );
      } else {
        await _expireNotificationById(userId, warningId);
        await _expireNotificationById(userId, exceededId);
      }
    }
  }

  Future<void> _syncDailyNotifications(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    await _deleteYesterdayAppNotifications(userId, startOfDay);

    final txSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch,
        )
        .where('timestamp', isLessThan: endOfDay.millisecondsSinceEpoch)
        .limit(1)
        .get();

    final dailyTransactionId =
        'daily_tx_${startOfDay.toIso8601String().substring(0, 10)}';
    if (txSnapshot.docs.isEmpty) {
      await _upsertNotification(
        userId,
        AppNotification(
          id: dailyTransactionId,
          sourceType: AppNotificationSourceType.dailyTransactionReminder,
          shortTitle: 'Thông báo từ ứng dụng',
          detailTitle: 'Hôm nay bạn chưa nhập giao dịch',
          body: 'Hãy ghi lại ít nhất một giao dịch để số liệu hôm nay luôn đầy đủ.',
          severity: AppNotificationSeverity.info,
          createdAt: now,
          actionType: AppNotificationActionType.addTransaction,
          actionLabel: 'Thêm giao dịch',
          effectiveDate: startOfDay,
        ),
      );
    } else {
      await _expireNotificationById(userId, dailyTransactionId);
    }

    final savingGoalsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('saving_goals')
        .get();
    final activeGoals = savingGoalsSnapshot.docs.where((doc) {
      final status = doc.data()['status']?.toString() ?? 'active';
      return status == 'active';
    }).toList(growable: false);

    final savingsReminderId =
        'daily_savings_${startOfDay.toIso8601String().substring(0, 10)}';

    if (activeGoals.isEmpty) {
      await _expireNotificationById(userId, savingsReminderId);
      return;
    }

    var hasContributionToday = false;
    for (final goalDoc in activeGoals) {
      final contributionSnapshot = await goalDoc.reference
          .collection('contributions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();
      if (contributionSnapshot.docs.isNotEmpty) {
        hasContributionToday = true;
        break;
      }
    }

    if (!hasContributionToday) {
      await _upsertNotification(
        userId,
        AppNotification(
          id: savingsReminderId,
          sourceType: AppNotificationSourceType.savingsReminder,
          shortTitle: 'Thông báo từ ứng dụng',
          detailTitle: 'Hôm nay bạn chưa nạp tiền tiết kiệm',
          body: 'Bạn đang có mục tiêu tiết kiệm hoạt động. Hãy góp thêm để giữ tiến độ.',
          severity: AppNotificationSeverity.info,
          createdAt: now,
          actionType: AppNotificationActionType.savings,
          actionLabel: 'Xem mục tiêu tiết kiệm',
          effectiveDate: startOfDay,
        ),
      );
    } else {
      await _expireNotificationById(userId, savingsReminderId);
    }
  }

  Future<void> _deleteYesterdayAppNotifications(
    String userId,
    DateTime startOfDay,
  ) async {
    final snapshot = await _notificationsCollection(userId).get();
    for (final doc in snapshot.docs) {
      final item = AppNotification.fromFirestore(doc.id, doc.data());
      if (item.isSystemNotification) continue;
      final anchorDate = item.effectiveDate ?? item.createdAt;
      final anchorDay = DateTime(
        anchorDate.year,
        anchorDate.month,
        anchorDate.day,
      );
      if (anchorDay.isBefore(startOfDay) && item.deletedAt == null) {
        await doc.reference.set(<String, dynamic>{
          'deletedAt': FieldValue.serverTimestamp(),
          'expiresAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> _expireNotificationById(String userId, String notificationId) async {
    final doc = await _notificationsCollection(userId).doc(notificationId).get();
    if (!doc.exists) return;
    final now = DateTime.now();
    await doc.reference.set(<String, dynamic>{
      'expiresAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
    _updateLocalNotification(
      notificationId,
      (current) => current.copyWith(expiresAt: now),
    );
  }

  Future<void> _hideNotification(String userId, String notificationId) async {
    final doc = await _notificationsCollection(userId).doc(notificationId).get();
    if (!doc.exists) return;
    final now = DateTime.now();
    await doc.reference.set(<String, dynamic>{
      'deletedAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
    _updateLocalNotification(
      notificationId,
      (current) => current.copyWith(
        deletedAt: now,
        expiresAt: now,
      ),
    );
  }

  Future<void> _upsertNotification(
    String userId,
    AppNotification notification,
  ) async {
    final docRef = _notificationsCollection(userId).doc(notification.id);
    final existingDoc = await docRef.get();

    DateTime? readAt;
    DateTime? deletedAt;
    DateTime? headsUpShownAt;
    DateTime? createdAt = notification.createdAt;
    DateTime? suppressedUntil;
    if (existingDoc.exists) {
      final existing = AppNotification.fromFirestore(notification.id, existingDoc.data()!);
      readAt = existing.readAt;
      deletedAt = notification.isSystemNotification ? existing.deletedAt : null;
      headsUpShownAt = existing.headsUpShownAt;
      createdAt = existing.createdAt;
      suppressedUntil = existing.suppressedUntil;
    }

    final mergedNotification = notification
        .copyWith(
          createdAt: createdAt,
          readAt: readAt,
          deletedAt: deletedAt,
          headsUpShownAt: headsUpShownAt,
          suppressedUntil: suppressedUntil,
          clearDeletedAt: !notification.isSystemNotification,
          clearExpiresAt: true,
        );
    await docRef.set(mergedNotification.toFirestore(), SetOptions(merge: true));
    _upsertLocalNotification(mergedNotification);
  }

  Future<void> _upsertBroadcastNotification(
    String userId,
    AppNotification notification,
  ) async {
    final docRef = _notificationsCollection(userId).doc(notification.id);
    final existingDoc = await docRef.get();
    if (!existingDoc.exists) {
      await docRef.set(notification.toFirestore(), SetOptions(merge: true));
      return;
    }

    final existing = AppNotification.fromFirestore(
      notification.id,
      existingDoc.data()!,
    );

    if (existing.sourceEventKey == notification.sourceEventKey) {
      final mergedNotification = notification
          .copyWith(
            createdAt: existing.createdAt,
            readAt: existing.readAt,
            deletedAt: existing.deletedAt,
            headsUpShownAt: existing.headsUpShownAt,
            suppressedUntil: existing.suppressedUntil,
          );
      await docRef.set(mergedNotification.toFirestore(), SetOptions(merge: true));
      _upsertLocalNotification(mergedNotification);
      return;
    }

    final mergedNotification = notification
        .copyWith(
          clearReadAt: true,
          clearDeletedAt: true,
          clearHeadsUpShownAt: true,
          clearSuppressedUntil: true,
        );
    await docRef.set(mergedNotification.toFirestore(), SetOptions(merge: true));
    _upsertLocalNotification(mergedNotification);
  }

  void _scheduleDayRolloverSync() {
    _dayRolloverTimer?.cancel();
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    final delay = nextDay.difference(now) + const Duration(seconds: 2);
    _dayRolloverTimer = Timer(delay, () {
      unawaited(syncNow());
    });
  }

  AppNotificationSeverity _mapBroadcastSeverity(String? type) {
    switch (type) {
      case 'warning':
        return AppNotificationSeverity.warning;
      case 'success':
        return AppNotificationSeverity.success;
      case 'info':
      default:
        return AppNotificationSeverity.info;
    }
  }

  AppNotificationActionType _inferBroadcastAction(String body) {
    final normalized = body.toLowerCase();
    if (normalized.contains('ngân sách') || normalized.contains('ngan sach')) {
      return AppNotificationActionType.budget;
    }
    if (normalized.contains('tiết kiệm') || normalized.contains('tiet kiem')) {
      return AppNotificationActionType.savings;
    }
    if (normalized.contains('giao dịch') || normalized.contains('giao dich')) {
      return AppNotificationActionType.addTransaction;
    }
    return AppNotificationActionType.none;
  }

  String? _inferBroadcastActionLabel(String body) {
    switch (_inferBroadcastAction(body)) {
      case AppNotificationActionType.budget:
        return 'Xem ngân sách';
      case AppNotificationActionType.savings:
        return 'Xem mục tiêu tiết kiệm';
      case AppNotificationActionType.addTransaction:
        return 'Thêm giao dịch';
      case AppNotificationActionType.none:
        return null;
    }
  }

  String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _dayKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _applyHeadsUpEntryDelay() {
    _headsUpTimer?.cancel();
    _currentHeadsUp = null;
    _headsUpBlockedUntil = DateTime.now().add(_headsUpInitialDelay);
    _scheduleHeadsUpGate(_headsUpInitialDelay);
    notifyListeners();
  }

  void _scheduleHeadsUpGate(Duration delay) {
    _headsUpGateTimer?.cancel();
    _headsUpGateTimer = Timer(delay, () {
      _headsUpBlockedUntil = null;
      _processHeadsUpQueue();
    });
  }

  void _upsertLocalNotification(AppNotification notification) {
    final items = List<AppNotification>.from(_notifications);
    final index = items.indexWhere((item) => item.id == notification.id);
    if (index >= 0) {
      items[index] = notification;
    } else {
      items.add(notification);
    }
    _notifications = items;
    _enqueueHeadsUpNotifications();
    notifyListeners();
  }

  bool _isNotificationVisible(AppNotification notification) {
    return _appNotificationsEnabled || notification.isSystemNotification;
  }

  void _scheduleBroadcastTransitionSync(DateTime? nextTick) {
    _broadcastTransitionTimer?.cancel();
    if (nextTick == null || _currentUserId == null) {
      return;
    }

    final delay = nextTick.difference(DateTime.now()) + const Duration(seconds: 1);
    _broadcastTransitionTimer = Timer(
      delay.isNegative ? const Duration(seconds: 1) : delay,
      () => unawaited(syncNow()),
    );
  }

  void _updateLocalNotification(
    String notificationId,
    AppNotification Function(AppNotification current) update,
  ) {
    final items = List<AppNotification>.from(_notifications);
    final index = items.indexWhere((item) => item.id == notificationId);
    if (index < 0) return;
    items[index] = update(items[index]);
    _notifications = items;
    notifyListeners();
  }
}
