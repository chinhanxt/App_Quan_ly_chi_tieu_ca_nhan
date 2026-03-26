import 'package:app/services/transaction_type_inference.dart';
import 'package:intl/intl.dart';

class AIResponseEnhancement {
  static const int _singleTransactionAlertThreshold = 100000000;
  static const List<String> _singleSuccessMessages = <String>[
    'Xong đẹp rồi, mình ghi lại 1 giao dịch cho bạn. Xem qua rồi lưu nhé!',
    'Mình chốt sổ gọn gàng 1 giao dịch rồi nha. Ngó lại một nhịp rồi lưu thôi!',
    'Đã bắt được 1 giao dịch ngon lành. Chuẩn thì mình lưu sổ tiếp nhé!',
    'Mình vừa ghim gọn 1 giao dịch cho bạn rồi. Liếc qua thấy ổn là lưu thôi!',
    'Một món đã vào sổ rất mượt rồi nè. Bạn xem lại một chút rồi chốt giúp mình nhé!',
    'Mình đã ráp xong 1 giao dịch khá ngọt. Chuẩn bài thì mình lưu tiếp nha!',
  ];
  static const List<String> _multiSuccessMessages = <String>[
    'Mình tách ra {count} giao dịch gọn ghẽ rồi đó. Bạn xem lại giúp mình nha!',
    'Sổ đã được ghi {count} món rõ ràng rồi. Kiểm tra ổn là lưu thôi!',
    'Mình bóc tách được {count} giao dịch rồi nè. Bạn duyệt qua trước khi chốt nhé!',
    'Mình gom và tách được {count} giao dịch khá mượt rồi đó. Bạn nghía lại giúp mình nha!',
    'Đã lên sổ sẵn {count} giao dịch cho bạn rồi. Ổn áp thì mình lưu luôn nhé!',
    'Mình dàn lại {count} giao dịch rõ ràng rồi nè. Bạn kiểm tra một vòng rồi chốt nhé!',
  ];
  static const List<String> _failureMessages = <String>[
    'Mình chưa xử lý trọn vẹn được lần này. Bạn thử lại giúp mình sau một chút nhé!',
    'Ca này mình chưa ghi sổ được gọn như mong muốn. Bạn thử lại giúp mình nha!',
    'Mình đang hơi khựng một nhịp nên chưa xử lý xong. Bạn thử lại lát nữa nhé!',
    'Mình đang bị khựng một nhịp khi phân tích giao dịch. Bạn thử lại giúp mình nhé!',
    'Lần này mình chưa bắt nhịp kịp để ghi sổ trọn vẹn. Bạn thử lại thêm lần nữa nhé!',
    'Mình đang vấp nhẹ ở khúc xử lý nên chưa chốt xong được. Bạn thử lại giúp mình nha!',
  ];
  static const List<String> _missingAllInfoMessages = <String>[
    'Mình chưa tách được giao dịch nào đủ rõ. Bạn thử nói rõ hơn một chút nhé!',
    'Mình chưa tách được giao dịch nào đủ rõ. Bạn thử nói kiểu như "ăn sáng 30k" hoặc "lương về 15 triệu" nhé!',
    'Mình chưa thấy khoản thu hay chi nào thật rõ ràng. Bạn nói lại kèm nội dung và số tiền nhé!',
    'Mình là trợ lý ví tiền của bạn đây. Kể mình nghe một khoản thu hoặc chi kèm số tiền, mình ghi lại ngay nhé!',
  ];
  static const List<String> _missingAmountMessages = <String>[
    'Mình nghe ra đây là một khoản thu hoặc chi rồi, nhưng bạn chưa nói số tiền. Thử nói lại kiểu "ăn trưa 45k" hoặc "lương về 15 triệu" nhé!',
    'Nội dung thì mình bắt được rồi, còn thiếu mỗi số tiền thôi. Bạn thêm giúp mình một con số nhé!',
    'Mình hiểu bạn đang nhắc tới một giao dịch, nhưng chưa có số tiền nên chưa chốt được. Bạn bổ sung giúp mình nha!',
  ];
  static const List<String> _missingTypeMessages = <String>[
    'Mình thấy có số tiền rồi, nhưng chưa rõ đây là thu hay chi cho việc gì. Bạn nói thêm một chút nhé!',
    'Số tiền thì có rồi nè, còn thiếu nội dung giao dịch để mình biết nên ghi vào khoản nào. Bạn bổ sung giúp mình nhé!',
    'Mình bắt được con số rồi, nhưng chưa rõ là bạn thu được hay vừa chi ra. Nói thêm một nhịp là mình ghi ngay!',
  ];
  static const List<String> _largeAmountMessages = <String>[
    'Con số này làm mình lác mắt luôn. Bạn kiểm tra lại xem đây là khoản thu hay chi gì, hay vừa trúng Vietlott thật nhé?',
    'Con số này làm mình giật mình một nhịp đó nha. Bạn xem lại giúp mình có nhầm đơn vị hay không nhé!',
    'Số tiền này hơi khủng nên mình xin phép hỏi lại cho chắc. Bạn kiểm tra lại giúp mình nhé!',
  ];
  static const List<String> _largeAmountTypoMessages = <String>[
    'Con số này làm mình lác mắt luôn. Bạn kiểm tra lại xem có bấm thừa số 0 nào không, hay bạn vừa trúng Vietlott thật?',
    'Khoản này to quá nên mình hơi rén tay khi chốt sổ. Bạn xem lại giúp mình có dư số 0 nào không nhé!',
    'Số này nhìn hơi choáng đó nha. Bạn kiểm tra lại xem mình có đang thừa một vài số 0 không nhé!',
  ];
  static const List<String> _futureDateMessages = <String>[
    'Ơ kìa, món này đang nằm ở tương lai đó nha. Mình chưa dám chốt sổ xuyên không đâu, bạn kiểm tra lại ngày giờ giúp mình nhé!',
    'Ui, giao dịch này đang chạy trước thời gian mất rồi. Mình chưa dám ghi sổ kiểu du hành thời gian đâu, bạn xem lại ngày giờ giúp mình nha!',
    'Khoan đã, món này hình như đến từ tương lai. Mình xin phép đứng yên trong hiện tại và nhờ bạn kiểm tra lại ngày giờ nhé!',
  ];
  static const List<String> _defaultClarificationMessages = <String>[
    'Mình cần thêm một chút thông tin để ghi đúng giao dịch cho bạn.',
    'Mình còn thiếu một chút dữ liệu để chốt giao dịch cho chuẩn. Bạn nói thêm giúp mình nhé!',
    'Ca này mình cần bạn gợi thêm một nhịp nữa để ghi sổ cho thật đúng nha!',
  ];
  static const List<String> _quickTemplateMessages = <String>[
    'Mình đã dựng sẵn card từ mục Chọn nhanh. Bạn kiểm tra lại rồi bấm lưu là xong.',
    'Card từ mục Chọn nhanh đã lên sẵn rồi nè. Bạn liếc qua một chút rồi lưu giúp mình nhé!',
    'Mình kéo sẵn giao dịch từ mục Chọn nhanh ra cho bạn rồi. Ổn áp thì bấm lưu thôi!',
  ];
  static const List<String> _saveSuccessMessages = <String>[
    'Mình đã lưu {count} giao dịch cho bạn rồi. Có gì bạn cứ nhắn tiếp nhé!',
    'Xong rồi nha, {count} giao dịch đã vào sổ gọn gàng. Cần thêm gì mình hỗ trợ tiếp nhé!',
    'Mình đã cất {count} giao dịch vào sổ cho bạn rồi. Muốn ghi tiếp thì cứ nói mình nha!',
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

  static String failureMessage({required String reasonCode, String? fallback}) {
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

  static String defaultClarificationMessage() {
    return _pickFromPool(
      _defaultClarificationMessages,
      seed: _defaultClarificationMessages.length,
    );
  }

  static String quickTemplateMessage() {
    return _pickFromPool(
      _quickTemplateMessages,
      seed: _quickTemplateMessages.length,
    );
  }

  static String saveSuccessMessage(int transactionCount) {
    final template = _pickFromPool(
      _saveSuccessMessages,
      seed: transactionCount,
    );
    return template.replaceAll('{count}', '$transactionCount');
  }

  static String missingAllInfoMessage() {
    return _pickFromPool(
      _missingAllInfoMessages,
      seed: _missingAllInfoMessages.length,
    );
  }

  static String missingAmountMessage() {
    return _pickFromPool(
      _missingAmountMessages,
      seed: _missingAmountMessages.length,
    );
  }

  static String missingTypeMessage() {
    return _pickFromPool(
      _missingTypeMessages,
      seed: _missingTypeMessages.length,
    );
  }

  static String largeAmountMessage({bool typoHint = false}) {
    final pool = typoHint ? _largeAmountTypoMessages : _largeAmountMessages;
    return _pickFromPool(pool, seed: pool.length);
  }

  static String futureDateMessage() {
    return _pickFromPool(_futureDateMessages, seed: _futureDateMessages.length);
  }

  static String exactDateClarificationMessage() {
    return 'Mình hiểu mốc thời gian bạn nói rồi, nhưng nó vẫn còn hơi mơ hồ. Bạn cho mình ngày chính xác giúp nhé, ví dụ 24/03/2026 hoặc hôm qua.';
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
        message: missingAllInfoMessage(),
      );
    }

    if (!hasMoneySignal && hasFinanceAction) {
      return _buildResponse(
        status: 'clarification',
        message: missingAmountMessage(),
      );
    }

    if (hasMoneySignal && !hasFinanceAction) {
      final biggestAmount = _extractLargestNumber(input);
      final message = biggestAmount > _singleTransactionAlertThreshold
          ? largeAmountMessage()
          : missingTypeMessage();
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
    DateTime? now,
  }) {
    final normalized = normalizeSchema(result);
    final transactions = _extractTransactions(
      normalized,
    ).map<Map<String, dynamic>>(_normalizeTransaction).toList();
    final current = now ?? DateTime.now();

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
        message: missingAllInfoMessage(),
      );
    }

    if (transactions.length == 1) {
      final amount = transactions.first['amount'];
      if (amount is int && amount > _singleTransactionAlertThreshold) {
        return _buildResponse(
          status: 'clarification',
          message: largeAmountMessage(typoHint: true),
          transactions: transactions,
        );
      }
    }

    final hasFutureTransaction = transactions.any((transaction) {
      final resolved = _tryParseTransactionDateTime(transaction);
      final hasExplicitFutureReference =
          transaction['_explicitFutureReference'] == true;
      return hasExplicitFutureReference &&
          resolved != null &&
          resolved.isAfter(current);
    });
    if (hasFutureTransaction) {
      return _buildResponse(
        status: 'clarification',
        message: futureDateMessage(),
      );
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
      'me cho',
      'bo cho',
      'duoc tang',
      'nhan',
      'thu',
      'an',
      'uong',
      'cafe',
      'tra sua',
      'mua',
      'do xang',
      'xang',
      'grab',
      'di grab',
      'di xe',
      'xe',
      'xe om',
      'taxi',
      'bus',
      'xe buyt',
      'ship',
      'gui xe',
      'di cho',
      'cho',
      'sieu thi',
      'bach hoa xanh',
      'sieu thi',
      'internet',
      'wifi',
      'host web',
      'mat',
      'tra',
      'me tra',
      'bo tra',
      'cho vay',
      'bi tru',
      'duoc cong',
      'dong',
      'nap',
      'chuyen khoan',
      'hoan tien',
      'refund',
      'cashback',
      'ban do',
      'ban',
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

  static DateTime? _tryParseTransactionDateTime(
    Map<String, dynamic> transaction,
  ) {
    final dateTimeRaw = transaction['dateTime']?.toString().trim();
    if (dateTimeRaw != null && dateTimeRaw.isNotEmpty) {
      for (final format in <DateFormat>[
        DateFormat('dd/MM/yyyy HH:mm'),
        DateFormat('d/M/yyyy H:m'),
      ]) {
        try {
          return format.parseStrict(dateTimeRaw);
        } catch (_) {}
      }
    }

    final dateRaw = transaction['date']?.toString().trim();
    if (dateRaw == null || dateRaw.isEmpty) return null;

    try {
      return DateFormat('dd/MM/yyyy').parseStrict(dateRaw);
    } catch (_) {
      return null;
    }
  }

  static String _defaultMessage(String status, int transactionCount) {
    switch (status) {
      case 'success':
        return successMessage(transactionCount);
      case 'clarification':
        return defaultClarificationMessage();
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
