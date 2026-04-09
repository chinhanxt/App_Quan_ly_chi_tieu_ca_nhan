import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? readRuntimeDateTime(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

bool isSingleWindowActive({
  required bool enabled,
  required DateTime now,
  required DateTime? startAt,
  required DateTime? endAt,
}) {
  if (!enabled || startAt == null || endAt == null) {
    return false;
  }
  if (!endAt.isAfter(startAt)) {
    return false;
  }
  return !now.isBefore(startAt) && now.isBefore(endAt);
}

bool isMaintenanceActive(
  Map<String, dynamic> controls, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final manualEnabled =
      controls['maintenanceModeManual'] == true ||
      controls['maintenanceMode'] == true;
  final scheduleEnabled = controls['maintenanceScheduleEnabled'] == true;
  final startAt = readRuntimeDateTime(controls['maintenanceStartAt']);
  final endAt = readRuntimeDateTime(controls['maintenanceEndAt']);

  return manualEnabled ||
      isSingleWindowActive(
        enabled: scheduleEnabled,
        now: currentTime,
        startAt: startAt,
        endAt: endAt,
      );
}

bool isBroadcastVisible(
  Map<String, dynamic> data, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final deliveryMode = data['deliveryMode']?.toString() ?? 'manual';

  if (deliveryMode == 'scheduled') {
    return isSingleWindowActive(
      enabled: true,
      now: currentTime,
      startAt: readRuntimeDateTime(data['autoStartAt']),
      endAt: readRuntimeDateTime(data['autoEndAt']),
    );
  }

  return data['status']?.toString() == 'active';
}

DateTime? nextSingleWindowTransitionAt({
  required bool enabled,
  required DateTime now,
  required DateTime? startAt,
  required DateTime? endAt,
}) {
  if (!enabled || startAt == null || endAt == null) {
    return null;
  }
  if (!endAt.isAfter(startAt)) {
    return null;
  }
  if (now.isBefore(startAt)) {
    return startAt;
  }
  if (now.isBefore(endAt)) {
    return endAt;
  }
  return null;
}

DateTime? nextMaintenanceTransitionAt(
  Map<String, dynamic> controls, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  if (controls['maintenanceModeManual'] == true ||
      controls['maintenanceMode'] == true) {
    return null;
  }

  return nextSingleWindowTransitionAt(
    enabled: controls['maintenanceScheduleEnabled'] == true,
    now: currentTime,
    startAt: readRuntimeDateTime(controls['maintenanceStartAt']),
    endAt: readRuntimeDateTime(controls['maintenanceEndAt']),
  );
}

DateTime? nextBroadcastTransitionAt(
  Map<String, dynamic> data, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final deliveryMode = data['deliveryMode']?.toString() ?? 'manual';
  if (deliveryMode != 'scheduled') {
    return null;
  }

  return nextSingleWindowTransitionAt(
    enabled: true,
    now: currentTime,
    startAt: readRuntimeDateTime(data['autoStartAt']),
    endAt: readRuntimeDateTime(data['autoEndAt']),
  );
}

DateTime? earliestTransition(Iterable<DateTime?> values) {
  DateTime? earliest;
  for (final value in values) {
    if (value == null) {
      continue;
    }
    if (earliest == null || value.isBefore(earliest)) {
      earliest = value;
    }
  }
  return earliest;
}
