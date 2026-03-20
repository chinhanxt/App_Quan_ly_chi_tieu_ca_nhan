/// PDF Export Service - Xuất báo cáo dưới dạng PDF
///
/// Bao gồm:
/// - Tạo PDF với header, summary, charts
/// - Xuất CSV cho Excel
/// - Lưu file và chia sẻ
///
/// Dependencies cần thiết:
/// - pdf: ^3.10.0 (tạo PDF)
/// - printing: ^5.11.0 (in/chia sẻ PDF)
/// - path_provider: ^2.1.0 (lấy path lưu file)

import 'dart:io';
import 'package:app/models/report_models.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class PdfExportService {
  /// Xuất báo cáo thành PDF
  ///
  /// Note: Cần import 'package:pdf/pdf.dart' và 'package:pdf/widgets.dart'
  /// khi chính thức generate PDF
  ///
  /// Parameters:
  ///   - report: Đối tượng ReportData đã generate
  ///   - fileName: Tên file (mặc định: Report_YYYY-MM-DD)
  ///
  /// Returns: Path của file PDF đã lưu
  Future<String?> exportReportToPdf(
    ReportData report, {
    String? fileName,
  }) async {
    try {
      print('📄 Đang tạo PDF báo cáo...');

      // Tên file mặc định
      fileName ??=
          'Report_${DateFormat('yyyy-MM-dd_HHmm').format(report.reportDate)}';

      // Tạo nội dung PDF (HTML format)
      final htmlContent = _generateHtmlContent(report);

      // Lưu file
      final pdfPath = await _savePdfFile(htmlContent, fileName);

      print('✅ PDF đã lưu: $pdfPath');
      return pdfPath;
    } catch (e) {
      print('❌ Lỗi khi export PDF: $e');
      return null;
    }
  }

  /// Xuất báo cáo thành CSV (để mở trong Excel)
  ///
  /// Parameters:
  ///   - report: Đối tượng ReportData đã generate
  ///   - fileName: Tên file (mặc định: Report_YYYY-MM-DD.csv)
  ///
  /// Returns: Path của file CSV đã lưu
  Future<String?> exportReportToCsv(
    ReportData report, {
    String? fileName,
  }) async {
    try {
      print('📊 Đang tạo file CSV...');

      fileName ??=
          'Report_${DateFormat('yyyy-MM-dd_HHmm').format(report.reportDate)}.csv';

      // Tạo nội dung CSV
      final csvContent = _generateCsvContent(report);

      // Lưu file
      final csvPath = await _saveCsvFile(csvContent, fileName);

      print('✅ CSV đã lưu: $csvPath');
      return csvPath;
    } catch (e) {
      print('❌ Lỗi khi export CSV: $e');
      return null;
    }
  }

  /// [PRIVATE] Tạo nội dung HTML cho PDF
  String _generateHtmlContent(ReportData report) {
    final monthLabel = report.periodLabel;
    final createdTime = report.formattedReportDate;

    // Tính năng đầu tiên: Header & Summary
    final summarySection =
        '''
    <section style="page-break-after: always;">
      <div style="text-align: center; margin-bottom: 30px;">
        <h1 style="color: #2c3e50; font-size: 20px; margin: 0;">📊 BÁO CÁO THỐNG KÊ CHI TIÊU</h1>
        <p style="font-size: 16px; color: #7f8c8d; margin: 10px 0;">Khoảng: <strong>$monthLabel</strong></p>
        <p style="font-size: 14px; color: #95a5a6;">
          ${report.formattedStartDate} - ${report.formattedEndDate}
        </p>
        <p style="font-size: 12px; color: #bdc3c7; margin-top: 20px;">
          Tạo lúc: $createdTime
        </p>
      </div>

      <!-- TỔNG HỢP CƠ BẢN -->
      <div style="background: #ecf0f1; padding: 20px; border-radius: 8px; margin-bottom: 30px;">
        <h2 style="color: #2c3e50; font-size: 18px; margin: 0 0 15px 0;">Tổng Hợp Cơ Bản</h2>
        <table style="width: 100%; border-collapse: collapse;">
          <tr>
            <td style="padding: 10px; border-bottom: 1px solid #bdc3c7;"><strong>💰 Thu Nhập</strong></td>
            <td style="padding: 10px; border-bottom: 1px solid #bdc3c7; text-align: right; color: #27ae60; font-weight: bold;">
              ${_formatCurrency(report.totalCredit)} VND
            </td>
          </tr>
          <tr>
            <td style="padding: 10px; border-bottom: 1px solid #bdc3c7;"><strong>💸 Chi Tiêu</strong></td>
            <td style="padding: 10px; border-bottom: 1px solid #bdc3c7; text-align: right; color: #e74c3c; font-weight: bold;">
              ${_formatCurrency(report.totalDebit)} VND
            </td>
          </tr>
          <tr>
            <td style="padding: 10px;"><strong>📈 Lợi Nhuận Ròng</strong></td>
            <td style="padding: 10px; text-align: right; color: ${report.netAmount >= 0 ? '#27ae60' : '#e74c3c'}; font-weight: bold; font-size: 16px;">
              ${_formatCurrency(report.netAmount)} VND
            </td>
          </tr>
        </table>
      </div>

      <!-- SO SÁNH THÁNG TRƯỚC -->
      <div style="background: #fef5e7; padding: 20px; border-radius: 8px; margin-bottom: 30px;">
        <h2 style="color: #2c3e50; font-size: 18px; margin: 0 0 15px 0;">📊 So Sánh Với Tháng Trước</h2>
        <table style="width: 100%; border-collapse: collapse;">
          <tr>
            <td style="padding: 10px; border-bottom: 1px solid #bdc3c7;"><strong>Thu Nhập</strong></td>
            <td style="padding: 10px; border-bottom: 1px solid #bdc3c7; color: #7f8c8d;">
              ${report.creditComparison.getTrendLabel()}
            </td>
            <td style="padding: 10px; border-bottom: 1px solid #bdc3c7; text-align: right; font-size: 12px; color: #95a5a6;">
              Tháng trước: ${_formatCurrency(report.creditComparison.previousAmount)} VND
            </td>
          </tr>
          <tr>
            <td style="padding: 10px;"><strong>Chi Tiêu</strong></td>
            <td style="padding: 10px; color: #7f8c8d;">
              ${report.debitComparison.getTrendLabel()}
            </td>
            <td style="padding: 10px; text-align: right; font-size: 12px; color: #95a5a6;">
              Tháng trước: ${_formatCurrency(report.debitComparison.previousAmount)} VND
            </td>
          </tr>
        </table>
      </div>
    </section>
    ''';

    // Tính năng thứ hai: Chi tiết phân tích
    final categoryAnalysisSection = _generateCategoryAnalysisHtml(report);

    // Tính năng thứ ba: Giao dịch cực trị
    final extremTransactionsSection = _generateExtremTransactionsHtml(report);

    // (removed recurring transactions section)

    // Tính năng thứ năm: Dự báo
    final forecastSection = _generateForecastHtml(report);

    // Tính năng thứ sáu: Danh sách giao dịch
    final transactionsListSection = _generateTransactionsListHtml(report);

    // Gộp tất cả
    return '''
    <!DOCTYPE html>
    <html lang="vi">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Báo Cáo Thống Kê</title>
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          color: #2c3e50;
          line-height: 1.6;
          background: white;
          padding-bottom: 80px; /* Chừa chỗ cho nút bấm */
        }
        .download-btn {
          position: fixed;
          bottom: 20px;
          right: 20px;
          background: #27ae60;
          color: white;
          padding: 15px 25px;
          border-radius: 50px;
          text-decoration: none;
          font-weight: bold;
          box-shadow: 0 4px 15px rgba(0,0,0,0.2);
          z-index: 1000;
          border: none;
          cursor: pointer;
          font-size: 16px;
        }
        @media print {
          .download-btn { display: none; } /* Không hiện nút khi in */
        }
        h1 { font-size: 24px; margin: 20px 0; }
        h2 { font-size: 18px; margin: 15px 0 10px 0; }
        table {
          width: 100%;
          border-collapse: collapse;
          margin: 15px 0;
        }
        th {
          background: #34495e;
          color: white;
          padding: 10px;
          text-align: left;
        }
        td {
          padding: 10px;
          border-bottom: 1px solid #ecf0f1;
        }
        tr:hover { background: #f5f5f5; }
        .positive { color: #27ae60; font-weight: bold; }
        .negative { color: #e74c3c; font-weight: bold; }
        .neutral { color: #7f8c8d; }
        section {
          margin: 20px 0;
        }
      </style>
    </head>
    <body>
      <button class="download-btn" onclick="window.print()">🖨️ In / Tải về PDF</button>
      $summarySection
      $categoryAnalysisSection
      $extremTransactionsSection
      $forecastSection
      $transactionsListSection
    </body>
    </html>
    ''';
  }

  /// [PRIVATE] HTML cho phần phân tích danh mục
  String _generateCategoryAnalysisHtml(ReportData report) {
    if (report.debitByCategory.isEmpty && report.creditByCategory.isEmpty) {
      return '<p style="color: #95a5a6;">Không có dữ liệu</p>';
    }

    String debitHtml = _generateCategoryTableHtml(
      'Chi Tiêu Theo Danh Mục',
      report.debitByCategory,
    );
    String creditHtml = _generateCategoryTableHtml(
      'Thu Nhập Theo Danh Mục',
      report.creditByCategory,
    );

    return '''
    <section style="page-break-after: always;">
      <h2 style="color: #2c3e50; font-size: 18px; margin-bottom: 15px;">🔍 Phân Tích Chi Tiết Theo Danh Mục</h2>
      $debitHtml
      $creditHtml
    </section>
    ''';
  }

  /// [PRIVATE] Tạo bảng danh mục
  String _generateCategoryTableHtml(
    String title,
    List<CategoryBreakdown> categories,
  ) {
    if (categories.isEmpty) {
      return '<p style="color: #95a5a6;">Không có dữ liệu</p>';
    }

    String rows = '';
    for (var category in categories) {
      rows +=
          '''
      <tr>
        <td><strong>${category.categoryName}</strong></td>
        <td>${_formatCurrency(category.totalAmount)} VND</td>
        <td>${category.transactionCount} giao dịch</td>
        <td style="text-align: right;">${category.percentage.toStringAsFixed(1)}%</td>
      </tr>
      ''';
    }

    return '''
    <div style="margin-bottom: 20px;">
      <h3 style="font-size: 16px; color: #34495e; margin-bottom: 10px;">$title</h3>
      <table style="width: 100%; border-collapse: collapse;">
        <tr style="background: #ecf0f1;">
          <th>Danh Mục</th>
          <th>Tổng Tiền</th>
          <th>Số Lượng</th>
          <th style="text-align: right;">Tỷ Lệ</th>
        </tr>
        $rows
      </table>
    </div>
    ''';
  }

  /// [PRIVATE] HTML cho phần giao dịch cực trị
  String _generateExtremTransactionsHtml(ReportData report) {
    String extremHtml =
        '<h2 style="color: #2c3e50; font-size: 18px; margin-bottom: 15px;">💰 Giao Dịch Cực Trị</h2>';

    // Giao dịch chi tiêu lớn nhất
    if (report.largestDebit != null) {
      extremHtml +=
          '''
      <div style="background: #ffe6e6; padding: 15px; border-radius: 8px; margin-bottom: 10px;">
        <strong>💸 Chi Tiêu Lớn Nhất:</strong>
        ${report.largestDebit!.transaction.title} - ${_formatCurrency(report.largestDebit!.transaction.amount)} VND
        <span style="color: #95a5a6; font-size: 12px;"> (${report.largestDebit!.percentage.toStringAsFixed(1)}% của tổng chi tiêu)</span>
      </div>
      ''';
    }

    // Giao dịch chi tiêu nhỏ nhất
    if (report.smallestDebit != null) {
      extremHtml +=
          '''
      <div style="background: #e6f7ff; padding: 15px; border-radius: 8px; margin-bottom: 10px;">
        <strong>💸 Chi Tiêu Nhỏ Nhất:</strong>
        ${report.smallestDebit!.transaction.title} - ${_formatCurrency(report.smallestDebit!.transaction.amount)} VND
        <span style="color: #95a5a6; font-size: 12px;"> (${report.smallestDebit!.percentage.toStringAsFixed(1)}% của tổng chi tiêu)</span>
      </div>
      ''';
    }

    return '''
    <section style="page-break-after: auto;">
      $extremHtml
    </section>
    ''';
  }

  /// [PRIVATE] HTML cho phần dự báo
  String _generateForecastHtml(ReportData report) {
    String forecastHtml =
        '<h2 style="color: #2c3e50; font-size: 18px; margin-bottom: 15px;">🎯 Dự Báo Tháng Tiếp Theo</h2>';

    // Dự báo chi tiêu
    if (report.debitForecast != null) {
      final forecast = report.debitForecast!;
      final trendIcon = forecast.growthRate >= 0 ? '📈' : '📉';
      forecastHtml +=
          '''
      <div style="background: #fff3cd; padding: 15px; border-radius: 8px; margin-bottom: 10px;">
        <strong>$trendIcon Chi Tiêu Dự Báo:</strong>
        <span style="font-size: 20px; color: #e74c3c;">${_formatCurrency(forecast.predictedAmount)} VND</span>
        <div style="margin-top: 10px; font-size: 12px; color: #7f8c8d;">
          <p>So với trung bình: ${_formatCurrency(forecast.benchmarkAmount)} VND</p>
          <p>Xu hướng: ${forecast.growthRate >= 0 ? 'Tăng' : 'Giảm'} ${forecast.growthRate.abs().toStringAsFixed(1)}%</p>
        </div>
      </div>
      ''';
    }

    // Dự báo thu nhập
    if (report.creditForecast != null) {
      final forecast = report.creditForecast!;
      final trendIcon = forecast.growthRate >= 0 ? '📈' : '📉';
      forecastHtml +=
          '''
      <div style="background: #d4edda; padding: 15px; border-radius: 8px;">
        <strong>$trendIcon Thu Nhập Dự Báo:</strong>
        <span style="font-size: 20px; color: #27ae60;">${_formatCurrency(forecast.predictedAmount)} VND</span>
        <div style="margin-top: 10px; font-size: 12px; color: #7f8c8d;">
          <p>So với trung bình: ${_formatCurrency(forecast.benchmarkAmount)} VND</p>
          <p>Xu hướng: ${forecast.growthRate >= 0 ? 'Tăng' : 'Giảm'} ${forecast.growthRate.abs().toStringAsFixed(1)}%</p>
        </div>
      </div>
      ''';
    }

    return '''
    <section style="page-break-after: auto;">
      $forecastHtml
    </section>
    ''';
  }

  /// [PRIVATE] HTML cho danh sách giao dịch chi tiết
  String _generateTransactionsListHtml(ReportData report) {
    if (report.allTransactions.isEmpty) {
      return '''
      <section style="page-break-before: always;">
        <h2 style="color: #2c3e50; font-size: 18px; margin-bottom: 15px;">📝 Danh Sách Giao Dịch Chi Tiết</h2>
        <p style="color: #95a5a6;">Không có giao dịch trong khoảng thời gian này</p>
      </section>
      ''';
    }

    String rows = '';
    for (var transaction in report.allTransactions) {
      final typeLabel = transaction.type == 'credit'
          ? '+ Thu Nhập'
          : '- Chi Tiêu';
      final colorClass = transaction.type == 'credit' ? 'positive' : 'negative';
      final formattedDate = DateFormat(
        'dd/MM/yyyy',
        'vi',
      ).format(transaction.date);

      rows +=
          '''
      <tr>
        <td>$formattedDate</td>
        <td>${transaction.title}</td>
        <td>${transaction.category}</td>
        <td class="$colorClass">$typeLabel ${_formatCurrency(transaction.amount)} VND</td>
      </tr>
      ''';
    }

    return '''
    <section style="page-break-before: always;">
      <h2 style="color: #2c3e50; font-size: 18px; margin-bottom: 15px;">📝 Danh Sách Giao Dịch Chi Tiết</h2>
      <p style="color: #7f8c8d; font-size: 12px; margin-bottom: 10px;">
        Tổng ${report.allTransactions.length} giao dịch trong ${report.periodLabel}
      </p>
      <table style="width: 100%; border-collapse: collapse;">
        <tr style="background: #34495e; color: white;">
          <th>Ngày</th>
          <th>Tiêu Đề</th>
          <th>Danh Mục</th>
          <th>Chi Tiêu/Thu Nhập</th>
        </tr>
        $rows
      </table>
    </section>
    ''';
  }

  /// [PRIVATE] Tạo nội dung CSV
  String _generateCsvContent(ReportData report) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('BÁOÇÁO THỐNG KÊ CHI TIÊU');
    buffer.writeln('Khoảng,${report.periodLabel}');
    buffer.writeln('Từ ngày,${report.formattedStartDate}');
    buffer.writeln('Đến ngày,${report.formattedEndDate}');
    buffer.writeln('Tạo lúc,${report.formattedReportDate}');
    buffer.writeln('');

    // Tổng hợp
    buffer.writeln('TỔNG HỢP CƠ BẢN');
    buffer.writeln('Loại,Số tiền ( VND)');
    buffer.writeln('Thu Nhập,${report.totalCredit}');
    buffer.writeln('Chi Tiêu,${report.totalDebit}');
    buffer.writeln('Lợi Nhuận,${report.netAmount}');
    buffer.writeln('');

    // So sánh
    buffer.writeln('SO SÁNH THÁNG TRƯỚC');
    buffer.writeln('Loại,Tháng Này,Tháng Trước,Thay Đổi %');
    buffer.writeln(
      'Thu Nhập,${report.creditComparison.currentAmount},${report.creditComparison.previousAmount},${report.creditComparison.percentageChange.toStringAsFixed(2)}',
    );
    buffer.writeln(
      'Chi Tiêu,${report.debitComparison.currentAmount},${report.debitComparison.previousAmount},${report.debitComparison.percentageChange.toStringAsFixed(2)}',
    );
    buffer.writeln('');

    // Phân tích danh mục - Chi tiêu
    if (report.debitByCategory.isNotEmpty) {
      buffer.writeln('PHÂN TÍCH - CHI TIÊU THEO DANH MỤC');
      buffer.writeln('Danh Mục,Số Tiền ( VND),Số Lượng,Tỷ Lệ %');
      for (var category in report.debitByCategory) {
        buffer.writeln(
          '${category.categoryName},${category.totalAmount},${category.transactionCount},${category.percentage.toStringAsFixed(2)}',
        );
      }
      buffer.writeln('');
    }

    // Danh sách giao dịch
    if (report.allTransactions.isNotEmpty) {
      buffer.writeln('DANH SÁCH GIAO DỊCH');
      buffer.writeln('Ngày,Tiêu Đề,Danh Mục,Loại,Số Tiền ( VND)');
      for (var transaction in report.allTransactions) {
        final formattedDate = DateFormat(
          'dd/MM/yyyy',
          'vi',
        ).format(transaction.date);
        buffer.writeln(
          '$formattedDate,"${transaction.title}",${transaction.category},${transaction.type},${transaction.amount}',
        );
      }
    }

    return buffer.toString();
  }

  /// [PRIVATE] Lưu file PDF
  ///
  /// Note: Hiện tại lưu dưới dạng HTML
  /// Có thể nâng cấp để sinh PDF thực sự
  Future<String?> _savePdfFile(String htmlContent, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.html';

      final file = File(filePath);
      await file.writeAsString(htmlContent);

      print('✅ File đã lưu: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Lỗi lưu file: $e');
      return null;
    }
  }

  /// [PRIVATE] Lưu file CSV
  Future<String?> _saveCsvFile(String csvContent, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csvContent);

      print('✅ CSV đã lưu: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Lỗi lưu CSV: $e');
      return null;
    }
  }

  /// Helper: Format tiền tệ
  String _formatCurrency(int amount) {
    final formatter = NumberFormat.decimalPattern('vi_VN');
    return formatter.format(amount);
  }
}
