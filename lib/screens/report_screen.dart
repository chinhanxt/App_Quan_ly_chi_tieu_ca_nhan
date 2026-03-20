import 'package:flutter/material.dart';
import 'package:app/models/report_models.dart';
import 'package:app/services/report_service.dart';
import 'package:app/services/pdf_export_service.dart';
import 'package:app/widgets/chart_widgets.dart';
import 'package:app/widgets/report_widgets.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late ReportService _reportService;
  late PdfExportService _pdfExportService;

  DateTime _selectedDate = DateTime.now();
  ReportData? _reportData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reportService = ReportService();
    _pdfExportService = PdfExportService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateReport();
    });
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    try {
      // Luôn lấy dữ liệu tối đa 24 tháng để đảm bảo biểu đồ con có đủ dải dữ liệu vẽ
      final report = await _reportService.generateReport(
        _selectedDate,
        observationMonths: 24,
      );
      if (!mounted) return;
      setState(() {
        _reportData = report;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog('Lỗi khi tạo báo cáo: $e');
    }
  }

  Future<void> _exportPdf() async {
    if (_reportData == null) return;

    // KIỂM TRA: Nếu không có bất kỳ giao dịch nào trong tháng
    if (_reportData!.allTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không có dữ liệu giao dịch trong tháng này để xuất báo cáo!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _showLoadingDialog('Đang tạo PDF...');
    try {
      final filePath = await _pdfExportService.exportReportToPdf(_reportData!);
      if (!mounted) return;
      Navigator.pop(context);
      if (filePath != null) {
        _showSuccessDialog('Báo cáo đã sẵn sàng:\n$filePath', filePath);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorDialog('Lỗi khi xuất PDF: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message)
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Thành Công'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Share.shareXFiles([XFile(filePath)], text: 'Báo cáo chi tiêu');
            },
            child: const Text('CHIA SẺ / TẢI VỀ'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final result = await OpenFilex.open(filePath);
                if (result.type != ResultType.done) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Không thể mở file: ${result.message}")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Lỗi khi mở file: $e")),
                );
              }
            },
            child: const Text('XEM'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ĐÓNG'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('❌ Lỗi'), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Báo Cáo', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _reportData == null 
                  ? const Center(child: Text("Không có dữ liệu"))
                  : _buildReportContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String monthYearLabel = DateFormat('MMMM yyyy', 'vi').format(_selectedDate);
    monthYearLabel = monthYearLabel[0].toUpperCase() + monthYearLabel.substring(1);

    return Container(
      color: const Color(0xFF3498DB),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () {
              setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1));
              _generateReport();
            },
          ),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(25)),
              child: Row(
                children: [
                  Text(monthYearLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            onPressed: () {
              setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1));
              _generateReport();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000), 
      lastDate: DateTime(2100),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _generateReport();
    }
  }

  Widget _buildReportContent() {
    final report = _reportData!;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildComparisonSection(report),
        const SizedBox(height: 24),
        TransactionListWidget(transactions: report.allTransactions),
        const SizedBox(height: 24),
        _buildChartsSection(report),
        const SizedBox(height: 24),
        _buildExtremTransactionsSection(report),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildComparisonSection(ReportData report) {
    return Column(children: [
      ComparisonCard(title: 'Thu nhập', comparison: report.creditComparison),
      ComparisonCard(title: 'Chi tiêu', comparison: report.debitComparison),
    ]);
  }

  Widget _buildChartsSection(ReportData report) {
    return Column(
      children: [
        if (report.debitByCategory.isNotEmpty) CategoryPieChart(categories: report.debitByCategory, title: '🔍 Chi Tiêu Theo Danh Mục'),
        if (report.creditByCategory.isNotEmpty) CategoryPieChart(categories: report.creditByCategory, title: '🔍 Thu Nhập Theo Danh Mục'),
        MonthComparisonBarChart(creditComparison: report.creditComparison, debitComparison: report.debitComparison),
        if (report.debitForecast?.historicalData.isNotEmpty ?? false)
          TrendLineChart(
            historicalData: report.debitForecast!.historicalData, 
            type: 'debit',
            selectedDate: _selectedDate,
          ),
        if (report.creditForecast?.historicalData.isNotEmpty ?? false)
          TrendLineChart(
            historicalData: report.creditForecast!.historicalData, 
            type: 'credit',
            selectedDate: _selectedDate,
          ),
      ],
    );
  }

  Widget _buildExtremTransactionsSection(ReportData report) {
    return Column(children: [
      ExtremTransactionsWidget(largest: report.largestDebit, smallest: report.smallestDebit, type: 'debit'),
      ExtremTransactionsWidget(largest: report.largestCredit, smallest: report.smallestCredit, type: 'credit'),
    ]);
  }
}
