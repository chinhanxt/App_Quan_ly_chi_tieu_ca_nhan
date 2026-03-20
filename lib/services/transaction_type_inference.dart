class TransactionTypeInference {
  static const Map<String, int> _phraseScores = <String, int>{
    'duoc tang': 6,
    'duoc cho': 6,
    'duoc bieu': 6,
    'duoc mung': 6,
    'nhan luong': 6,
    'luong ve': 6,
    'nhan thuong': 5,
    'duoc thuong': 5,
    'thu no': 6,
    'duoc tra no': 7,
    'hoan tien': 6,
    'duoc hoan tien': 7,
    'refund': 6,
    'cashback': 6,
    'nhan tien': 5,
    'chuyen khoan vao': 5,
    'duoc chuyen khoan': 5,
    'nhan chuyen khoan': 5,
    'ck vao': 5,
    'ban do cu': 5,
    'ban hang': 4,
    'ban do': 4,
    'lai ngan hang': 6,
    'co tuc': 6,
    'mua': -4,
    'an sang': -6,
    'an trua': -6,
    'an toi': -6,
    'uong cafe': -6,
    'uong ca phe': -6,
    'do xang': -6,
    'tra no': -6,
    'dong tien': -5,
    'nop tien': -5,
    'thanh toan': -5,
    'tra tien': -5,
    'chuyen khoan cho': -6,
    'chuyen khoan tien': -5,
    'nap tien': -5,
    'rut tien': -4,
    'tang me': -6,
    'tang ba': -6,
    'tang bo': -6,
    'tang vo': -6,
    'tang chong': -6,
    'tang con': -6,
    'cho me': -6,
    'cho ba': -6,
    'cho bo': -6,
    'cho vo': -6,
    'cho chong': -6,
    'cho con': -6,
    'tien nha': -5,
    'tien dien': -5,
    'tien nuoc': -5,
    'tien mang': -5,
    'hoc phi': -6,
    'vien phi': -6,
  };

  static const Map<String, int> _wordScores = <String, int>{
    'duoc': 2,
    'nhan': 2,
    'luong': 3,
    'thu': 2,
    'hoan': 2,
    'refund': 3,
    'cashback': 3,
    'lai': 2,
    'mua': -3,
    'an': -2,
    'uong': -2,
    'tra': -2,
    'dong': -2,
    'nop': -2,
    'nap': -2,
    'tang': -2,
    'cho': -1,
    'phi': -2,
  };

  static const Map<String, String> _typeAliases = <String, String>{
    'credit': 'credit',
    'thu': 'credit',
    'thu nhap': 'credit',
    'income': 'credit',
    'inflow': 'credit',
    'debit': 'debit',
    'chi': 'debit',
    'chi tieu': 'debit',
    'expense': 'debit',
    'spend': 'debit',
    'outflow': 'debit',
  };

  static Map<String, dynamic> refineResult(
    Map<String, dynamic> result, {
    required String input,
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
          ),
        );
      }
    }

    return <String, dynamic>{...result, 'transactions': normalizedTransactions};
  }

  static Map<String, dynamic> refineTransaction({
    required String input,
    required Map<String, dynamic> transaction,
  }) {
    final normalized = Map<String, dynamic>.from(transaction);
    final aiType = canonicalizeType(transaction['type']);
    final inferredType = inferType(
      input: input,
      title: normalized['title']?.toString(),
      note: normalized['note']?.toString(),
      category: normalized['category']?.toString(),
    );

    normalized['type'] = inferredType ?? aiType ?? 'debit';
    return normalized;
  }

  static String? inferType({
    required String input,
    String? title,
    String? note,
    String? category,
  }) {
    final inputText = normalizeText(input);
    final transactionText = normalizeText(
      <String?>[title, note, category].whereType<String>().join(' '),
    );

    final transactionScore = _scoreText(transactionText);
    if (transactionScore >= 3) return 'credit';
    if (transactionScore <= -3) return 'debit';

    final inputScore = _scoreText(inputText);
    final combinedScore = inputScore + (transactionScore * 2);

    if (combinedScore >= 4) return 'credit';
    if (combinedScore <= -4) return 'debit';
    return null;
  }

  static String? canonicalizeType(Object? rawType) {
    if (rawType == null) return null;
    return _typeAliases[normalizeText(rawType.toString())];
  }

  static String normalizeText(String value) {
    var normalized = value.toLowerCase();

    const replacements = <String, String>{
      'à': 'a',
      'á': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'đ': 'd',
      'è': 'e',
      'é': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'ì': 'i',
      'í': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ò': 'o',
      'ó': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
    };

    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });

    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized;
  }

  static int _scoreText(String text) {
    if (text.isEmpty) return 0;

    var score = 0;

    _phraseScores.forEach((phrase, value) {
      if (_matchesToken(text, phrase)) {
        score += value;
      }
    });

    _wordScores.forEach((word, value) {
      if (_matchesToken(text, word)) {
        score += value;
      }
    });

    return score;
  }

  static bool _matchesToken(String text, String token) {
    final pattern = RegExp('(^| )${RegExp.escape(token)}(?= |\$)');
    return pattern.hasMatch(text);
  }
}
