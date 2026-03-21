// Report Service - Logic tính toán thống kê và phân tích
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:app/models/report_models.dart';

class ReportService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<TransactionDetail>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final startMs = startDate.millisecondsSinceEpoch;
      final endMs = endDate.add(const Duration(days: 1)).millisecondsSinceEpoch;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('timestamp', isGreaterThanOrEqualTo: startMs)
          .where('timestamp', isLessThan: endMs)
          .get();

      final transactions = <TransactionDetail>[];
      for (var doc in querySnapshot.docs) {
        transactions.add(TransactionDetail.fromFirestore(doc.id, doc.data()));
      }

      transactions.sort((a, b) => b.date.compareTo(a.date));
      return transactions;
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }

  MonthComparison compareWithPreviousMonth(
    List<TransactionDetail> currentMonth,
    List<TransactionDetail> previousMonth,
    String type,
  ) {
    final currentFiltered = currentMonth.where((t) => t.type == type).toList();
    final previousFiltered = previousMonth.where((t) => t.type == type).toList();

    final currentAmount = currentFiltered.fold<int>(
      0,
      (runningTotal, transaction) => runningTotal + transaction.amount,
    );
    final previousAmount = previousFiltered.fold<int>(
      0,
      (runningTotal, transaction) => runningTotal + transaction.amount,
    );

    final difference = currentAmount - previousAmount;
    final percentageChange = previousAmount == 0 ? 0.0 : (difference / previousAmount) * 100;

    String trend;
    if (percentageChange > 5) {
      trend = 'increase';
    } else if (percentageChange < -5) {
      trend = 'decrease';
    } else {
      trend = 'stable';
    }

    return MonthComparison(
      currentAmount: currentAmount,
      previousAmount: previousAmount,
      difference: difference,
      percentageChange: percentageChange.abs(),
      trend: trend,
    );
  }

  List<CategoryBreakdown> analyzeByCategory(
    List<TransactionDetail> transactions,
    String type,
  ) {
    final filtered = transactions.where((t) => t.type == type).toList();
    if (filtered.isEmpty) return [];

    final Map<String, List<TransactionDetail>> groupedByCategory = {};
    for (var transaction in filtered) {
      if (!groupedByCategory.containsKey(transaction.category)) {
        groupedByCategory[transaction.category] = [];
      }
      groupedByCategory[transaction.category]!.add(transaction);
    }

    final totalAmount = filtered.fold<int>(
      0,
      (runningTotal, transaction) => runningTotal + transaction.amount,
    );
    final breakdowns = <CategoryBreakdown>[];
    groupedByCategory.forEach((category, transactions) {
      final categoryTotal = transactions.fold<int>(
        0,
        (runningTotal, transaction) => runningTotal + transaction.amount,
      );
      final percentage = (categoryTotal / totalAmount) * 100;

      breakdowns.add(CategoryBreakdown(
        categoryName: category,
        totalAmount: categoryTotal,
        transactionCount: transactions.length,
        percentage: percentage,
        type: type,
        transactions: transactions,
      ));
    });

    breakdowns.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return breakdowns;
  }

  ExtremTransaction? findLargestTransaction(List<TransactionDetail> transactions) {
    if (transactions.isEmpty) return null;
    final TransactionDetail largest = transactions.reduce(
      (a, b) => a.amount > b.amount ? a : b,
    );
    final totalAmount = transactions.fold<int>(
      0,
      (runningTotal, transaction) => runningTotal + transaction.amount,
    );
    return ExtremTransaction(
      transaction: largest,
      percentage: (largest.amount / totalAmount) * 100,
    );
  }

  ExtremTransaction? findSmallestTransaction(List<TransactionDetail> transactions) {
    if (transactions.isEmpty) return null;
    final validTransactions = transactions.where((t) => t.amount > 0).toList();
    if (validTransactions.isEmpty) return null;
    final TransactionDetail smallest = validTransactions.reduce(
      (a, b) => a.amount < b.amount ? a : b,
    );
    final totalAmount = validTransactions.fold<int>(
      0,
      (runningTotal, transaction) => runningTotal + transaction.amount,
    );
    return ExtremTransaction(
      transaction: smallest,
      percentage: (smallest.amount / totalAmount) * 100,
    );
  }

  /// [CẬP NHẬT] Dự báo và xử lý dữ liệu lịch sử liên tục
  ForecastData? forecastNextMonth(
    List<TransactionDetail> transactions, {
    required DateTime reportDate,
    required int observationMonths,
    required String type,
  }) {
    final filtered = transactions.where((t) => t.type == type).toList();
    
    // Tạo danh sách các tháng liên tục từ quá khứ đến reportDate
    final List<int> monthlyTotals = [];
    for (int i = observationMonths - 1; i >= 0; i--) {
      final targetDate = DateTime(reportDate.year, reportDate.month - i, 1);
      final monthKey = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}';
      
      final monthTotal = filtered
          .where((t) => '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}' == monthKey)
          .fold<int>(
            0,
            (runningTotal, transaction) => runningTotal + transaction.amount,
          );
          
      monthlyTotals.add(monthTotal);
    }

    if (monthlyTotals.isEmpty) return null;

    // Tính Weighted Average cho dự báo (nếu có đủ ít nhất 3 tháng)
    int predictedAmount = 0;
    if (monthlyTotals.length >= 3) {
      double weightedSum = 0;
      double weightSum = 0;
      for (int i = 0; i < monthlyTotals.length; i++) {
        final weight = (i + 1).toDouble();
        weightedSum += monthlyTotals[i] * weight;
        weightSum += weight;
      }
      predictedAmount = (weightedSum / weightSum).round();
    } else {
      predictedAmount = (monthlyTotals.fold<int>(
                0,
                (runningTotal, total) => runningTotal + total,
              ) /
              monthlyTotals.length)
          .round();
    }

    final simpleAverage = (monthlyTotals.fold<int>(
              0,
              (runningTotal, total) => runningTotal + total,
            ) /
            monthlyTotals.length)
        .round();
    final growthRate = simpleAverage == 0 ? 0.0 : ((predictedAmount - simpleAverage) / simpleAverage) * 100;

    return ForecastData(
      predictedAmount: predictedAmount,
      benchmarkAmount: simpleAverage,
      growthRate: growthRate,
      historicalData: monthlyTotals,
      methodology: "Weighted Average",
    );
  }

  Future<ReportData> generateReport(
    DateTime reportDate, {
    int observationMonths = 12,
  }) async {
    final currentMonthStart = DateTime(reportDate.year, reportDate.month, 1);
    final currentMonthEnd = DateTime(reportDate.year, reportDate.month + 1, 1).subtract(const Duration(days: 1));

    final previousMonthDate = DateTime(reportDate.year, reportDate.month - 1);
    final previousMonthStart = DateTime(previousMonthDate.year, previousMonthDate.month, 1);
    final previousMonthEnd = DateTime(previousMonthDate.year, previousMonthDate.month + 1, 1).subtract(const Duration(days: 1));

    // Luôn lấy dữ liệu từ tháng xa nhất có thể quan sát được đến tháng hiện tại
    final observationStart = DateTime(reportDate.year, reportDate.month - observationMonths + 1, 1);

    final currentMonthTransactions = await getTransactionsByDateRange(currentMonthStart, currentMonthEnd);
    final previousMonthTransactions = await getTransactionsByDateRange(previousMonthStart, previousMonthEnd);
    final observationTransactions = await getTransactionsByDateRange(observationStart, currentMonthEnd);

    final totalCredit = currentMonthTransactions
        .where((t) => t.type == 'credit')
        .fold<int>(
          0,
          (runningTotal, transaction) => runningTotal + transaction.amount,
        );
    final totalDebit = currentMonthTransactions
        .where((t) => t.type == 'debit')
        .fold<int>(
          0,
          (runningTotal, transaction) => runningTotal + transaction.amount,
        );

    final creditComparison = compareWithPreviousMonth(currentMonthTransactions, previousMonthTransactions, 'credit');
    final debitComparison = compareWithPreviousMonth(currentMonthTransactions, previousMonthTransactions, 'debit');

    final creditByCategory = analyzeByCategory(currentMonthTransactions, 'credit');
    final debitByCategory = analyzeByCategory(currentMonthTransactions, 'debit');

    final creditTransactions = currentMonthTransactions.where((t) => t.type == 'credit').toList();
    final debitTransactions = currentMonthTransactions.where((t) => t.type == 'debit').toList();
    
    final largestCredit = findLargestTransaction(creditTransactions);
    final largestDebit = findLargestTransaction(debitTransactions);
    final smallestCredit = findSmallestTransaction(creditTransactions);
    final smallestDebit = findSmallestTransaction(debitTransactions);

    final debitForecast = forecastNextMonth(
      observationTransactions,
      reportDate: reportDate,
      observationMonths: observationMonths,
      type: 'debit',
    );
    final creditForecast = forecastNextMonth(
      observationTransactions,
      reportDate: reportDate,
      observationMonths: observationMonths,
      type: 'credit',
    );

    final periodLabel = '${_getMonthName(reportDate.month)} - ${reportDate.year}';

    return ReportData(
      reportDate: DateTime.now(),
      startDate: currentMonthStart,
      endDate: currentMonthEnd,
      periodLabel: periodLabel,
      totalCredit: totalCredit,
      totalDebit: totalDebit,
      netAmount: totalCredit - totalDebit,
      creditComparison: creditComparison,
      debitComparison: debitComparison,
      creditByCategory: creditByCategory,
      debitByCategory: debitByCategory,
      largestCredit: largestCredit,
      largestDebit: largestDebit,
      smallestCredit: smallestCredit,
      smallestDebit: smallestDebit,
      debitForecast: debitForecast,
      creditForecast: creditForecast,
      allTransactions: currentMonthTransactions,
    );
  }

  String _getMonthName(int month) {
    const monthNames = ['Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'];
    return monthNames[month - 1];
  }
}
