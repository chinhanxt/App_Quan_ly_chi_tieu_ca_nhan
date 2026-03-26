import 'dart:ui' show Rect;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrHelper {
  static final RegExp _amountPattern = RegExp(
    r'(?<![\d/:-])(\d{1,3}(?:[.,\s]\d{3})+|\d{4,9})(?![\d/:-])',
    unicode: true,
  );
  static final RegExp _datePattern = RegExp(
    r'(\d{2}[-/]\d{2}[-/]\d{4})',
    unicode: true,
  );
  static final RegExp _dateTimePattern = RegExp(
    r'(\d{2}[-/]\d{2}[-/]\d{4})(?:\s+|\D+)(\d{2}:\d{2}(?::\d{2})?)',
    unicode: true,
  );

  static Future<Map<String, String>> scanImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) {
      return {};
    }

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFilePath(pickedFile.path);
    final recognizedText = await textRecognizer.processImage(inputImage);

    await textRecognizer.close();

    return parseRecognizedResult(recognizedText);
  }

  static Map<String, String> parseRecognizedResult(RecognizedText recognizedText) {
    final orderedLines = _extractOrderedLines(recognizedText);
    final normalizedText = _normalizeText(
      orderedLines.isEmpty
          ? recognizedText.text
          : orderedLines.map((line) => line.text).join('\n'),
    );
    final result = <String, String>{};

    final amount =
        _extractBestAmountFromStructuredLines(orderedLines) ??
        _extractBestAmount(normalizedText);
    if (amount != null) {
      result['amount'] = amount.toString();
    }

    final date = _extractDate(normalizedText);
    if (date != null) {
      result['date'] = date;
    }

    final type = _inferType(normalizedText);
    if (type != null) {
      result['type'] = type;
    }

    final title = _inferTitle(normalizedText);
    if (title.isNotEmpty) {
      result['title'] = title;
    }

    final note = _buildNote(normalizedText, title: title);
    if (note.isNotEmpty) {
      result['note'] = note;
    }

    return result;
  }

  static Map<String, String> parseRecognizedText(String text) {
    final normalizedText = _normalizeText(text);
    final result = <String, String>{};

    final amount = _extractBestAmount(normalizedText);
    if (amount != null) {
      result['amount'] = amount.toString();
    }

    final date = _extractDate(normalizedText);
    if (date != null) {
      result['date'] = date;
    }

    final type = _inferType(normalizedText);
    if (type != null) {
      result['type'] = type;
    }

    final title = _inferTitle(normalizedText);
    if (title.isNotEmpty) {
      result['title'] = title;
    }

    final note = _buildNote(normalizedText, title: title);
    if (note.isNotEmpty) {
      result['note'] = note;
    }

    return result;
  }

  static String _normalizeText(String text) {
    final normalized = text
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ');

    return normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  static List<_OcrLine> _extractOrderedLines(RecognizedText recognizedText) {
    final lines = <_OcrLine>[];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;
        lines.add(
          _OcrLine(
            text: text,
            boundingBox: line.boundingBox,
          ),
        );
      }
    }

    lines.sort((a, b) {
      final topCompare = a.boundingBox.top.compareTo(b.boundingBox.top);
      if (topCompare != 0) return topCompare;
      return a.boundingBox.left.compareTo(b.boundingBox.left);
    });

    return lines;
  }

  static int? _extractBestAmountFromStructuredLines(List<_OcrLine> lines) {
    if (lines.isEmpty) return null;

    final nonEmptyBoxes = lines
        .map((line) => line.boundingBox)
        .where((box) => box.width > 0 && box.height > 0)
        .toList();
    if (nonEmptyBoxes.isEmpty) return null;

    final maxBottom = nonEmptyBoxes
        .map((box) => box.bottom)
        .reduce((value, element) => value > element ? value : element);
    final maxHeight = nonEmptyBoxes
        .map((box) => box.height)
        .reduce((value, element) => value > element ? value : element);

    _AmountCandidate? best;

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final previousLine = index > 0 ? lines[index - 1].text : '';
      final nextLine = index + 1 < lines.length ? lines[index + 1].text : '';
      final previousTwoLines = index > 1 ? lines[index - 2].text : '';
      final nextTwoLines = index + 2 < lines.length ? lines[index + 2].text : '';
      final normalizedLine = line.text.toLowerCase();

      for (final match in _amountPattern.allMatches(line.text)) {
        final raw = match.group(0);
        if (raw == null) continue;
        if (_looksLikeDateFragment(line.text, raw)) continue;

        final amount = _parseAmount(raw);
        if (amount == null || amount < 1000) continue;

        var score = _scoreAmountCandidate(
          raw: raw,
          rawLine: line.text,
          previousLine: previousLine,
          nextLine: nextLine,
          amount: amount,
        );

        final heightRatio = maxHeight == 0 ? 0 : line.boundingBox.height / maxHeight;
        final topRatio = maxBottom == 0 ? 1 : line.boundingBox.top / maxBottom;

        score += (heightRatio * 220).round();
        score += ((1 - topRatio).clamp(0, 1) * 120).round();

        if (_looksLikeStandaloneAmountLine(normalizedLine, raw)) {
          score += 180;
        }
        if (_isCurrencyOnlyLine(nextLine)) {
          score += 220;
        }
        if (_isStatusLine(previousLine) || _isStatusLine(nextLine)) {
          score += 180;
        }
        if (_isLikelyReferenceLine(normalizedLine) ||
            _isLikelyReferenceLine(previousLine.toLowerCase()) ||
            _isLikelyReferenceLine(nextLine.toLowerCase()) ||
            _isLikelyReferenceLine(previousTwoLines.toLowerCase()) ||
            _isLikelyReferenceLine(nextTwoLines.toLowerCase())) {
          score -= 320;
        }
        if (topRatio > 0.62 &&
            !_hasStrongAmountSignal(normalizedLine) &&
            !_hasStrongAmountSignal(previousLine.toLowerCase()) &&
            !_hasStrongAmountSignal(nextLine.toLowerCase())) {
          score -= 160;
        }
        if (_looksLikeReferenceContinuation(
          raw: raw,
          rawLine: normalizedLine,
          previousLine: previousLine.toLowerCase(),
          previousTwoLines: previousTwoLines.toLowerCase(),
        )) {
          score -= 420;
        }
        if (_looksLikeYearAmount(amount, raw, line.text)) {
          score -= 280;
        }

        final candidate = _AmountCandidate(
          raw: raw,
          amount: amount,
          score: score,
        );

        if (best == null ||
            candidate.score > best.score ||
            (candidate.score == best.score && candidate.amount > best.amount)) {
          best = candidate;
        }
      }
    }

    return best?.amount;
  }

  static int? _extractBestAmount(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    _AmountCandidate? best;

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final previousLine = index > 0 ? lines[index - 1] : '';
      final nextLine = index + 1 < lines.length ? lines[index + 1] : '';

      for (final match in _amountPattern.allMatches(line)) {
        final raw = match.group(0);
        if (raw == null) continue;
        if (_looksLikeDateFragment(line, raw)) continue;

        final amount = _parseAmount(raw);
        if (amount == null || amount < 1000) continue;

        final score = _scoreAmountCandidate(
          raw: raw,
          rawLine: line,
          previousLine: previousLine,
          nextLine: nextLine,
          amount: amount,
        );

        final candidate = _AmountCandidate(
          raw: raw,
          amount: amount,
          score: score,
        );

        if (best == null ||
            candidate.score > best.score ||
            (candidate.score == best.score &&
                candidate.amount > best.amount)) {
          best = candidate;
        }
      }
    }

    if (best != null) {
      return best.amount;
    }

    final allMatches = _amountPattern
        .allMatches(text)
        .map((match) => match.group(0))
        .whereType<String>()
        .where((raw) => !_looksLikeDateFragment(text, raw))
        .map(_parseAmount)
        .whereType<int>()
        .where((amount) => amount >= 1000)
        .toList();

    if (allMatches.isEmpty) return null;
    allMatches.sort();
    return allMatches.last;
  }

  static int _scoreAmountCandidate({
    required String raw,
    required String rawLine,
    required String previousLine,
    required String nextLine,
    required int amount,
  }) {
    final line = rawLine.toLowerCase();
    final previous = previousLine.toLowerCase();
    final next = nextLine.toLowerCase();
    final compactRaw = raw.replaceAll(RegExp(r'\s+'), '');

    var score = 0;

    if (line.contains('vnd') ||
        line.contains('vnđ') ||
        line.contains(' đ') ||
        line.contains(' d') ||
        line.endsWith('đ') ||
        line.endsWith('d')) {
      score += 160;
    }
    if (line.contains('giao dich thanh cong') ||
        line.contains('giao dịch thành công') ||
        line.contains('số tiền') ||
        line.contains('so tien') ||
        line.contains('thành tiền') ||
        line.contains('thanh tien') ||
        line.contains('tổng cộng') ||
        line.contains('tong cong') ||
        line.contains('total') ||
        line.contains('amount')) {
      score += 220;
    }
    if (previous.contains('giao dich thanh cong') ||
        previous.contains('giao dịch thành công') ||
        previous.contains('nap dien thoai') ||
        previous.contains('nạp điện thoại') ||
        previous.contains('so tien') ||
        previous.contains('số tiền') ||
        previous.contains('thanh tien') ||
        previous.contains('thành tiền')) {
      score += 170;
    }
    if (next.contains('vnd') ||
        next.contains('vnđ') ||
        next.contains(' đ') ||
        next == 'vnd' ||
        next == 'vnđ') {
      score += 140;
    }
    if (line.contains('tai khoan') ||
        line.contains('tài khoản') ||
        line.contains('số tham chiếu') ||
        line.contains('so tham chieu') ||
        line.contains('tham khảo') ||
        line.contains('mã giao dịch') ||
        line.contains('ma giao dich') ||
        line.contains('tham chiếu') ||
        line.contains('tham chieu') ||
        line.contains('số ref') ||
        line.contains('so ref')) {
      score -= 240;
    }
    if (_looksLikeDateFragment(rawLine, raw)) {
      score -= 500;
    }
    if (rawLine.contains(':') &&
        !_hasStrongAmountSignal(line) &&
        !_hasStrongAmountSignal(previous) &&
        !_hasStrongAmountSignal(next)) {
      score -= 180;
    }
    if (compactRaw.length <= 2) {
      score -= 320;
    }
    if (compactRaw.length >= 5) {
      score += 36;
    }
    if (_hasGroupedThousands(raw)) {
      score += 90;
    }
    if (amount >= 10000) {
      score += 40;
    }
    if (amount >= 100000) {
      score += 40;
    }
    if (rawLine.length <= 24) {
      score += 18;
    }

    return score;
  }

  static bool _looksLikeStandaloneAmountLine(String line, String raw) {
    final normalized = line
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    final compactRaw = raw.replaceAll(' ', '').toLowerCase();

    if (normalized == compactRaw ||
        normalized == '$compactRaw vnd' ||
        normalized == '$compactRaw vnđ' ||
        normalized == '$compactRaw đ') {
      return true;
    }

    final stripped = normalized.replaceAll(RegExp(r'[^0-9a-zđ]'), '');
    return stripped == '${compactRaw}vnd' ||
        stripped == '${compactRaw}vnđ' ||
        stripped == '${compactRaw}đ';
  }

  static bool _isCurrencyOnlyLine(String line) {
    final normalized = line.trim().toLowerCase();
    return normalized == 'vnd' || normalized == 'vnđ' || normalized == 'đ';
  }

  static bool _isStatusLine(String line) {
    final normalized = line.trim().toLowerCase();
    return normalized.contains('giao dich thanh cong') ||
        normalized.contains('giao dịch thành công') ||
        normalized.contains('thanh cong') ||
        normalized.contains('thành công');
  }

  static bool _isLikelyReferenceLine(String line) {
    return line.contains('tai khoan') ||
        line.contains('tài khoản') ||
        line.contains('so tham chieu') ||
        line.contains('số tham chiếu') ||
        line.contains('tham chieu') ||
        line.contains('tham chiếu') ||
        line.contains('ma giao dich') ||
        line.contains('mã giao dịch') ||
        line.contains('ref') ||
        line.contains('reference');
  }

  static bool _looksLikeReferenceContinuation({
    required String raw,
    required String rawLine,
    required String previousLine,
    required String previousTwoLines,
  }) {
    final compactRaw = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (compactRaw.length < 4) {
      return false;
    }

    final hasReferenceContext =
        _isLikelyReferenceLine(rawLine) ||
        _isLikelyReferenceLine(previousLine) ||
        _isLikelyReferenceLine(previousTwoLines);
    if (!hasReferenceContext) {
      return false;
    }

    final lettersOnly = rawLine.replaceAll(RegExp(r'[^a-z]'), '');
    final digitsOnly = rawLine.replaceAll(RegExp(r'[^0-9]'), '');
    final mostlyDigits = digitsOnly.length >= compactRaw.length &&
        (lettersOnly.isEmpty || digitsOnly.length >= lettersOnly.length * 3);

    return mostlyDigits;
  }

  static bool _looksLikeYearAmount(int amount, String raw, String line) {
    final compact = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (compact.length == 4) {
      final year = int.tryParse(compact);
      if (year != null && year >= 2000 && year <= 2099) {
        return true;
      }
    }

    if (amount >= 2000 &&
        amount <= 2099 &&
        RegExp(r'[/:-]').hasMatch(line)) {
      return true;
    }

    return false;
  }

  static bool _looksLikeDateFragment(String line, String raw) {
    final escaped = RegExp.escape(raw);
    final dateContext = RegExp(
      '(^|\\D)$escaped(?=\\D*(?:[:/-]|gio|h|min|pm|am|ngay|thang|nam))|(?:[:/-]|gio|h|min|pm|am|ngay|thang|nam)\\D*$escaped(\\D|\$)',
      caseSensitive: false,
      unicode: true,
    );

    if (dateContext.hasMatch(line)) {
      return true;
    }

    if (RegExp(
      '\\b\\d{1,2}[:/]\\d{1,2}(?:[:/]\\d{2,4})?\\b',
      unicode: true,
    ).hasMatch(line)) {
      final compactRaw = raw.replaceAll(RegExp(r'\s+'), '');
      if (compactRaw.length <= 2 || compactRaw.length == 4) {
        return true;
      }
    }

    return false;
  }

  static bool _hasGroupedThousands(String raw) {
    final compact = raw.replaceAll(' ', '');
    return RegExp(r'^\d{1,3}([.,]\d{3})+$', unicode: true).hasMatch(compact);
  }

  static bool _hasStrongAmountSignal(String text) {
    return text.contains('vnd') ||
        text.contains('vnđ') ||
        text.contains('số tiền') ||
        text.contains('so tien') ||
        text.contains('thành tiền') ||
        text.contains('thanh tien') ||
        text.contains('tổng cộng') ||
        text.contains('tong cong') ||
        text.contains('amount') ||
        text.contains('giao dịch thành công') ||
        text.contains('giao dich thanh cong');
  }

  static int? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9,.\s]'), '').trim();
    if (cleaned.isEmpty) return null;

    final compact = cleaned.replaceAll(' ', '');
    final commaCount = ','.allMatches(compact).length;
    final dotCount = '.'.allMatches(compact).length;

    if (commaCount > 0 && dotCount > 0) {
      final lastComma = compact.lastIndexOf(',');
      final lastDot = compact.lastIndexOf('.');
      final lastSep = lastComma > lastDot ? ',' : '.';
      final decimalDigits = compact.length - compact.lastIndexOf(lastSep) - 1;

      if (decimalDigits == 1 || decimalDigits == 2) {
        final normalized = compact
            .replaceAll(lastSep == ',' ? '.' : ',', '')
            .replaceAll(lastSep, '.');
        return double.tryParse(normalized)?.round();
      }

      return int.tryParse(compact.replaceAll(RegExp(r'[,.]'), ''));
    }

    if (commaCount > 0 || dotCount > 0) {
      final separator = commaCount > 0 ? ',' : '.';
      final parts = compact.split(separator);
      final trailingParts = parts.skip(1).toList();

      final looksLikeThousands = trailingParts.isNotEmpty &&
          trailingParts.every((part) => part.length == 3);
      if (looksLikeThousands) {
        return int.tryParse(parts.join());
      }

      final lastPartLength = parts.last.length;
      if (lastPartLength == 1 || lastPartLength == 2) {
        return double.tryParse(compact.replaceAll(separator, '.'))?.round();
      }

      return int.tryParse(parts.join());
    }

    return int.tryParse(compact);
  }

  static String? _extractDate(String text) {
    final dateTimeMatch = _dateTimePattern.firstMatch(text);
    if (dateTimeMatch != null) {
      return dateTimeMatch.group(1)!.replaceAll('-', '/');
    }

    final dateMatch = _datePattern.firstMatch(text);
    if (dateMatch != null) {
      return dateMatch.group(1)!.replaceAll('-', '/');
    }

    return null;
  }

  static String? _inferType(String text) {
    final normalized = text.toLowerCase();

    const debitHints = <String>[
      'chuyen tien',
      'chuyển tiền',
      'đến:',
      'den:',
      'nap dien thoai',
      'nạp điện thoại',
      'thanh toán',
      'thanh toan',
      'mua hang',
      'mua hàng',
      'tra tien',
      'trả tiền',
    ];
    for (final hint in debitHints) {
      if (normalized.contains(hint)) {
        return 'debit';
      }
    }

    const creditHints = <String>[
      'nhan tien',
      'nhận tiền',
      'tien vao',
      'tiền vào',
      'duoc cong',
      'được cộng',
      'hoan tien',
      'hoàn tiền',
      'luong',
      'lương',
    ];
    for (final hint in creditHints) {
      if (normalized.contains(hint)) {
        return 'credit';
      }
    }

    return null;
  }

  static String _inferTitle(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final normalized = text.toLowerCase();

    final recipientLine = lines.firstWhere(
      (line) => line.toLowerCase().startsWith('đến:') ||
          line.toLowerCase().startsWith('den:'),
      orElse: () => '',
    );
    if (recipientLine.isNotEmpty) {
      final recipient = recipientLine.split(':').skip(1).join(':').trim();
      if (recipient.isNotEmpty) {
        return 'Chuyển tiền cho $recipient';
      }
    }

    if (normalized.contains('nap dien thoai') ||
        normalized.contains('nạp điện thoại')) {
      return 'Nạp điện thoại';
    }

    if (normalized.contains('chuyen tien') ||
        normalized.contains('chuyển tiền')) {
      return 'Chuyển tiền';
    }

    if (normalized.contains('giao dich thanh cong') ||
        normalized.contains('giao dịch thành công')) {
      return 'Giao dịch thành công';
    }

    final firstMeaningful = lines.firstWhere(
      (line) => !_isNoiseLine(line),
      orElse: () => '',
    );
    return firstMeaningful;
  }

  static bool _isNoiseLine(String line) {
    final normalized = line.toLowerCase();
    return normalized == 'bidv' ||
        normalized.contains('giao dich thanh cong') ||
        normalized.contains('giao dịch thành công') ||
        normalized.contains('so tham chieu') ||
        normalized.contains('số tham chiếu') ||
        normalized.contains('tai khoan') ||
        normalized.contains('tài khoản');
  }

  static String _buildNote(String text, {required String title}) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => line != title)
        .take(8)
        .toList();

    return lines.join(' | ').trim();
  }
}

class _AmountCandidate {
  const _AmountCandidate({
    required this.raw,
    required this.amount,
    required this.score,
  });

  final String raw;
  final int amount;
  final int score;
}

class _OcrLine {
  const _OcrLine({
    required this.text,
    required this.boundingBox,
  });

  final String text;
  final Rect boundingBox;
}
