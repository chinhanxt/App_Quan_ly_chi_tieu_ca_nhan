import 'package:app/services/transaction_amount_parser.dart';

class TransactionSegment {
  const TransactionSegment({
    required this.text,
    required this.order,
  });

  final String text;
  final int order;
}

class TransactionSegmenter {
  static final RegExp _splitPattern = RegExp(
    r'\s*(?:,|;|\n+|(?:\s+|^)và(?:\s+|$)|(?:\s+|^)va(?:\s+|$)|(?:\s+|^)với(?:\s+|$)|(?:\s+|^)voi(?:\s+|$)|(?:\s+|^)rồi(?:\s+|$)|(?:\s+|^)roi(?:\s+|$)|(?:\s+|^)sau đó(?:\s+|$)|(?:\s+|^)sau do(?:\s+|$)|(?:\s+|^)xong(?:\s+|$)|(?:\s+|^)nhưng(?:\s+|$)|(?:\s+|^)nhung(?:\s+|$)|(?:\s+|^)rồi thì(?:\s+|$)|(?:\s+|^)roi thi(?:\s+|$))\s*',
    caseSensitive: false,
    unicode: true,
  );

  static List<TransactionSegment> split(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return const <TransactionSegment>[];

    final parts = raw
        .split(_splitPattern)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (parts.isEmpty) return const <TransactionSegment>[];
    if (parts.length == 1) {
      return <TransactionSegment>[TransactionSegment(text: raw, order: 0)];
    }

    final merged = <String>[];
    String? pendingPrefix;
    for (final part in parts) {
      final hasAmount = TransactionAmountParser.hasAmount(part);
      if (!hasAmount && merged.isNotEmpty) {
        merged[merged.length - 1] = '${merged.last} $part'.trim();
        continue;
      }

      if (!hasAmount) {
        pendingPrefix = pendingPrefix == null ? part : '$pendingPrefix $part';
        continue;
      }

      final resolved = pendingPrefix == null ? part : '$pendingPrefix $part';
      merged.add(resolved.trim());
      pendingPrefix = null;
    }

    if (pendingPrefix != null && pendingPrefix.trim().isNotEmpty) {
      if (merged.isNotEmpty) {
        merged[merged.length - 1] = '${merged.last} $pendingPrefix'.trim();
      } else {
        merged.add(pendingPrefix.trim());
      }
    }

    return List<TransactionSegment>.generate(
      merged.length,
      (index) => TransactionSegment(text: merged[index], order: index),
    );
  }
}
