import 'dart:convert';

import 'package:app/models/ai_runtime_config.dart';
import 'package:app/services/transaction_phrase_lexicon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;

const String superAdminEmail = 'admin@gmail.com';
const String adminPermissionOverview = 'overview.view';
const String adminPermissionUsers = 'users.manage';
const String adminPermissionCategories = 'categories.manage';
const String adminPermissionBroadcasts = 'broadcasts.manage';
const String adminPermissionSystemConfigs = 'system_configs.manage';
const String adminPermissionAiConfig = 'ai_config.manage';
const String adminPermissionTransactions = 'transactions.view';
const String adminPermissionReports = 'reports.view';

const List<String> adminAllPermissions = <String>[
  adminPermissionOverview,
  adminPermissionUsers,
  adminPermissionCategories,
  adminPermissionBroadcasts,
  adminPermissionSystemConfigs,
  adminPermissionAiConfig,
  adminPermissionTransactions,
  adminPermissionReports,
];

String normalizeAdminRole({required String email, required String role}) {
  if (email.trim().toLowerCase() == superAdminEmail) {
    return 'super_admin';
  }
  return role.trim().isEmpty ? 'user' : role.trim();
}

List<String> defaultPermissionsForRole(String role) {
  switch (role) {
    case 'super_admin':
    case 'admin':
      return List<String>.from(adminAllPermissions);
    default:
      return const <String>[];
  }
}

List<String> normalizeAdminPermissions(String role, Object? raw) {
  final defaults = defaultPermissionsForRole(role);
  if (raw is! List) return defaults;

  final normalized = raw
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty && adminAllPermissions.contains(item))
      .toSet()
      .toList(growable: false);

  if (normalized.isEmpty && role != 'user') {
    return defaults;
  }

  return normalized;
}

int _readEpochMillis(Object? value) {
  if (value is Timestamp) {
    return value.millisecondsSinceEpoch;
  }
  if (value is num) {
    return value.toInt();
  }
  return 0;
}

Timestamp? _readTimestamp(Object? value) {
  if (value is Timestamp) {
    return value;
  }
  if (value is num) {
    return Timestamp.fromMillisecondsSinceEpoch(value.toInt());
  }
  return null;
}

class AdminProfile {
  const AdminProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
    required this.permissions,
  });

  final String uid;
  final String email;
  final String name;
  final String role;
  final String status;
  final List<String> permissions;

  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isLocked => status == 'locked';
  bool hasPermission(String permission) =>
      isSuperAdmin || permissions.contains(permission);
}

class AdminUserRecord {
  const AdminUserRecord({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
    required this.totalCredit,
    required this.totalDebit,
    required this.remainingAmount,
    required this.createdAt,
    required this.raw,
    required this.permissions,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String status;
  final int totalCredit;
  final int totalDebit;
  final int remainingAmount;
  final Timestamp? createdAt;
  final Map<String, dynamic> raw;
  final List<String> permissions;

  factory AdminUserRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final email = data['email']?.toString() ?? '';
    final normalizedRole = normalizeAdminRole(
      email: email,
      role: data['role']?.toString() ?? 'user',
    );
    return AdminUserRecord(
      id: doc.id,
      email: email,
      name: data['name']?.toString().trim().isNotEmpty == true
          ? data['name'].toString()
          : (data['username']?.toString() ?? 'Chua dat ten'),
      role: normalizedRole,
      status: data['status']?.toString() ?? 'active',
      totalCredit: (data['totalCredit'] as num?)?.toInt() ?? 0,
      totalDebit: (data['totalDebit'] as num?)?.toInt() ?? 0,
      remainingAmount: (data['remainingAmount'] as num?)?.toInt() ?? 0,
      createdAt: _readTimestamp(data['createdAt']),
      raw: data,
      permissions: normalizeAdminPermissions(
        normalizedRole,
        data['permissions'],
      ),
    );
  }
}

class CategoryRecord {
  const CategoryRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.iconName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String type;
  final String iconName;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  factory CategoryRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CategoryRecord(
      id: doc.id,
      name: data['name']?.toString() ?? 'Khong ten',
      type: data['type']?.toString() ?? 'debit',
      iconName: data['iconName']?.toString() ?? 'cartShopping',
      createdAt: _readTimestamp(data['createdAt']),
      updatedAt: _readTimestamp(data['updatedAt']),
    );
  }
}

class BroadcastRecord {
  const BroadcastRecord({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByEmail,
  });

  final String id;
  final String title;
  final String content;
  final String type;
  final String status;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String createdByEmail;

  factory BroadcastRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BroadcastRecord(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      type: data['type']?.toString() ?? 'info',
      status: data['status']?.toString() ?? 'inactive',
      createdAt: _readTimestamp(data['createdAt']),
      updatedAt: _readTimestamp(data['updatedAt']),
      createdByEmail: data['createdByEmail']?.toString() ?? '',
    );
  }
}

class SystemConfigRecord {
  const SystemConfigRecord({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  factory SystemConfigRecord.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return SystemConfigRecord(
      id: doc.id,
      data: doc.data() ?? <String, dynamic>{},
    );
  }
}

class AdminTransactionRecord {
  const AdminTransactionRecord({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.timestamp,
    required this.monthyear,
  });

  final String id;
  final String userId;
  final String title;
  final int amount;
  final String type;
  final String category;
  final int timestamp;
  final String monthyear;

  factory AdminTransactionRecord.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return AdminTransactionRecord(
      id: doc.id,
      userId: doc.reference.parent.parent?.id ?? '',
      title: data['title']?.toString() ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      type: data['type']?.toString() ?? 'debit',
      category: data['category']?.toString() ?? 'Khac',
      timestamp: (data['timestamp'] as num?)?.toInt() ?? 0,
      monthyear: data['monthyear']?.toString() ?? '',
    );
  }
}

class AdminOverviewStats {
  const AdminOverviewStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.adminUsers,
    required this.lockedUsers,
    required this.systemCategories,
    required this.activeBroadcasts,
    required this.transactionsThisMonth,
    required this.totalCredit,
    required this.totalDebit,
    required this.netAmount,
  });

  final int totalUsers;
  final int activeUsers;
  final int adminUsers;
  final int lockedUsers;
  final int systemCategories;
  final int activeBroadcasts;
  final int transactionsThisMonth;
  final int totalCredit;
  final int totalDebit;
  final int netAmount;
}

class AdminOverviewSnapshot {
  const AdminOverviewSnapshot({
    required this.stats,
    required this.recentUsers,
    required this.recentBroadcasts,
    required this.recentTransactions,
    required this.monthTransactions,
  });

  final AdminOverviewStats stats;
  final List<AdminUserRecord> recentUsers;
  final List<BroadcastRecord> recentBroadcasts;
  final List<AdminTransactionRecord> recentTransactions;
  final List<AdminTransactionRecord> monthTransactions;
}

class AiLexiconState {
  const AiLexiconState({
    required this.raw,
    required this.version,
    required this.sourceLabel,
    required this.draftRaw,
    required this.draftVersion,
  });

  final String raw;
  final int version;
  final String sourceLabel;
  final String draftRaw;
  final int draftVersion;
}

class AdminCategorySummary {
  const AdminCategorySummary({
    required this.name,
    required this.totalAmount,
    required this.transactionCount,
    required this.type,
  });

  final String name;
  final int totalAmount;
  final int transactionCount;
  final String type;
}

class AdminUserSummary {
  const AdminUserSummary({
    required this.userId,
    required this.name,
    required this.email,
    required this.totalAmount,
    required this.transactionCount,
  });

  final String userId;
  final String name;
  final String email;
  final int totalAmount;
  final int transactionCount;
}

class AdminMonthlyReport {
  const AdminMonthlyReport({
    required this.month,
    required this.totalTransactions,
    required this.totalCredit,
    required this.totalDebit,
    required this.categories,
    required this.topUsers,
    required this.transactions,
  });

  final DateTime month;
  final int totalTransactions;
  final int totalCredit;
  final int totalDebit;
  final List<AdminCategorySummary> categories;
  final List<AdminUserSummary> topUsers;
  final List<AdminTransactionRecord> transactions;
}

class AdminWebRepository {
  AdminWebRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authChanges() => _auth.authStateChanges();

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Stream<AdminProfile?> watchAdminProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data() ?? <String, dynamic>{};
      final authUser = _auth.currentUser;
      final email = data['email']?.toString() ?? authUser?.email ?? '';
      final normalizedRole = normalizeAdminRole(
        email: email,
        role: data['role']?.toString() ?? 'user',
      );
      return AdminProfile(
        uid: uid,
        email: email,
        name: data['name']?.toString().trim().isNotEmpty == true
            ? data['name'].toString()
            : (data['username']?.toString() ??
                  authUser?.email?.split('@').first ??
                  'Admin'),
        role: normalizedRole,
        status: data['status']?.toString() ?? 'active',
        permissions: normalizeAdminPermissions(
          normalizedRole,
          data['permissions'],
        ),
      );
    });
  }

  Stream<List<AdminUserRecord>> watchUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs.map(AdminUserRecord.fromDoc).toList();
      users.sort((a, b) {
        final left =
            a.createdAt?.millisecondsSinceEpoch ??
            _readEpochMillis(a.raw['updatedAt']);
        final right =
            b.createdAt?.millisecondsSinceEpoch ??
            _readEpochMillis(b.raw['updatedAt']);
        return right.compareTo(left);
      });
      return users;
    });
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).update(<String, dynamic>{
      'role': role,
      'permissions': defaultPermissionsForRole(role),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserAuthorization({
    required String uid,
    required String role,
    required List<String> permissions,
  }) async {
    final actor = _auth.currentUser;
    if (actor == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Bạn cần đăng nhập lại để phân quyền.',
      );
    }

    final actorDoc = await _firestore.collection('users').doc(actor.uid).get();
    final actorData = actorDoc.data() ?? <String, dynamic>{};
    final actorRole = normalizeAdminRole(
      email: actor.email ?? actorData['email']?.toString() ?? '',
      role: actorData['role']?.toString() ?? 'user',
    );

    if (actorRole != 'super_admin') {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Chỉ super admin mới được phân quyền.',
      );
    }

    await _firestore.collection('users').doc(uid).update(<String, dynamic>{
      'role': role,
      'permissions': normalizeAdminPermissions(role, permissions),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserStatus(String uid, String status) async {
    await _firestore.collection('users').doc(uid).update(<String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<CategoryRecord>> watchCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      final categories = snapshot.docs.map(CategoryRecord.fromDoc).toList();
      categories.sort((a, b) {
        final left =
            a.updatedAt?.millisecondsSinceEpoch ??
            a.createdAt?.millisecondsSinceEpoch ??
            0;
        final right =
            b.updatedAt?.millisecondsSinceEpoch ??
            b.createdAt?.millisecondsSinceEpoch ??
            0;
        return right.compareTo(left);
      });
      return categories;
    });
  }

  Future<void> saveCategory({
    String? id,
    required String name,
    required String type,
    required String iconName,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'type': type,
      'iconName': iconName,
      'isDefault': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (id == null) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('categories').add(payload);
      return;
    }

    await _firestore
        .collection('categories')
        .doc(id)
        .set(payload, SetOptions(merge: true));
  }

  Future<void> deleteCategory(String id) {
    return _firestore.collection('categories').doc(id).delete();
  }

  Stream<List<BroadcastRecord>> watchBroadcasts() {
    return _firestore.collection('system_broadcasts').snapshots().map((
      snapshot,
    ) {
      final broadcasts = snapshot.docs.map(BroadcastRecord.fromDoc).toList();
      broadcasts.sort((a, b) {
        final left =
            a.updatedAt?.millisecondsSinceEpoch ??
            a.createdAt?.millisecondsSinceEpoch ??
            0;
        final right =
            b.updatedAt?.millisecondsSinceEpoch ??
            b.createdAt?.millisecondsSinceEpoch ??
            0;
        return right.compareTo(left);
      });
      return broadcasts;
    });
  }

  Future<void> saveBroadcast({
    String? id,
    String? title,
    required String content,
    required String type,
    required bool active,
    String? actorEmail,
  }) async {
    final payload = <String, dynamic>{
      'title': title?.trim() ?? '',
      'content': content,
      'type': type,
      'status': active ? 'active' : 'inactive',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final trimmedActorEmail = actorEmail?.trim() ?? '';
    if (trimmedActorEmail.isNotEmpty) {
      payload['updatedByEmail'] = trimmedActorEmail;
    }

    if (id == null) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      if (trimmedActorEmail.isNotEmpty) {
        payload['createdByEmail'] = trimmedActorEmail;
      }
      await _firestore.collection('system_broadcasts').add(payload);
      return;
    }

    await _firestore
        .collection('system_broadcasts')
        .doc(id)
        .set(payload, SetOptions(merge: true));
  }

  Future<void> toggleBroadcastStatus(String id, bool active) {
    return _firestore
        .collection('system_broadcasts')
        .doc(id)
        .update(<String, dynamic>{
          'status': active ? 'active' : 'inactive',
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> deleteBroadcast(String id) {
    return _firestore.collection('system_broadcasts').doc(id).delete();
  }

  Stream<List<SystemConfigRecord>> watchSystemConfigs() {
    return _firestore
        .collection('system_configs')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(SystemConfigRecord.fromDoc)
              .where(
                (config) => !<String>{
                  'ai_lexicon',
                  'ai_lexicon_draft',
                  'ai_runtime_config',
                  'ai_runtime_config_draft',
                }.contains(config.id),
              )
              .toList(growable: false),
        );
  }

  Future<void> saveSystemConfig(String id, Map<String, dynamic> data) {
    return _firestore.collection('system_configs').doc(id).set(
      <String, dynamic>{...data, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> deleteSystemConfig(String id) {
    return _firestore.collection('system_configs').doc(id).delete();
  }

  Future<AiLexiconState> loadAiLexiconState() async {
    final fallback = await rootBundle.loadString('data.text');
    try {
      final snapshot = await _firestore
          .collection('system_configs')
          .doc('ai_lexicon')
          .get();
      final draftSnapshot = await _firestore
          .collection('system_configs')
          .doc('ai_lexicon_draft')
          .get();
      final data = snapshot.data();
      final draftData = draftSnapshot.data();
      final raw = data?['raw_text']?.toString().trim() ?? '';
      final draftRaw = draftData?['raw_text']?.toString().trim() ?? '';
      return AiLexiconState(
        raw: raw.isNotEmpty ? raw : fallback,
        version: (data?['version'] as num?)?.toInt() ?? 1,
        sourceLabel: raw.isNotEmpty
            ? 'Cấu hình đang áp dụng'
            : 'Tệp hệ thống data.text',
        draftRaw: draftRaw,
        draftVersion: (draftData?['version'] as num?)?.toInt() ?? 1,
      );
    } catch (_) {
      return AiLexiconState(
        raw: fallback,
        version: 1,
        sourceLabel: 'Tệp hệ thống data.text',
        draftRaw: '',
        draftVersion: 1,
      );
    }
  }

  Future<void> saveAiLexiconDraft({
    required String raw,
    required AdminProfile actor,
    required int nextVersion,
  }) async {
    await _firestore
        .collection('system_configs')
        .doc('ai_lexicon_draft')
        .set(<String, dynamic>{
          'raw_text': raw,
          'version': nextVersion,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedByUid': actor.uid,
          'updatedByEmail': actor.email,
        }, SetOptions(merge: true));

    await _firestore.collection('admin_logs').add(<String, dynamic>{
      'action': 'save_ai_lexicon_draft',
      'target': 'system_configs/ai_lexicon_draft',
      'version': nextVersion,
      'adminUid': actor.uid,
      'adminEmail': actor.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveAiLexiconRaw({
    required String raw,
    required AdminProfile actor,
    required int nextVersion,
  }) async {
    await _firestore
        .collection('system_configs')
        .doc('ai_lexicon')
        .set(<String, dynamic>{
          'raw_text': raw,
          'version': nextVersion,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    await _firestore.collection('admin_logs').add(<String, dynamic>{
      'action': 'publish_ai_lexicon',
      'target': 'system_configs/ai_lexicon',
      'version': nextVersion,
      'adminUid': actor.uid,
      'adminEmail': actor.email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    TransactionPhraseLexicon.invalidateCache();
  }

  Future<AiRuntimeConfigState> loadAiRuntimeConfigState() async {
    final defaults = AiRuntimeConfig.defaults();
    try {
      final snapshot = await _firestore
          .collection('system_configs')
          .doc('ai_runtime_config')
          .get();
      final draftSnapshot = await _firestore
          .collection('system_configs')
          .doc('ai_runtime_config_draft')
          .get();
      final data = snapshot.data();
      final draftData = draftSnapshot.data();
      final published = AiRuntimeConfig.fromMap(data);
      final hasDraft = draftData != null && draftData.isNotEmpty;
      final draft = hasDraft
          ? AiRuntimeConfig.fromMap(draftData)
          : AiRuntimeConfig.fromMap(data);
      final publishedVersion = (data?['version'] as num?)?.toInt() ?? 1;
      final draftVersion = hasDraft
          ? (draftData['version'] as num?)?.toInt() ?? 1
          : publishedVersion;
      return AiRuntimeConfigState(
        published: published,
        publishedVersion: publishedVersion,
        draft: hasDraft ? draft : published,
        draftVersion: draftVersion,
        sourceLabel: data == null || data.isEmpty
            ? 'Mặc định hệ thống'
            : 'Cấu hình runtime đang áp dụng',
      );
    } catch (_) {
      return AiRuntimeConfigState(
        published: defaults,
        publishedVersion: 1,
        draft: defaults,
        draftVersion: 1,
        sourceLabel: 'Mặc định hệ thống',
      );
    }
  }

  Future<void> saveAiRuntimeConfigDraft({
    required AiRuntimeConfig config,
    required AdminProfile actor,
    required int nextVersion,
  }) async {
    await _firestore
        .collection('system_configs')
        .doc('ai_runtime_config_draft')
        .set(<String, dynamic>{
          ...config.toMap(),
          'version': nextVersion,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedByUid': actor.uid,
          'updatedByEmail': actor.email,
        }, SetOptions(merge: true));

    await _firestore.collection('admin_logs').add(<String, dynamic>{
      'action': 'save_ai_runtime_config_draft',
      'target': 'system_configs/ai_runtime_config_draft',
      'version': nextVersion,
      'adminUid': actor.uid,
      'adminEmail': actor.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveAiRuntimeConfigRaw({
    required AiRuntimeConfig config,
    required AdminProfile actor,
    required int nextVersion,
  }) async {
    await _firestore
        .collection('system_configs')
        .doc('ai_runtime_config')
        .set(<String, dynamic>{
          ...config.toMap(),
          'version': nextVersion,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedByUid': actor.uid,
          'updatedByEmail': actor.email,
        }, SetOptions(merge: true));

    await _firestore.collection('admin_logs').add(<String, dynamic>{
      'action': 'publish_ai_runtime_config',
      'target': 'system_configs/ai_runtime_config',
      'version': nextVersion,
      'adminUid': actor.uid,
      'adminEmail': actor.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AdminTransactionRecord>> watchRecentTransactions({
    int limit = 250,
  }) {
    return _firestore
        .collectionGroup('transactions')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AdminTransactionRecord.fromDoc)
              .toList(growable: false),
        );
  }

  Future<List<AdminTransactionRecord>> loadTransactionsFeed({
    int perUserLimit = 40,
    int maxUsers = 200,
  }) async {
    final usersSnapshot = await _firestore
        .collection('users')
        .limit(maxUsers)
        .get();
    final futures = usersSnapshot.docs.map((userDoc) async {
      final txSnapshot = await userDoc.reference
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(perUserLimit)
          .get();
      return txSnapshot.docs
          .map(AdminTransactionRecord.fromDoc)
          .toList(growable: false);
    }).toList();

    final grouped = await Future.wait(futures);
    final merged = grouped.expand((items) => items).toList();
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged;
  }

  Future<List<AdminTransactionRecord>> loadTransactionsForMonth(
    DateTime month, {
    int maxUsers = 200,
  }) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final usersSnapshot = await _firestore
        .collection('users')
        .limit(maxUsers)
        .get();
    final futures = usersSnapshot.docs
        .map((userDoc) async {
          final txSnapshot = await userDoc.reference
              .collection('transactions')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: start.millisecondsSinceEpoch,
              )
              .where('timestamp', isLessThan: end.millisecondsSinceEpoch)
              .get();
          return txSnapshot.docs
              .map(AdminTransactionRecord.fromDoc)
              .toList(growable: false);
        })
        .toList(growable: false);

    final grouped = await Future.wait(futures);
    final merged = grouped.expand((items) => items).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged;
  }

  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final txRef = userRef.collection('transactions').doc(transactionId);

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final txSnapshot = await transaction.get(txRef);

      if (!userSnapshot.exists || !txSnapshot.exists) {
        return;
      }

      final userData = userSnapshot.data() ?? <String, dynamic>{};
      final txData = txSnapshot.data() ?? <String, dynamic>{};

      final amount = (txData['amount'] as num?)?.toInt() ?? 0;
      final type = txData['type']?.toString() ?? 'debit';
      var remainingAmount = (userData['remainingAmount'] as num?)?.toInt() ?? 0;
      var totalCredit = (userData['totalCredit'] as num?)?.toInt() ?? 0;
      var totalDebit = (userData['totalDebit'] as num?)?.toInt() ?? 0;

      if (type == 'credit') {
        remainingAmount -= amount;
        totalCredit -= amount;
      } else {
        remainingAmount += amount;
        totalDebit -= amount;
      }

      transaction.update(userRef, <String, dynamic>{
        'remainingAmount': remainingAmount < 0 ? 0 : remainingAmount,
        'totalCredit': totalCredit < 0 ? 0 : totalCredit,
        'totalDebit': totalDebit < 0 ? 0 : totalDebit,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      transaction.delete(txRef);
    });
  }

  Future<AdminOverviewStats> loadOverview() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final categoriesSnapshot = await _firestore.collection('categories').get();
    final broadcastsSnapshot = await _firestore
        .collection('system_broadcasts')
        .where('status', isEqualTo: 'active')
        .get();

    final users = usersSnapshot.docs.map(AdminUserRecord.fromDoc).toList();

    return AdminOverviewStats(
      totalUsers: users.length,
      activeUsers: users.where((user) => user.status == 'active').length,
      adminUsers: users.where((user) => user.role != 'user').length,
      lockedUsers: users.where((user) => user.status == 'locked').length,
      systemCategories: categoriesSnapshot.size,
      activeBroadcasts: broadcastsSnapshot.size,
      transactionsThisMonth: 0,
      totalCredit: users.fold<int>(
        0,
        (total, user) => total + user.totalCredit,
      ),
      totalDebit: users.fold<int>(0, (total, user) => total + user.totalDebit),
      netAmount: users.fold<int>(
        0,
        (total, user) => total + user.remainingAmount,
      ),
    );
  }

  Future<AdminOverviewSnapshot> loadOverviewSnapshot() async {
    final now = DateTime.now();
    final usersSnapshot = await _firestore.collection('users').get();
    final categoriesSnapshot = await _firestore.collection('categories').get();
    final broadcastsCollection = await _firestore
        .collection('system_broadcasts')
        .get();

    final users = usersSnapshot.docs.map(AdminUserRecord.fromDoc).toList()
      ..sort((a, b) {
        final left =
            a.createdAt?.millisecondsSinceEpoch ??
            _readEpochMillis(a.raw['updatedAt']);
        final right =
            b.createdAt?.millisecondsSinceEpoch ??
            _readEpochMillis(b.raw['updatedAt']);
        return right.compareTo(left);
      });

    final broadcasts =
        broadcastsCollection.docs.map(BroadcastRecord.fromDoc).toList()
          ..sort((a, b) {
            final left =
                a.updatedAt?.millisecondsSinceEpoch ??
                a.createdAt?.millisecondsSinceEpoch ??
                0;
            final right =
                b.updatedAt?.millisecondsSinceEpoch ??
                b.createdAt?.millisecondsSinceEpoch ??
                0;
            return right.compareTo(left);
          });

    final recentTransactions = await loadTransactionsFeed(
      perUserLimit: 12,
      maxUsers: 200,
    );
    final monthTransactions = await loadTransactionsForMonth(now);

    final stats = AdminOverviewStats(
      totalUsers: users.length,
      activeUsers: users.where((user) => user.status == 'active').length,
      adminUsers: users.where((user) => user.role != 'user').length,
      lockedUsers: users.where((user) => user.status == 'locked').length,
      systemCategories: categoriesSnapshot.size,
      activeBroadcasts: broadcasts
          .where((item) => item.status == 'active')
          .length,
      transactionsThisMonth: monthTransactions.length,
      totalCredit: users.fold<int>(
        0,
        (total, user) => total + user.totalCredit,
      ),
      totalDebit: users.fold<int>(0, (total, user) => total + user.totalDebit),
      netAmount: users.fold<int>(
        0,
        (total, user) => total + user.remainingAmount,
      ),
    );

    return AdminOverviewSnapshot(
      stats: stats,
      recentUsers: users.take(6).toList(growable: false),
      recentBroadcasts: broadcasts.take(6).toList(growable: false),
      recentTransactions: recentTransactions.take(8).toList(growable: false),
      monthTransactions: monthTransactions,
    );
  }

  Future<AdminMonthlyReport> loadMonthlyReport(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final usersSnapshot = await _firestore.collection('users').get();

    final usersById = <String, AdminUserRecord>{
      for (final doc in usersSnapshot.docs)
        doc.id: AdminUserRecord.fromDoc(doc),
    };
    final futures = usersSnapshot.docs
        .map((userDoc) async {
          final txSnapshot = await userDoc.reference
              .collection('transactions')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: start.millisecondsSinceEpoch,
              )
              .where('timestamp', isLessThan: end.millisecondsSinceEpoch)
              .get();
          return txSnapshot.docs
              .map(AdminTransactionRecord.fromDoc)
              .toList(growable: false);
        })
        .toList(growable: false);

    final grouped = await Future.wait(futures);
    final transactions = grouped.expand((items) => items).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    var totalCredit = 0;
    var totalDebit = 0;
    final categoryMap = <String, ({int amount, int count, String type})>{};
    final userMap = <String, ({int amount, int count})>{};

    for (final tx in transactions) {
      if (tx.type == 'credit') {
        totalCredit += tx.amount;
      } else {
        totalDebit += tx.amount;
      }

      final categoryKey = '${tx.type}:${tx.category}';
      final existingCategory = categoryMap[categoryKey];
      categoryMap[categoryKey] = (
        amount: (existingCategory?.amount ?? 0) + tx.amount,
        count: (existingCategory?.count ?? 0) + 1,
        type: tx.type,
      );

      final existingUser = userMap[tx.userId];
      userMap[tx.userId] = (
        amount: (existingUser?.amount ?? 0) + tx.amount,
        count: (existingUser?.count ?? 0) + 1,
      );
    }

    final categories =
        categoryMap.entries
            .map(
              (entry) => AdminCategorySummary(
                name: entry.key.split(':').last,
                totalAmount: entry.value.amount,
                transactionCount: entry.value.count,
                type: entry.value.type,
              ),
            )
            .toList()
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final topUsers = userMap.entries.map((entry) {
      final user = usersById[entry.key];
      return AdminUserSummary(
        userId: entry.key,
        name: user?.name ?? 'Nguoi dung',
        email: user?.email ?? '',
        totalAmount: entry.value.amount,
        transactionCount: entry.value.count,
      );
    }).toList()..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return AdminMonthlyReport(
      month: month,
      totalTransactions: transactions.length,
      totalCredit: totalCredit,
      totalDebit: totalDebit,
      categories: categories,
      topUsers: topUsers.take(8).toList(growable: false),
      transactions: transactions.take(30).toList(growable: false),
    );
  }

  Map<String, dynamic> parseJsonMap(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON phai la object');
    }
    return decoded;
  }

  String prettyJson(Map<String, dynamic> data) {
    final encoder = JsonEncoder.withIndent('  ', (object) {
      if (object is Timestamp) {
        return object.toDate().toIso8601String();
      }
      return object.toString();
    });
    return encoder.convert(data);
  }
}
