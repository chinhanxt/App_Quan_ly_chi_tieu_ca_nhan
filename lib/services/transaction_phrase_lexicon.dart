import 'package:app/services/transaction_type_inference.dart';
import 'package:flutter/services.dart' show rootBundle;

class TransactionPhraseLexicon {
  static const Set<String> _categorySections = <String>{
    'AN_UONG',
    'DI_LAI',
    'MUA_SAM',
    'HOA_DON',
    'GIAI_TRI',
    'NHA_O',
    'NHA_CUA',
    'Y_TE',
    'HOC_TAP',
    'TAI_CHINH',
    'TIET_KIEM',
    'KHAC',
  };

  TransactionPhraseLexicon._({
    required this.creditPhrases,
    required this.debitPhrases,
    required this.negationPhrases,
    required this.futureIntentPhrases,
    required this.debtIntentPhrases,
    required this.categoryPhrases,
    required this.prioritySections,
  });

  final Set<String> creditPhrases;
  final Set<String> debitPhrases;
  final Set<String> negationPhrases;
  final Set<String> futureIntentPhrases;
  final Set<String> debtIntentPhrases;
  final Map<String, Set<String>> categoryPhrases;
  final Map<String, String> prioritySections;

  static Future<TransactionPhraseLexicon>? _cachedFuture;

  static Future<TransactionPhraseLexicon> load() {
    return _cachedFuture ??= _loadInternal();
  }

  static Future<TransactionPhraseLexicon> _loadInternal() async {
    final raw = await rootBundle.loadString('data.text');
    return parseRaw(raw);
  }

  static TransactionPhraseLexicon parseRaw(String raw) {
    final creditPhrases = <String>{};
    final debitPhrases = <String>{};
    final negationPhrases = <String>{};
    final futureIntentPhrases = <String>{};
    final debtIntentPhrases = <String>{};
    final categoryPhrases = <String, Set<String>>{};
    final prioritySections = <String, String>{};

    for (final rawLine in raw.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty ||
          line.startsWith('#') ||
          (!line.contains('::') && !line.contains(':'))) {
        continue;
      }

      final separator = line.contains('::') ? '::' : ':';
      final separatorIndex = line.indexOf(separator);
      final section = line.substring(0, separatorIndex).trim();
      final values = line.substring(separatorIndex + separator.length).trim();
      if (values.isEmpty) continue;

      final sectionKey = _normalizeSectionKey(section);
      if (sectionKey == 'THU' || sectionKey == 'TYPE_CREDIT') {
        final phrases = _parsePhraseList(values);
        creditPhrases.addAll(phrases);
      } else if (sectionKey == 'CHI' || sectionKey == 'TYPE_DEBIT') {
        final phrases = _parsePhraseList(values);
        debitPhrases.addAll(phrases);
      } else if (sectionKey == 'INTENT_NEGATION') {
        negationPhrases.addAll(_parsePhraseList(values));
      } else if (sectionKey == 'INTENT_FUTURE') {
        futureIntentPhrases.addAll(_parsePhraseList(values));
      } else if (sectionKey == 'INTENT_DEBT') {
        debtIntentPhrases.addAll(_parsePhraseList(values));
      } else if (sectionKey == 'PRIORITY_MAP') {
        prioritySections.addAll(_parsePriorityMap(values));
      } else if (_categorySections.contains(sectionKey)) {
        final phrases = _parsePhraseList(values);
        categoryPhrases[sectionKey] = phrases;
      }
    }

    return TransactionPhraseLexicon._(
      creditPhrases: creditPhrases,
      debitPhrases: debitPhrases,
      negationPhrases: negationPhrases,
      futureIntentPhrases: futureIntentPhrases,
      debtIntentPhrases: debtIntentPhrases,
      categoryPhrases: categoryPhrases,
      prioritySections: prioritySections,
    );
  }

  String? inferType(String input) {
    final normalized = TransactionTypeInference.normalizeText(input);
    final creditScore = _bestScore(normalized, creditPhrases);
    final debitScore = _bestScore(normalized, debitPhrases);

    if (creditScore == 0 && debitScore == 0) return null;
    if (creditScore == debitScore) return null;
    return creditScore > debitScore ? 'credit' : 'debit';
  }

  String? bestCategorySection(String input) {
    final normalized = TransactionTypeInference.normalizeText(input);
    String? bestSection;
    var bestScore = 0;

    categoryPhrases.forEach((section, phrases) {
      final score = _bestScore(normalized, phrases);
      if (score > bestScore) {
        bestSection = section;
        bestScore = score;
      }
    });

    return bestSection;
  }

  String? bestPrioritySection(String input) {
    final normalized = TransactionTypeInference.normalizeText(input);

    for (final entry in prioritySections.entries) {
      if (_matchesPhrase(normalized, entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  bool hasFutureIntent(String input) {
    return _containsAnyPhrase(
      TransactionTypeInference.normalizeText(input),
      futureIntentPhrases,
    );
  }

  bool hasNegation(String input) {
    return _containsAnyPhrase(
      TransactionTypeInference.normalizeText(input),
      negationPhrases,
    );
  }

  bool hasPendingDebtIntent(String input) {
    final normalized = TransactionTypeInference.normalizeText(input);
    if (!_containsAnyPhrase(normalized, debtIntentPhrases)) {
      return false;
    }

    return _containsAnyPhrase(normalized, <String>{
      'chua tra',
      'chua thanh toan',
      'tra sau',
      'no lai',
      'ghi so',
      'tam ung',
    });
  }

  static String _normalizeSectionKey(String raw) {
    final upper = raw.trim().toUpperCase();
    final parenIndex = upper.indexOf('(');
    return parenIndex >= 0 ? upper.substring(0, parenIndex).trim() : upper;
  }

  static String _normalizePhrase(String raw) {
    final withSpaces = raw.replaceAll('_', ' ').trim();
    return TransactionTypeInference.normalizeText(withSpaces);
  }

  static Set<String> _parsePhraseList(String values) {
    final rawItems = values.contains(',')
        ? values.split(',')
        : values.split(RegExp(r'\s+'));
    return rawItems
        .map(_normalizePhrase)
        .where((phrase) => phrase.isNotEmpty)
        .toSet();
  }

  static Map<String, String> _parsePriorityMap(String values) {
    final map = <String, String>{};
    for (final rawEntry in values.split(',')) {
      final entry = rawEntry.trim();
      if (entry.isEmpty || !entry.contains(':')) continue;
      final separator = entry.indexOf(':');
      final keyword = _normalizePhrase(entry.substring(0, separator));
      final section = _normalizeSectionKey(entry.substring(separator + 1));
      if (keyword.isEmpty || section.isEmpty) continue;
      map[keyword] = section;
    }
    return map;
  }

  static int _bestScore(String normalizedInput, Set<String> phrases) {
    var best = 0;
    for (final phrase in phrases) {
      if (!_matchesPhrase(normalizedInput, phrase)) continue;

      final score = phrase.split(' ').length * 100 + phrase.length;
      if (score > best) {
        best = score;
      }
    }
    return best;
  }

  static bool _matchesPhrase(String text, String phrase) {
    final pattern = RegExp('(^| )${RegExp.escape(phrase)}(?= |\$)');
    return pattern.hasMatch(text);
  }

  static bool _containsAnyPhrase(String text, Set<String> phrases) {
    for (final phrase in phrases) {
      if (_matchesPhrase(text, phrase)) {
        return true;
      }
    }
    return false;
  }
}
