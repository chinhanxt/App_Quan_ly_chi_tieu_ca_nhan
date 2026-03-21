import 'package:app/services/transaction_type_inference.dart';
import 'package:flutter/services.dart' show rootBundle;

class TransactionPhraseLexicon {
  TransactionPhraseLexicon._({
    required this.creditPhrases,
    required this.debitPhrases,
    required this.categoryPhrases,
  });

  final Set<String> creditPhrases;
  final Set<String> debitPhrases;
  final Map<String, Set<String>> categoryPhrases;

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
    final categoryPhrases = <String, Set<String>>{};

    for (final rawLine in raw.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty || !line.contains(':')) continue;

      final separatorIndex = line.indexOf(':');
      final section = line.substring(0, separatorIndex).trim();
      final values = line.substring(separatorIndex + 1).trim();
      if (values.isEmpty) continue;

      final phrases = values
          .split(RegExp(r'\s+'))
          .map(_normalizePhrase)
          .where((phrase) => phrase.isNotEmpty)
          .toSet();

      final sectionKey = _normalizeSectionKey(section);
      if (sectionKey == 'THU') {
        creditPhrases.addAll(phrases);
      } else if (sectionKey == 'CHI') {
        debitPhrases.addAll(phrases);
      } else {
        categoryPhrases[sectionKey] = phrases;
      }
    }

    return TransactionPhraseLexicon._(
      creditPhrases: creditPhrases,
      debitPhrases: debitPhrases,
      categoryPhrases: categoryPhrases,
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

  static String _normalizeSectionKey(String raw) {
    final upper = raw.trim().toUpperCase();
    final parenIndex = upper.indexOf('(');
    return parenIndex >= 0 ? upper.substring(0, parenIndex).trim() : upper;
  }

  static String _normalizePhrase(String raw) {
    final withSpaces = raw.replaceAll('_', ' ').trim();
    return TransactionTypeInference.normalizeText(withSpaces);
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
}
