import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/widgets/app_chrome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CategoryAnalysisScreen extends StatefulWidget {
  final String categoryName;
  const CategoryAnalysisScreen({super.key, required this.categoryName});

  @override
  State<CategoryAnalysisScreen> createState() => _CategoryAnalysisScreenState();
}

class _CategoryAnalysisScreenState extends State<CategoryAnalysisScreen> {
  late DateTimeRange _selectedDateRange;
  final currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VND',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedDateRange,
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Lỗi xác thực")));

    return AppScaffold(
      appBar: AppBar(
        title: Text("Phân tích: ${widget.categoryName}"),
        actions: [
          IconButton(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];
          final startTime = _selectedDateRange.start.millisecondsSinceEpoch;
          final endTime = _selectedDateRange.end
              .add(const Duration(days: 1))
              .millisecondsSinceEpoch;

          final docs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['category'] == widget.categoryName &&
                data['timestamp'] >= startTime &&
                data['timestamp'] <= endTime;
          }).toList();

          if (docs.isEmpty) return _buildEmptyState();

          double totalAmount = 0;
          Map<String, double> dailyData = {};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] as num).toDouble();
            totalAmount += amount;
            final date = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
            final dateKey = DateFormat('dd/MM').format(date);
            dailyData[dateKey] = (dailyData[dateKey] ?? 0) + amount;
          }

          double average =
              totalAmount / (_selectedDateRange.duration.inDays + 1);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeroHeader(
                  title: widget.categoryName,
                  subtitle:
                      "Phân tích xu hướng chi tiêu theo danh mục trong khoảng thời gian đang chọn.",
                  trailing: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildHeaderInfo(totalAmount, average),
                const SizedBox(height: 24),
                const AppSectionTitle(title: "Xu hướng chi tiêu"),
                const SizedBox(height: 12),
                _buildModernChart(dailyData),
                const SizedBox(height: 24),
                const AppSectionTitle(title: "Lịch sử chi tiết"),
                const SizedBox(height: 12),
                _buildTransactionList(docs),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderInfo(double total, double avg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Tổng chi tiêu",
            style: TextStyle(color: AppColors.accentSoft, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _formatFullVND(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _columnInfo("Trung bình/ngày", _formatFullVND(avg)),
              _columnInfo(
                "Thời gian",
                "${DateFormat('dd/MM').format(_selectedDateRange.start)} - ${DateFormat('dd/MM').format(_selectedDateRange.end)}",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _columnInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.accentSoft, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildModernChart(Map<String, double> data) {
    List<String> sortedKeys = data.keys.toList()
      ..sort((a, b) {
        // Sắp xếp theo ngày tháng thực tế thay vì chuỗi
        var partsA = a.split('/');
        var partsB = b.split('/');
        var dateA = DateTime(2026, int.parse(partsA[1]), int.parse(partsA[0]));
        var dateB = DateTime(2026, int.parse(partsB[1]), int.parse(partsB[0]));
        return dateA.compareTo(dateB);
      });

    if (sortedKeys.length > 10)
      sortedKeys = sortedKeys.sublist(sortedKeys.length - 10);
    List<FlSpot> spots = sortedKeys
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), data[e.value]!))
        .toList();

    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 24, 24, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey[100]!, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < sortedKeys.length && idx % 2 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        sortedKeys[idx],
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.accentStrong,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: AppColors.accentStrong,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentStrong.withValues(alpha: 0.2),
                    AppColors.accentStrong.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => AppColors.primary,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${_formatFullVND(spot.y)}\n${sortedKeys[spot.x.toInt()]}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<DocumentSnapshot> docs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final date = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF5FAF7)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.06),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            title: Text(
              data['title'] ?? "Không tiêu đề",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy HH:mm').format(date),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            trailing: Text(
              _formatFullVND((data['amount'] as num).toDouble()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: data['type'] == 'credit'
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                fontSize: 15,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatFullVND(double amount) {
    return currencyFormat.format(amount).trim();
  }

  Widget _buildEmptyState() {
    return const AppEmptyState(
      icon: Icons.analytics_outlined,
      title: "Không có dữ liệu phân tích",
      message: "Chưa có giao dịch phù hợp trong khoảng thời gian đã chọn.",
    );
  }
}
