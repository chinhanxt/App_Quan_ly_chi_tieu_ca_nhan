import 'package:app/services/transaction_type_inference.dart';

class AIResponseEnhancement {
  static const int _singleTransactionAlertThreshold = 100000000;
  static const List<String> _singleSuccessMessages = <String>[
    'Xong đẹp rồi, mình ghi lại 1 giao dịch cho bạn. Xem qua rồi lưu nhé!',
    'Mình chốt sổ gọn gàng 1 giao dịch rồi nha. Ngó lại một nhịp rồi lưu thôi!',
    'Đã bắt được 1 giao dịch ngon lành. Chuẩn thì mình lưu sổ tiếp nhé!',
  ];
  static const List<String> _multiSuccessMessages = <String>[
    'Mình tách ra {count} giao dịch gọn ghẽ rồi đó. Bạn xem lại giúp mình nha!',
    'Sổ đã được ghi {count} món rõ ràng rồi. Kiểm tra ổn là lưu thôi!',
    'Mình bóc tách được {count} giao dịch rồi nè. Bạn duyệt qua trước khi chốt nhé!',
  ];
  static const List<String> _failureMessages = <String>[
    'Mình chưa xử lý trọn vẹn được lần này. Bạn thử lại giúp mình sau một chút nhé!',
    'Ca này mình chưa ghi sổ được gọn như mong muốn. Bạn thử lại giúp mình nha!',
    'Mình đang hơi khựng một nhịp nên chưa xử lý xong. Bạn thử lại lát nữa nhé!',
  ];

  static final RegExp _amountPattern = RegExp(
    r'(\d[\d\.,]*)(?:\s*)(k|ngan|nghin|tr|trieu|cu|m|lit|ve)?',
    caseSensitive: false,
  );
  static final RegExp _likelyMultiTransactionPattern = RegExp(
    r'(^| )(roi|r roi|sau do|xong|va|voi|,|;)( |$)',
    caseSensitive: false,
  );
  static final RegExp _ambiguityPattern = RegExp(
    r'(^| )(hay|hoac|tam|tam tam|khoang|gan|hon|up to)( |$)|[?~]',
    caseSensitive: false,
  );

  static String fallbackMessage({
    required String reasonCode,
    int transactionCount = 1,
  }) {
    return successMessage(transactionCount);
  }

  static String successMessage(int transactionCount) {
    if (transactionCount <= 1) {
      return _pickFromPool(_singleSuccessMessages, seed: transactionCount);
    }

    final template = _pickFromPool(
      _multiSuccessMessages,
      seed: transactionCount,
    );
    return template.replaceAll('{count}', '$transactionCount');
  }

  static String failureMessage({
    required String reasonCode,
    String? fallback,
  }) {
    switch (reasonCode) {
      case 'rate_limit':
        return 'Mình đang chạm giới hạn xử lý một chút, bạn thử lại sau ít phút nhé!';
      case 'network':
        return 'Mình đang hụt kết nối nên chưa xử lý xong. Bạn thử lại giúp mình sau một chút nhé!';
      case 'timeout':
        return 'Mình xử lý hơi lâu quá một nhịp nên chưa kịp xong. Bạn thử lại giúp mình nhé!';
      default:
        return fallback?.trim().isNotEmpty == true
            ? fallback!
            : _pickFromPool(_failureMessages, seed: reasonCode.length);
    }
  }

  static bool shouldUseLocalFastPath(String input) {
    final normalized = TransactionTypeInference.normalizeText(input);
    if (normalized.isEmpty) return false;

    final amountMatches = _amountPattern.allMatches(input).length;
    if (amountMatches != 1) return false;

    if (_ambiguityPattern.hasMatch(normalized)) return false;
    if (_likelyMultiTransactionPattern.hasMatch(normalized)) return false;

    if (!_hasFinanceAction(normalized)) return false;
    if (normalized.split(' ').length > 12) return false;

    return true;
  }

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

    final message = status == 'success'
        ? successMessage(transactions.length)
        : result['message']?.toString().trim().isNotEmpty == true
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

    final message = successMessage(transactions.length);

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
      'di cho',
      'cho',
      'sieu thi',
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
        return successMessage(transactionCount);
      case 'clarification':
        return 'Minh can them mot chut thong tin de ghi dung giao dich cho ban.';
      default:
        return failureMessage(reasonCode: 'unknown');
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

  static String _pickFromPool(List<String> messages, {required int seed}) {
    if (messages.isEmpty) return '';
    final index = seed.abs() % messages.length;
    return messages[index];
  }
}
