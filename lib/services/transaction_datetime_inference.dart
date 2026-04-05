import 'package:app/services/transaction_type_inference.dart';
import 'package:intl/intl.dart';

class TransactionDateTimeInference {
  static bool requiresExactDateClarification(String input) {
    final normalized = TransactionTypeInference.normalizeText(input);
    if (normalized.isEmpty) return false;

    if (_containsAny(normalized, <String>[
      'hom qua',
      'toi qua',
      'dem qua',
      'hom nay',
      'ngay mai',
      'mai',
      'ngay kia',
      'mai mot',
    ])) {
      return false;
    }

    if (_inferDateFromInput(input, DateTime.now()).isExplicit) {
      return false;
    }

    return _containsAny(normalized, <String>[
      'hom truoc',
      'hom kia',
      'bua hom',
      'bua hom truoc',
      'bua te',
      'dot truoc',
      'lan truoc',
      'tuan truoc',
      'thang truoc',
      'nam ngoai',
      'nam truoc',
      'dau thang truoc',
      'cuoi thang truoc',
    ]);
  }

  static Map<String, dynamic> refineResult(
    Map<String, dynamic> result, {
    required String input,
    DateTime? now,
  }) {
    if (result['success'] != true) return result;

    final transactions = result['transactions'];
    if (transactions is! List) return result;

    final normalizedTransactions = <Map<String, dynamic>>[];
    for (final transaction in transactions) {
      if (transaction is Map) {
        normalizedTransactions.add(
          refineTransaction(
            input: input,
            transaction: Map<String, dynamic>.from(transaction),
            now: now,
          ),
        );
      }
    }

    return <String, dynamic>{...result, 'transactions': normalizedTransactions};
  }

  static Map<String, dynamic> refineTransaction({
    required String input,
    required Map<String, dynamic> transaction,
    DateTime? now,
  }) {
    final resolved = resolveDateTime(
      input: input,
      transaction: transaction,
      now: now,
    );

    return <String, dynamic>{
      ...transaction,
      'date': DateFormat('dd/MM/yyyy').format(resolved),
      'time': DateFormat('HH:mm').format(resolved),
      'dateTime': DateFormat('dd/MM/yyyy HH:mm').format(resolved),
      '_explicitFutureReference': _hasExplicitFutureReference(
        input: input,
        transactionDateTime: resolved,
        now: now ?? DateTime.now(),
      ),
    };
  }

  static DateTime resolveDateTime({
    required String input,
    required Map<String, dynamic> transaction,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final dateFromInput = _inferDateFromInput(input, current);
    final timeFromInput = _inferTimeFromInput(input, current);

    final aiDateTime = _tryParseDateTime(transaction['dateTime']?.toString());
    final aiDate = _tryParseDate(transaction['date']?.toString());
    final aiTime = _tryParseTime(transaction['time']?.toString());

    final baseDate =
        dateFromInput.value ??
        _dateOnlyOrNull(aiDateTime) ??
        _dateOnlyOrNull(aiDate) ??
        _dateOnly(current);

    final resolvedTime =
        timeFromInput.value ??
        (timeFromInput.shouldUseCurrentTime
            ? _TimeOfDay(current.hour, current.minute)
            : null) ??
        _timeOnly(aiDateTime) ??
        aiTime ??
        _TimeOfDay(current.hour, current.minute);

    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      resolvedTime.hour,
      resolvedTime.minute,
    );
  }

  static _DateResolution _inferDateFromInput(String input, DateTime now) {
    final normalized = TransactionTypeInference.normalizeText(input);
    final today = _dateOnly(now);

    final numericDateMatch = RegExp(
      r'\b(\d{1,2})[\/\-.](\d{1,2})(?:[\/\-.](\d{2,4}))?\b',
    ).firstMatch(input);
    if (numericDateMatch != null) {
      final day = int.tryParse(numericDateMatch.group(1)!);
      final month = int.tryParse(numericDateMatch.group(2)!);
      final rawYear = numericDateMatch.group(3);
      if (day != null && month != null) {
        final year = rawYear == null
            ? now.year
            : (rawYear.length == 2
                  ? 2000 + int.parse(rawYear)
                  : int.parse(rawYear));
        final parsed = _safeDate(year, month, day);
        if (parsed != null) {
          return _DateResolution(
            parsed,
            isExplicit: true,
            isFutureReference: parsed.isAfter(today),
          );
        }
      }
    }

    final verbalDateMatch = RegExp(
      r'\bngay\s+(\d{1,2})\s+thang\s+(\d{1,2})(?:\s+nam\s+(\d{2,4}))?\b',
    ).firstMatch(normalized);
    if (verbalDateMatch != null) {
      final day = int.tryParse(verbalDateMatch.group(1)!);
      final month = int.tryParse(verbalDateMatch.group(2)!);
      final rawYear = verbalDateMatch.group(3);
      if (day != null && month != null) {
        final year = rawYear == null
            ? now.year
            : (rawYear.length == 2
                  ? 2000 + int.parse(rawYear)
                  : int.parse(rawYear));
        final parsed = _safeDate(year, month, day);
        if (parsed != null) {
          return _DateResolution(
            parsed,
            isExplicit: true,
            isFutureReference: parsed.isAfter(today),
          );
        }
      }
    }

    final monthOnlyMatch = RegExp(
      r'\bthang\s+(\d{1,2})(?:\s+nam\s+(\d{2,4}))?\b',
    ).firstMatch(normalized);
    if (monthOnlyMatch != null && !normalized.contains('ngay ')) {
      final month = int.tryParse(monthOnlyMatch.group(1)!);
      final rawYear = monthOnlyMatch.group(2);
      if (month != null && month >= 1 && month <= 12) {
        final year = rawYear == null
            ? _resolveYearForMonthOnly(month: month, now: now)
            : (rawYear.length == 2
                  ? 2000 + int.parse(rawYear)
                  : int.parse(rawYear));
        final parsed = _safeMonthAnchoredDate(
          year: year,
          month: month,
          preferredDay: now.day,
        );
        if (parsed != null) {
          return _DateResolution(
            parsed,
            isExplicit: true,
            isFutureReference: parsed.isAfter(today),
          );
        }
      }
    }

    if (_containsAny(normalized, <String>['hom qua', 'toi qua', 'dem qua'])) {
      return _DateResolution(
        today.subtract(const Duration(days: 1)),
        isExplicit: true,
      );
    }

    if (_containsAny(normalized, <String>[
      'hom nay',
      'sang nay',
      'trua nay',
      'chieu nay',
      'toi nay',
      'dem nay',
    ])) {
      return _DateResolution(today, isExplicit: true);
    }

    if (_containsAny(normalized, <String>['ngay mai', 'mai'])) {
      return _DateResolution(
        today.add(const Duration(days: 1)),
        isExplicit: true,
        isFutureReference: true,
      );
    }

    if (_containsAny(normalized, <String>['ngay kia', 'mai mot'])) {
      return _DateResolution(
        today.add(const Duration(days: 2)),
        isExplicit: true,
        isFutureReference: true,
      );
    }

    final weekday = _extractWeekday(normalized);
    if (weekday != null) {
      final isNextWeek = normalized.contains('tuan sau');
      final isPreviousWeek = normalized.contains('tuan truoc');
      return _DateResolution(
        _resolveWeekday(
          targetWeekday: weekday,
          now: today,
          nextWeek: isNextWeek,
          previousWeek: isPreviousWeek,
        ),
        isExplicit: true,
        isFutureReference:
            isNextWeek ||
            (!isPreviousWeek &&
                _resolveWeekday(
                  targetWeekday: weekday,
                  now: today,
                  nextWeek: isNextWeek,
                  previousWeek: isPreviousWeek,
                ).isAfter(today)),
      );
    }

    return const _DateResolution(null);
  }

  static _TimeResolution _inferTimeFromInput(String input, DateTime now) {
    final raw = input.toLowerCase();
    final normalized = TransactionTypeInference.normalizeText(input);

    final hourMinuteMatch = RegExp(
      r'\b(\d{1,2})[:h](\d{1,2})\b',
    ).firstMatch(raw);
    if (hourMinuteMatch != null) {
      final rawHour = int.tryParse(hourMinuteMatch.group(1)!);
      final minute = int.tryParse(hourMinuteMatch.group(2)!);
      final time = _normalizeHour(rawHour, minute, normalized);
      if (time != null) {
        return _TimeResolution(value: time);
      }
    }

    final halfHourMatch = RegExp(
      r'\b(\d{1,2})\s*(?:h|gio)\s*ruoi\b',
    ).firstMatch(normalized);
    if (halfHourMatch != null) {
      final rawHour = int.tryParse(halfHourMatch.group(1)!);
      final time = _normalizeHour(rawHour, 30, normalized);
      if (time != null) {
        return _TimeResolution(value: time);
      }
    }

    final hourOnlyMatch = RegExp(
      r'\b(\d{1,2})\s*(?:h|gio)\b',
    ).firstMatch(normalized);
    if (hourOnlyMatch != null) {
      final rawHour = int.tryParse(hourOnlyMatch.group(1)!);
      final time = _normalizeHour(rawHour, 0, normalized);
      if (time != null) {
        return _TimeResolution(value: time);
      }
    }

    if (_containsAny(normalized, <String>[
      'rang sang',
      'sang som',
      'buoi sang som',
    ])) {
      return const _TimeResolution(value: _TimeOfDay(6, 0), isExplicit: true);
    }

    if (_containsAny(normalized, <String>[
      'sang',
      'an sang',
      'buoi sang',
      'sang nay',
    ])) {
      return const _TimeResolution(value: _TimeOfDay(8, 0), isExplicit: true);
    }

    if (_containsAny(normalized, <String>['trua', 'buoi trua', 'qua trua'])) {
      return const _TimeResolution(value: _TimeOfDay(12, 0), isExplicit: true);
    }

    if (_containsAny(normalized, <String>['chieu', 'buoi chieu', 'xechieu'])) {
      return const _TimeResolution(value: _TimeOfDay(15, 0), isExplicit: true);
    }

    if (_containsAny(normalized, <String>['toi', 'buoi toi', 'toi nay'])) {
      return const _TimeResolution(value: _TimeOfDay(19, 0), isExplicit: true);
    }

    if (_containsAny(normalized, <String>[
      'dem',
      'khuya',
      'nua dem',
      'gan sang',
    ])) {
      return const _TimeResolution(value: _TimeOfDay(22, 0), isExplicit: true);
    }

    return const _TimeResolution(value: null, shouldUseCurrentTime: true);
  }

  static DateTime? _tryParseDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final value = raw.trim();
    final formats = <DateFormat>[
      DateFormat('dd/MM/yyyy HH:mm'),
      DateFormat('d/M/yyyy H:m'),
      DateFormat('dd-MM-yyyy HH:mm'),
      DateFormat('d-M-yyyy H:m'),
    ];

    for (final format in formats) {
      try {
        return format.parseStrict(value);
      } catch (_) {}
    }

    return DateTime.tryParse(value);
  }

  static DateTime? _tryParseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final value = raw.trim();
    final formats = <DateFormat>[
      DateFormat('dd/MM/yyyy'),
      DateFormat('d/M/yyyy'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('d-M-yyyy'),
    ];

    for (final format in formats) {
      try {
        return format.parseStrict(value);
      } catch (_) {}
    }

    return null;
  }

  static _TimeOfDay? _tryParseTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final source = raw.trim().toLowerCase();
    final normalized = TransactionTypeInference.normalizeText(raw);

    final hourMinuteMatch = RegExp(
      r'\b(\d{1,2})[:h](\d{1,2})\b',
    ).firstMatch(source);
    if (hourMinuteMatch != null) {
      return _normalizeHour(
        int.tryParse(hourMinuteMatch.group(1)!),
        int.tryParse(hourMinuteMatch.group(2)!),
        normalized,
      );
    }

    final hourOnlyMatch = RegExp(r'\b(\d{1,2})\b').firstMatch(normalized);
    if (hourOnlyMatch != null) {
      return _normalizeHour(
        int.tryParse(hourOnlyMatch.group(1)!),
        0,
        normalized,
      );
    }

    return null;
  }

  static _TimeOfDay? _normalizeHour(
    int? rawHour,
    int? minute,
    String normalizedContext,
  ) {
    if (rawHour == null || minute == null) return null;
    if (minute < 0 || minute > 59) return null;

    var hour = rawHour;
    final hasMorningContext = _containsAny(normalizedContext, <String>['sang']);
    final hasNoonContext = _containsAny(normalizedContext, <String>['trua']);
    final hasAfternoonContext = _containsAny(normalizedContext, <String>[
      'chieu',
      'toi',
      'dem',
      'khuya',
    ]);

    if (hour == 24 && minute == 0) {
      hour = 0;
    }

    if (hour < 0 || hour > 24) return null;

    if (hour <= 12 && hasAfternoonContext && hour < 12) {
      hour += 12;
    } else if (hour == 12 &&
        _containsAny(normalizedContext, <String>['dem', 'khuya'])) {
      hour = 0;
    } else if (hour == 12 && hasMorningContext) {
      hour = 0;
    } else if (hour == 12 && hasNoonContext) {
      hour = 12;
    }

    if (hour < 0 || hour > 23) return null;
    return _TimeOfDay(hour, minute);
  }

  static DateTime _resolveWeekday({
    required int targetWeekday,
    required DateTime now,
    required bool nextWeek,
    required bool previousWeek,
  }) {
    final startOfWeek = _dateOnly(
      now.subtract(Duration(days: now.weekday - DateTime.monday)),
    );
    var resolved = startOfWeek.add(
      Duration(days: targetWeekday - DateTime.monday),
    );

    if (previousWeek) {
      resolved = resolved.subtract(const Duration(days: 7));
    } else if (nextWeek) {
      resolved = resolved.add(const Duration(days: 7));
    } else if (resolved.isAfter(_dateOnly(now))) {
      resolved = resolved.subtract(const Duration(days: 7));
    }

    return resolved;
  }

  static int? _extractWeekday(String normalized) {
    const weekdayAliases = <String, int>{
      'thu 2': DateTime.monday,
      'thu hai': DateTime.monday,
      'thu 3': DateTime.tuesday,
      'thu ba': DateTime.tuesday,
      'thu 4': DateTime.wednesday,
      'thu tu': DateTime.wednesday,
      'thu 5': DateTime.thursday,
      'thu nam': DateTime.thursday,
      'thu 6': DateTime.friday,
      'thu sau': DateTime.friday,
      'thu 7': DateTime.saturday,
      'thu bay': DateTime.saturday,
      'chu nhat': DateTime.sunday,
      'cn': DateTime.sunday,
    };

    for (final entry in weekdayAliases.entries) {
      if (_containsAny(normalized, <String>[entry.key])) {
        return entry.value;
      }
    }
    return null;
  }

  static bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final regex = RegExp('(^| )${RegExp.escape(pattern)}(?= |\\\$)');
      if (regex.hasMatch(text)) return true;
    }
    return false;
  }

  static DateTime? _safeDate(int year, int month, int day) {
    try {
      final parsed = DateTime(year, month, day);
      if (parsed.year == year && parsed.month == month && parsed.day == day) {
        return parsed;
      }
    } catch (_) {}
    return null;
  }

  static DateTime? _safeMonthAnchoredDate({
    required int year,
    required int month,
    required int preferredDay,
  }) {
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = preferredDay.clamp(1, lastDayOfMonth);
    return _safeDate(year, month, day);
  }

  static int _resolveYearForMonthOnly({
    required int month,
    required DateTime now,
  }) {
    if (month > now.month) {
      return now.year - 1;
    }
    return now.year;
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime? _dateOnlyOrNull(DateTime? value) {
    if (value == null) return null;
    return _dateOnly(value);
  }

  static _TimeOfDay? _timeOnly(DateTime? value) {
    if (value == null) return null;
    return _TimeOfDay(value.hour, value.minute);
  }

  static bool _hasExplicitFutureReference({
    required String input,
    required DateTime transactionDateTime,
    required DateTime now,
  }) {
    final resolution = _inferDateFromInput(input, now);
    if (!resolution.isFutureReference) {
      return false;
    }

    return transactionDateTime.isAfter(now);
  }
}

class _DateResolution {
  final DateTime? value;
  final bool isExplicit;
  final bool isFutureReference;

  const _DateResolution(
    this.value, {
    this.isExplicit = false,
    this.isFutureReference = false,
  });
}

class _TimeResolution {
  final _TimeOfDay? value;
  final bool shouldUseCurrentTime;
  final bool isExplicit;

  const _TimeResolution({
    required this.value,
    this.shouldUseCurrentTime = false,
    this.isExplicit = false,
  });
}

class _TimeOfDay {
  final int hour;
  final int minute;

  const _TimeOfDay(this.hour, this.minute);
}
