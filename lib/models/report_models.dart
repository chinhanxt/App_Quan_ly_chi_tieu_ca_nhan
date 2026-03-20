/// Report Models - Các model dữ liệu cho tính năng thống kê báo cáo
/// 
/// Bao gồm:
/// - TransactionDetail: Chi tiết một giao dịch
/// - CategoryBreakdown: Phân tích theo danh mục
/// - ExtremTransaction: Giao dịch lớn nhất/nhỏ nhất
/// - ForecastData: Dữ liệu dự báo chi tiêu
/// - MonthComparison: So sánh tháng
/// - ReportData: Báo cáo chính (tổng hợp)

import 'package:intl/intl.dart';

/// Chi tiết một giao dịch trong báo cáo
class TransactionDetail {
  final String id;
  final String title;
  final int amount;
  final String type; // 'credit' hoặc 'debit'
  final String category;
  final DateTime date;

  TransactionDetail({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  /// Chuyển đổi từ Firestore document
  factory TransactionDetail.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    return TransactionDetail(
      id: docId,
      title: data['title'] ?? '',
      amount: data['amount'] ?? 0,
      type: data['type'] ?? 'debit',
      category: data['category'] ?? 'Khác',
      date: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
    );
  }

  @override
  String toString() => '$title - $amount VND ($category) on $date';
}

/// Phân tích chi tiết theo danh mục
class CategoryBreakdown {
  final String categoryName;
  final int totalAmount;
  final int transactionCount;
  final double percentage;
  final String type; // 'credit' hoặc 'debit'
  final List<TransactionDetail> transactions;

  CategoryBreakdown({
    required this.categoryName,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
    required this.type,
    required this.transactions,
  });

  @override
  String toString() =>
      '$categoryName: $totalAmount VND (${percentage.toStringAsFixed(1)}%, $transactionCount giao dịch)';
}

/// Giao dịch lớn nhất/nhỏ nhất
class ExtremTransaction {
  final TransactionDetail transaction;
  final double percentage; // % của tổng

  ExtremTransaction({
    required this.transaction,
    required this.percentage,
  });

  @override
  String toString() =>
      '${transaction.title} - ${transaction.amount} VND (${percentage.toStringAsFixed(1)}% of total)';
}


/// Dữ liệu dự báo chi tiêu
class ForecastData {
  final int predictedAmount;
  final int benchmarkAmount; // Trung bình của khoảng quan sát
  final double growthRate; // % thay đổi so với trung bình
  final List<int> historicalData; // Dữ liệu lịch sử (tổng tiền mỗi tháng)
  final String methodology; // "Weighted Average" hoặc "Simple Average"

  ForecastData({
    required this.predictedAmount,
    required this.benchmarkAmount,
    required this.growthRate,
    required this.historicalData,
    this.methodology = "Weighted Average",
  });

  /// Lấy nhãn mô tả dự báo
  String getDescription() {
    final trend = growthRate >= 0 ? 'tăng' : 'giảm';
    final absRate = growthRate.abs().toStringAsFixed(1);
    return 'Dự báo $predictedAmount VND (${trend.toUpperCase()} $absRate%)';
  }

  @override
  String toString() => getDescription();
}

/// So sánh chi tiêu: tháng hiện tại vs tháng trước
class MonthComparison {
  final int currentAmount;
  final int previousAmount;
  final int difference;
  final double percentageChange; // % thay đổi
  final String trend; // 'increase', 'decrease', 'stable'

  MonthComparison({
    required this.currentAmount,
    required this.previousAmount,
    required this.difference,
    required this.percentageChange,
    required this.trend,
  });

  /// Lấy nhãn mô tả xu hướng
  String getTrendLabel() {
    switch (trend) {
      case 'increase':
        return '⬆️ Tăng ${percentageChange.toStringAsFixed(1)}%';
      case 'decrease':
        return '⬇️ Giảm ${percentageChange.abs().toStringAsFixed(1)}%';
      default:
        return '➡️ Ổn định';
    }
  }

  @override
  String toString() =>
      'Current: $currentAmount VND, Previous: $previousAmount VND, ${getTrendLabel()}';
}

/// Báo cáo chính (tổng hợp tất cả dữ liệu)
class ReportData {
  final DateTime reportDate; // Ngày tạo báo cáo
  final DateTime startDate;
  final DateTime endDate;
  final String periodLabel; // "Tháng 3 - 2026", "Quý 1 - 2026"

  // Tổng hợp cơ bản
  final int totalCredit;
  final int totalDebit;
  final int netAmount; // totalCredit - totalDebit

  // So sánh với tháng trước
  final MonthComparison creditComparison;
  final MonthComparison debitComparison;

  // Phân tích chi tiết
  final List<CategoryBreakdown> creditByCategory;
  final List<CategoryBreakdown> debitByCategory;

  // Giao dịch cực trị
  final ExtremTransaction? largestCredit;
  final ExtremTransaction? largestDebit;
  final ExtremTransaction? smallestCredit;
  final ExtremTransaction? smallestDebit;


  // Dự báo
  final ForecastData? debitForecast; // Dự báo chi tiêu
  final ForecastData? creditForecast;

  // Tất cả giao dịch trong khoảng
  final List<TransactionDetail> allTransactions;

  ReportData({
    required this.reportDate,
    required this.startDate,
    required this.endDate,
    required this.periodLabel,
    required this.totalCredit,
    required this.totalDebit,
    required this.netAmount,
    required this.creditComparison,
    required this.debitComparison,
    required this.creditByCategory,
    required this.debitByCategory,
    required this.largestCredit,
    required this.largestDebit,
    required this.smallestCredit,
    required this.smallestDebit,
    required this.debitForecast,
    required this.creditForecast,
    required this.allTransactions,
  });

  /// Định dạng ngày tạo báo cáo theo tiếng Việt
  String get formattedReportDate {
    return DateFormat('HH:mm - dd/MM/yyyy', 'vi').format(reportDate);
  }

  /// Định dạng ngày bắt đầu
  String get formattedStartDate {
    return DateFormat('dd/MM/yyyy', 'vi').format(startDate);
  }

  /// Định dạng ngày kết thúc
  String get formattedEndDate {
    return DateFormat('dd/MM/yyyy', 'vi').format(endDate);
  }

  /// Lấy tóm tắt báo cáo
  String getSummary() {
    return '''
BÁOÇÁO THỐNG KÊ CHI TIÊU
Khoảng: $periodLabel ($formattedStartDate - $formattedEndDate)
Tạo lúc: $formattedReportDate

📊 TỔNG HỢP CƠ BẢN:
  Thu nhập: $totalCredit VND
  Chi tiêu: $totalDebit VND
  Lợi nhuận: $netAmount VND (${(netAmount / totalCredit * 100).toStringAsFixed(1)}%)

📈 SO SÁNH THÁNG TRƯỚC:
  Thu: ${creditComparison.getTrendLabel()}
  Chi: ${debitComparison.getTrendLabel()}

 DỰ BÁO THÁNG SAU:
  Chi: ${debitForecast?.getDescription() ?? 'Không có dữ liệu'}
''';
  }

  @override
  String toString() => getSummary();
}
