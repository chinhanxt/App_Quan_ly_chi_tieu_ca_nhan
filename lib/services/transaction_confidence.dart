class TransactionConfidence {
  static String label(double score) {
    if (score >= 0.85) return 'high';
    if (score >= 0.6) return 'medium';
    return 'low';
  }

  static double score({
    required bool hasAmount,
    required bool hasType,
    required bool hasCategory,
    required bool hasKnownCategory,
    required bool hasTitle,
    required bool isMultiSegment,
  }) {
    var total = 0.0;

    if (hasAmount) total += 0.35;
    if (hasType) total += 0.2;
    if (hasCategory) total += 0.2;
    if (hasKnownCategory) total += 0.15;
    if (hasTitle) total += 0.1;

    if (isMultiSegment && total > 0.1) {
      total -= 0.05;
    }

    if (total < 0) return 0;
    if (total > 1) return 1;
    return total;
  }
}
