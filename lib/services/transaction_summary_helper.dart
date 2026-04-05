class TransactionSummary {
  const TransactionSummary({
    required this.remainingAmount,
    required this.totalCredit,
    required this.totalDebit,
  });

  final int remainingAmount;
  final int totalCredit;
  final int totalDebit;

  Map<String, dynamic> toUserUpdateMap({required int updatedAt}) {
    return <String, dynamic>{
      'remainingAmount': remainingAmount,
      'totalCredit': totalCredit,
      'totalDebit': totalDebit,
      'updatedAt': updatedAt,
    };
  }
}

class TransactionSummaryHelper {
  static int normalizeAmount(Object? rawAmount) {
    final amount = rawAmount is num
        ? rawAmount.toInt()
        : int.tryParse(rawAmount?.toString() ?? '') ?? 0;
    return amount.abs();
  }

  static TransactionSummary snapshotFromMap(Map<String, dynamic> data) {
    return TransactionSummary(
      remainingAmount: _toInt(data['remainingAmount']),
      totalCredit: _toInt(data['totalCredit']),
      totalDebit: _toInt(data['totalDebit']),
    );
  }

  static TransactionSummary applyTransaction({
    required TransactionSummary summary,
    required String type,
    required int amount,
  }) {
    final normalizedAmount = amount.abs();
    if (type == 'credit') {
      return TransactionSummary(
        remainingAmount: summary.remainingAmount + normalizedAmount,
        totalCredit: summary.totalCredit + normalizedAmount,
        totalDebit: summary.totalDebit,
      );
    }

    return TransactionSummary(
      remainingAmount: summary.remainingAmount - normalizedAmount,
      totalCredit: summary.totalCredit,
      totalDebit: summary.totalDebit + normalizedAmount,
    );
  }

  static TransactionSummary revertTransaction({
    required TransactionSummary summary,
    required String type,
    required int amount,
  }) {
    final normalizedAmount = amount.abs();
    if (type == 'credit') {
      return TransactionSummary(
        remainingAmount: summary.remainingAmount - normalizedAmount,
        totalCredit: summary.totalCredit - normalizedAmount,
        totalDebit: summary.totalDebit,
      );
    }

    return TransactionSummary(
      remainingAmount: summary.remainingAmount + normalizedAmount,
      totalCredit: summary.totalCredit,
      totalDebit: summary.totalDebit - normalizedAmount,
    );
  }

  static TransactionSummary reconcileFromTransactions(
    Iterable<Map<String, dynamic>> transactions,
  ) {
    var totalCredit = 0;
    var totalDebit = 0;

    for (final tx in transactions) {
      final amount = normalizeAmount(tx['amount']);
      final type = tx['type']?.toString() ?? 'debit';
      if (type == 'credit') {
        totalCredit += amount;
      } else {
        totalDebit += amount;
      }
    }

    return TransactionSummary(
      remainingAmount: totalCredit - totalDebit,
      totalCredit: totalCredit,
      totalDebit: totalDebit,
    );
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
