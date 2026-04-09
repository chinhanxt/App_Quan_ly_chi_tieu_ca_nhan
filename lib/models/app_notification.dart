import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationSourceType {
  system,
  app,
  budgetWarning,
  budgetExceeded,
  dailyTransactionReminder,
  savingsReminder,
}

enum AppNotificationSeverity { info, warning, danger, success }

enum AppNotificationActionType { none, budget, savings, addTransaction }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.sourceType,
    required this.shortTitle,
    required this.detailTitle,
    required this.body,
    required this.severity,
    required this.createdAt,
    required this.actionType,
    this.actionLabel,
    this.actionPayload,
    this.readAt,
    this.deletedAt,
    this.expiresAt,
    this.effectiveDate,
    this.broadcastId,
    this.headsUpShownAt,
    this.occurrenceCount = 1,
    this.sourceEventKey,
    this.suppressedUntil,
  });

  final String id;
  final AppNotificationSourceType sourceType;
  final String shortTitle;
  final String detailTitle;
  final String body;
  final AppNotificationSeverity severity;
  final DateTime createdAt;
  final AppNotificationActionType actionType;
  final String? actionLabel;
  final String? actionPayload;
  final DateTime? readAt;
  final DateTime? deletedAt;
  final DateTime? expiresAt;
  final DateTime? effectiveDate;
  final String? broadcastId;
  final DateTime? headsUpShownAt;
  final int occurrenceCount;
  final String? sourceEventKey;
  final DateTime? suppressedUntil;

  bool get isUnread => readAt == null;
  bool get hasAction => actionType != AppNotificationActionType.none;
  bool get isSystemNotification => sourceType == AppNotificationSourceType.system;

  bool isActiveAt(DateTime now) {
    if (deletedAt != null) return false;
    if (expiresAt != null && !expiresAt!.isAfter(now)) return false;
    return true;
  }

  bool isSuppressedAt(DateTime now) {
    if (suppressedUntil == null) return false;
    return suppressedUntil!.isAfter(now);
  }

  String get headsUpText {
    final trimmedTitle = detailTitle.trim();
    if (trimmedTitle.isNotEmpty && trimmedTitle != shortTitle) {
      return trimmedTitle;
    }
    final trimmedBody = body.trim();
    if (trimmedBody.isNotEmpty) {
      return trimmedBody;
    }
    return shortTitle;
  }

  AppNotification copyWith({
    String? id,
    AppNotificationSourceType? sourceType,
    String? shortTitle,
    String? detailTitle,
    String? body,
    AppNotificationSeverity? severity,
    DateTime? createdAt,
    AppNotificationActionType? actionType,
    String? actionLabel,
    String? actionPayload,
    DateTime? readAt,
    DateTime? deletedAt,
    DateTime? expiresAt,
    DateTime? effectiveDate,
    String? broadcastId,
    DateTime? headsUpShownAt,
    int? occurrenceCount,
    String? sourceEventKey,
    DateTime? suppressedUntil,
    bool clearReadAt = false,
    bool clearDeletedAt = false,
    bool clearExpiresAt = false,
    bool clearEffectiveDate = false,
    bool clearBroadcastId = false,
    bool clearHeadsUpShownAt = false,
    bool clearSourceEventKey = false,
    bool clearSuppressedUntil = false,
  }) {
    return AppNotification(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      shortTitle: shortTitle ?? this.shortTitle,
      detailTitle: detailTitle ?? this.detailTitle,
      body: body ?? this.body,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
      actionType: actionType ?? this.actionType,
      actionLabel: actionLabel ?? this.actionLabel,
      actionPayload: actionPayload ?? this.actionPayload,
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      effectiveDate: clearEffectiveDate
          ? null
          : (effectiveDate ?? this.effectiveDate),
      broadcastId: clearBroadcastId ? null : (broadcastId ?? this.broadcastId),
      headsUpShownAt: clearHeadsUpShownAt
          ? null
          : (headsUpShownAt ?? this.headsUpShownAt),
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      sourceEventKey: clearSourceEventKey
          ? null
          : (sourceEventKey ?? this.sourceEventKey),
      suppressedUntil: clearSuppressedUntil
          ? null
          : (suppressedUntil ?? this.suppressedUntil),
    );
  }

  factory AppNotification.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return AppNotification(
      id: id,
      sourceType: _parseSourceType(data['sourceType']),
      shortTitle: _readString(data['shortTitle']),
      detailTitle: _readString(data['detailTitle']),
      body: _readString(data['body']),
      severity: _parseSeverity(data['severity']),
      createdAt: _readDateTime(data['createdAt']) ?? DateTime.now(),
      actionType: _parseActionType(data['actionType']),
      actionLabel: _readOptionalString(data['actionLabel']),
      actionPayload: _readOptionalString(data['actionPayload']),
      readAt: _readDateTime(data['readAt']),
      deletedAt: _readDateTime(data['deletedAt']),
      expiresAt: _readDateTime(data['expiresAt']),
        effectiveDate: _readDateTime(data['effectiveDate']),
        broadcastId: _readOptionalString(data['broadcastId']),
        headsUpShownAt: _readDateTime(data['headsUpShownAt']),
        occurrenceCount: _readInt(data['occurrenceCount'], fallback: 1),
        sourceEventKey: _readOptionalString(data['sourceEventKey']),
        suppressedUntil: _readDateTime(data['suppressedUntil']),
      );
    }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'sourceType': sourceType.name,
      'shortTitle': shortTitle,
      'detailTitle': detailTitle,
      'body': body,
      'severity': severity.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'actionType': actionType.name,
      'actionLabel': actionLabel,
      'actionPayload': actionPayload,
      'readAt': readAt == null ? null : Timestamp.fromDate(readAt!),
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
      'effectiveDate': effectiveDate == null
          ? null
          : Timestamp.fromDate(effectiveDate!),
        'broadcastId': broadcastId,
        'headsUpShownAt': headsUpShownAt == null
            ? null
            : Timestamp.fromDate(headsUpShownAt!),
        'occurrenceCount': occurrenceCount,
        'sourceEventKey': sourceEventKey,
        'suppressedUntil': suppressedUntil == null
            ? null
            : Timestamp.fromDate(suppressedUntil!),
      };
    }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    final raw = value?.toString().trim() ?? '';
    return raw.isEmpty ? fallback : raw;
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String? _readOptionalString(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    return raw.isEmpty ? null : raw;
  }

  static AppNotificationSourceType _parseSourceType(dynamic value) {
    switch (value?.toString()) {
      case 'system':
        return AppNotificationSourceType.system;
      case 'app':
        return AppNotificationSourceType.app;
      case 'budgetWarning':
        return AppNotificationSourceType.budgetWarning;
      case 'budgetExceeded':
        return AppNotificationSourceType.budgetExceeded;
      case 'dailyTransactionReminder':
        return AppNotificationSourceType.dailyTransactionReminder;
      case 'savingsReminder':
        return AppNotificationSourceType.savingsReminder;
      default:
        return AppNotificationSourceType.system;
    }
  }

  static AppNotificationSeverity _parseSeverity(dynamic value) {
    switch (value?.toString()) {
      case 'warning':
        return AppNotificationSeverity.warning;
      case 'danger':
        return AppNotificationSeverity.danger;
      case 'success':
        return AppNotificationSeverity.success;
      case 'info':
      default:
        return AppNotificationSeverity.info;
    }
  }

  static AppNotificationActionType _parseActionType(dynamic value) {
    switch (value?.toString()) {
      case 'budget':
        return AppNotificationActionType.budget;
      case 'savings':
        return AppNotificationActionType.savings;
      case 'addTransaction':
        return AppNotificationActionType.addTransaction;
      case 'none':
      default:
        return AppNotificationActionType.none;
    }
  }
}
