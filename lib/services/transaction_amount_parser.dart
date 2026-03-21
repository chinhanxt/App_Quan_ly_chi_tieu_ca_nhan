import 'package:app/services/transaction_type_inference.dart';

class ParsedAmount {
  const ParsedAmount({
    required this.raw,
    required this.amount,
    required this.start,
    required this.end,
  });

  final String raw;
  final int amount;
  final int start;
  final int end;
}

class TransactionAmountParser {
  static final RegExp _compactMillionPattern = RegExp(
    r'(?<![a-z0-9])(\d+)\s*(tr|trieu|triệu|m|cu|củ|chai)\s*(\d{1,3})\b',
    caseSensitive: false,
    unicode: true,
  );

  static final RegExp _halfUnitPattern = RegExp(
    r'(?<![a-z0-9])(\d+)\s*(tr|trieu|triệu|m|cu|củ|chai)\s*(ruoi|rưỡi)\b',
    caseSensitive: false,
    unicode: true,
  );

  static final RegExp _numericAmountPattern = RegExp(
    r'(?<![a-z0-9])(\d[\d\.,]*)(?:\s*)(k|ngan|nghin|ngàn|nghìn|kđ|tr|trieu|triệu|cu|củ|m|lit|lít|ve|xị|xi|chai|dong|đồng|vnd|vnđ|d|đ)?(?=\s|$)',
    caseSensitive: false,
    unicode: true,
  );

  static final RegExp _wordAmountPattern = RegExp(
    r'\b(nua|nửa|mot|một|hai|ba|bon|bốn|tu|tư|nam|năm|sau|sáu|bay|bảy|tam|tám|chin|chín|muoi|mười)'
    r'(?:\s+(ruoi|rưỡi))?\s+'
    r'(k|ngan|nghin|ngàn|nghìn|tr|trieu|triệu|cu|củ|m|lit|lít|ve|xị|xi)\b',
    caseSensitive: false,
  );

  static final Map<String, int> _wordNumbers = <String, int>{
    'nua': 0,
    'mot': 1,
    'hai': 2,
    'ba': 3,
    'bon': 4,
    'tu': 4,
    'nam': 5,
    'sau': 6,
    'bay': 7,
    'tam': 8,
    'chin': 9,
    'muoi': 10,
  };

  static List<ParsedAmount> extractAmounts(String input) {
    final amounts = <ParsedAmount>[];

    for (final match in _compactMillionPattern.allMatches(input)) {
      final raw = match.group(0);
      final major = int.tryParse(match.group(1) ?? '');
      final fraction = int.tryParse(match.group(3) ?? '');
      if (raw == null || major == null || fraction == null) continue;

      final digits = match.group(3)!.length;
      final decimal = fraction / _pow10(digits);
      final unitAmount = (major + decimal) * _unitMultiplier(match.group(2));
      _addAmount(
        amounts,
        ParsedAmount(
          raw: raw.trim(),
          amount: unitAmount.round().abs(),
          start: match.start,
          end: match.end,
        ),
      );
    }

    for (final match in _halfUnitPattern.allMatches(input)) {
      final raw = match.group(0);
      final major = int.tryParse(match.group(1) ?? '');
      if (raw == null || major == null) continue;

      final unitAmount = (major + 0.5) * _unitMultiplier(match.group(2));
      _addAmount(
        amounts,
        ParsedAmount(
          raw: raw.trim(),
          amount: unitAmount.round().abs(),
          start: match.start,
          end: match.end,
        ),
      );
    }

    for (final match in _numericAmountPattern.allMatches(input)) {
      final raw = match.group(0);
      final rawNumber = match.group(1);
      if (raw == null || rawNumber == null) continue;

      final amount = _parseNumeric(rawNumber, match.group(2));
      if (amount == null) continue;

      _addAmount(
        amounts,
        ParsedAmount(
          raw: raw.trim(),
          amount: amount.abs(),
          start: match.start,
          end: match.end,
        ),
      );
    }

    for (final match in _wordAmountPattern.allMatches(input)) {
      final raw = match.group(0);
      final rawWord = match.group(1);
      if (raw == null || rawWord == null) continue;

      final amount = _parseWordAmount(
        rawWord: rawWord,
        halfWord: match.group(2),
        unit: match.group(3),
      );
      if (amount == null) continue;

      final overlaps = amounts.any(
        (item) => match.start < item.end && match.end > item.start,
      );
      if (overlaps) continue;

      _addAmount(
        amounts,
        ParsedAmount(
          raw: raw.trim(),
          amount: amount.abs(),
          start: match.start,
          end: match.end,
        ),
      );
    }

    amounts.sort((a, b) => a.start.compareTo(b.start));
    return amounts;
  }

  static int? extractSingleAmount(String input) {
    final amounts = extractAmounts(input);
    if (amounts.length != 1) return null;
    return amounts.first.amount;
  }

  static bool hasAmount(String input) => extractAmounts(input).isNotEmpty;

  static int? _parseNumeric(String rawNumber, String? unitRaw) {
    var normalized = rawNumber.replaceAll('.', '').replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) return null;
    final multiplier = _unitMultiplier(unitRaw);
    var amount = (parsed * multiplier).round();

    if (multiplier == 1 &&
        !rawNumber.contains('.') &&
        !rawNumber.contains(',') &&
        parsed > 0 &&
        parsed < 1000) {
      amount *= 1000;
    }

    return amount;
  }

  static int? _parseWordAmount({
    required String rawWord,
    required String? halfWord,
    required String? unit,
  }) {
    final normalizedWord = TransactionTypeInference.normalizeText(rawWord);
    final base = _wordNumbers[normalizedWord];
    if (base == null) return null;

    double value = base.toDouble();
    if (normalizedWord == 'nua') {
      value = 0.5;
    }
    if (halfWord != null && halfWord.trim().isNotEmpty) {
      value += 0.5;
    }

    return (value * _unitMultiplier(unit)).round();
  }

  static int _unitMultiplier(String? unitRaw) {
    final unit = TransactionTypeInference.normalizeText(unitRaw ?? '');
    switch (unit) {
      case 'k':
      case 'ngan':
      case 'nghin':
        return 1000;
      case 'tr':
      case 'trieu':
      case 'cu':
      case 'm':
      case 'chai':
        return 1000000;
      case 'lit':
      case 'xi':
        return 100000;
      case 've':
        return 500000;
      default:
        return 1;
    }
  }

  static int _pow10(int exponent) {
    var value = 1;
    for (var index = 0; index < exponent; index++) {
      value *= 10;
    }
    return value;
  }

  static void _addAmount(List<ParsedAmount> amounts, ParsedAmount candidate) {
    final overlaps = amounts.any(
      (item) => candidate.start < item.end && candidate.end > item.start,
    );
    if (!overlaps) {
      amounts.add(candidate);
    }
  }
}
