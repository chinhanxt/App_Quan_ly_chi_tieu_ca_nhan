import 'package:app/services/transaction_type_inference.dart';

class AIResponseEnhancement {
  static const int _singleTransactionAlertThreshold = 100000000;

  static Map<String, dynamic>? preflight(String input) {
    final normalized = TransactionTypeInference.normalizeText(input);
    final hasMoneySignal = _hasMoneySignal(input, normalized);
    final hasFinanceAction = _hasFinanceAction(normalized);

    if (!hasMoneySignal && !hasFinanceAction) {
      return _buildResponse(
        status: 'clarification',
        message:
            'Toi la tro ly vi tien cua ban. Ke toi nghe mot khoan thu hoac chi kem so tien, toi se ghi lai giup ban nhe!',
      );
    }

    if (!hasMoneySignal && hasFinanceAction) {
      return _buildResponse(
        status: 'clarification',
        message:
            'Minh nghe ra day la mot khoan thu/chi roi, nhung ban chua noi so tien. Thu noi lai kieu "an trua 45k" hoac "luong ve 15 trieu" nhe!',
      );
    }

    if (hasMoneySignal && !hasFinanceAction) {
      final biggestAmount = _extractLargestNumber(input);
      final message = biggestAmount > _singleTransactionAlertThreshold
          ? 'Con so nay lam minh lac mat luon. Ban kiem tra lai xem day la khoan thu hay chi gi, hay vua trung Vietlott that nhe?'
          : 'Minh thay co so tien roi, nhung chua ro day la thu hay chi cho viec gi. Ban noi them mot chut nhe!';
      return _buildResponse(status: 'clarification', message: message);
    }

    return null;
  }

  static Map<String, dynamic> normalizeSchema(Map<String, dynamic> result) {
    final transactions = _extractTransactions(result);
    final statusRaw = result['status']?.toString().trim().toLowerCase();
    final successRaw = result['success'];

    String status;
    if (<String>{'success', 'error', 'clarification'}.contains(statusRaw)) {
      status = statusRaw!;
    } else if (successRaw == true) {
      status = 'success';
    } else if (successRaw == false) {
      status = 'error';
    } else if ((result['message']?.toString().trim().isNotEmpty ?? false)) {
      status = 'clarification';
    } else {
      status = 'error';
    }

    final message = result['message']?.toString().trim().isNotEmpty == true
        ? result['message'].toString()
        : _defaultMessage(status, transactions.length);

    return <String, dynamic>{
      ...result,
      'status': status,
      'message': message,
      'success': status == 'success',
      'transactions': transactions,
      'data': transactions,
    };
  }

  static Map<String, dynamic> postProcess(
    Map<String, dynamic> result, {
    required String input,
  }) {
    final normalized = normalizeSchema(result);
    final transactions = _extractTransactions(
      normalized,
    ).map<Map<String, dynamic>>(_normalizeTransaction).toList();

    if (normalized['status'] != 'success') {
      return <String, dynamic>{
        ...normalized,
        'transactions': transactions,
        'data': transactions,
      };
    }

    if (transactions.isEmpty) {
      return _buildResponse(
        status: 'clarification',
        message:
            'Minh chua thay khoan thu/chi nao that ro rang. Ban noi lai kem noi dung va so tien nhe!',
      );
    }

    if (transactions.length == 1) {
      final amount = transactions.first['amount'];
      if (amount is int && amount > _singleTransactionAlertThreshold) {
        return _buildResponse(
          status: 'clarification',
          message:
              'Con so nay lam minh lac mat luon. Ban kiem tra lai xem co bam thua so 0 nao khong, hay ban vua trung Vietlott that?',
          transactions: transactions,
        );
      }
    }

    final message = normalized['message']?.toString().trim().isNotEmpty == true
        ? normalized['message'].toString()
        : _defaultMessage('success', transactions.length);

    return <String, dynamic>{
      ...normalized,
      'status': 'success',
      'message': message,
      'success': true,
      'transactions': transactions,
      'data': transactions,
    };
  }

  static List<Map<String, dynamic>> _extractTransactions(
    Map<String, dynamic> result,
  ) {
    final rawTransactions = result['transactions'] ?? result['data'];
    if (rawTransactions is! List) return const <Map<String, dynamic>>[];

    return rawTransactions.whereType<Map>().map<Map<String, dynamic>>((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  static Map<String, dynamic> _normalizeTransaction(
    Map<String, dynamic> transaction,
  ) {
    final normalized = Map<String, dynamic>.from(transaction);
    final amount = _coerceAmount(normalized['amount']);
    if (amount != null) {
      normalized['amount'] = amount.abs();
    }
    return normalized;
  }

  static int? _coerceAmount(Object? rawAmount) {
    if (rawAmount is int) return rawAmount;
    if (rawAmount is double) return rawAmount.round();
    if (rawAmount is num) return rawAmount.toInt();
    if (rawAmount is! String) return null;

    var normalized = rawAmount.trim();
    if (normalized.isEmpty) return null;

    normalized = normalized.replaceAll(RegExp(r'[^0-9,\.-]'), '');

    if (normalized.contains(',') && normalized.contains('.')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else if (normalized.contains(',')) {
      normalized = normalized.replaceAll(',', '.');
    }

    final parsed = double.tryParse(normalized);
    if (parsed != null) return parsed.round();

    final compact = rawAmount.replaceAll(RegExp(r'[^0-9-]'), '');
    return int.tryParse(compact);
  }

  static bool _hasMoneySignal(String raw, String normalized) {
    if (RegExp(r'\d').hasMatch(raw)) return true;

    return _containsAny(normalized, <String>[
      'k',
      'ngan',
      'nghin',
      'tr',
      'trieu',
      'cu',
      'm',
      'lit',
      'vnd',
      'dong',
    ]);
  }

  static bool _hasFinanceAction(String normalized) {
    return _containsAny(normalized, <String>[
      'luong',
      'thuong',
      'duoc cho',
      'duoc tang',
      'nhan',
      'thu',
      'an',
      'uong',
      'mua',
      'do xang',
      'xang',
      'mat',
      'tra',
      'dong',
      'nap',
      'chuyen khoan',
      'hoan tien',
      'refund',
      'cashback',
      'ban do',
      'cho',
      'tang',
    ]);
  }

  static int _extractLargestNumber(String raw) {
    final matches = RegExp(r'\d[\d\.,]*').allMatches(raw);
    var largest = 0;
    for (final match in matches) {
      final value = match.group(0);
      if (value == null) continue;

      final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
      final parsed = int.tryParse(digitsOnly);
      if (parsed != null && parsed > largest) {
        largest = parsed;
      }
    }
    return largest;
  }

  static String _defaultMessage(String status, int transactionCount) {
    switch (status) {
      case 'success':
        return transactionCount > 1
            ? 'Da tach duoc $transactionCount giao dich. Ban xem lai giup minh nhe!'
            : 'Da ghi nhan xong. Ban xem lai giao dich giup minh nhe!';
      case 'clarification':
        return 'Minh can them mot chut thong tin de ghi dung giao dich cho ban.';
      default:
        return 'Co loi xay ra khi xu ly AI. Ban thu lai giup minh nhe!';
    }
  }

  static Map<String, dynamic> _buildResponse({
    required String status,
    required String message,
    List<Map<String, dynamic>> transactions = const <Map<String, dynamic>>[],
  }) {
    return <String, dynamic>{
      'status': status,
      'message': message,
      'success': status == 'success',
      'transactions': transactions,
      'data': transactions,
    };
  }

  static bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final regex = RegExp('(^| )${RegExp.escape(pattern)}(?= |\$)');
      if (regex.hasMatch(text)) return true;
    }
    return false;
  }
}
