/// Chart Widgets - Các widget biểu đồ cho báo cáo
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:app/models/report_models.dart';

/// Pie Chart - Phân tích chi tiêu theo danh mục
class CategoryPieChart extends StatefulWidget {
  final List<CategoryBreakdown> categories;
  final String title;

  const CategoryPieChart({
    super.key,
    required this.categories,
    required this.title,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('Không có dữ liệu', style: TextStyle(color: Colors.grey[400])),
        ),
      );
    }

    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Orange
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFF64748B), // Slate
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[100]!),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: List.generate(widget.categories.length, (i) {
                    final isTouched = i == touchedIndex;
                    final fontSize = isTouched ? 16.0 : 12.0;
                    final radius = isTouched ? 70.0 : 60.0;
                    final category = widget.categories[i];
                    
                    return PieChartSectionData(
                      color: colors[i % colors.length],
                      value: category.percentage,
                      title: isTouched ? '${category.percentage.toStringAsFixed(0)}%' : '',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: List.generate(widget.categories.length, (i) {
                final category = widget.categories[i];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${category.categoryName} (${category.percentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: touchedIndex == i ? Colors.black : Colors.grey[600],
                        fontWeight: touchedIndex == i ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bar Chart - So sánh tháng
class MonthComparisonBarChart extends StatelessWidget {
  final MonthComparison creditComparison;
  final MonthComparison debitComparison;

  const MonthComparisonBarChart({
    super.key,
    required this.creditComparison,
    required this.debitComparison,
  });

  @override
  Widget build(BuildContext context) {
    final maxAmount = [
      creditComparison.currentAmount,
      creditComparison.previousAmount,
      debitComparison.currentAmount,
      debitComparison.previousAmount,
    ].reduce((a, b) => a > b ? a : b);

    final formatter = NumberFormat.decimalPattern('vi_VN');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey[100]!)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 So sánh với tháng trước',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem(const Color(0xFFE2E8F0), 'Tháng trước'),
                _buildLegendItem(const Color(0xFF3B82F6), 'Thu nhập (Tháng này)'),
                _buildLegendItem(const Color(0xFFEF4444), 'Chi tiêu (Tháng này)'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxAmount == 0 ? 1000 : maxAmount.toDouble() * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1E293B),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${formatter.format(rod.toY.toInt())} VND',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const style = TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 11);
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 10,
                            child: Text(value.toInt() == 0 ? 'Thu nhập' : 'Chi tiêu', style: style),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _makeGroupData(0, creditComparison.previousAmount.toDouble(), creditComparison.currentAmount.toDouble()),
                    _makeGroupData(1, debitComparison.previousAmount.toDouble(), debitComparison.currentAmount.toDouble()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      barsSpace: 8,
      x: x,
      barRods: [
        BarChartRodData(toY: y1, color: const Color(0xFFE2E8F0), width: 14, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: y2, color: x == 0 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444), width: 14, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }
}

/// Line Chart - Xu hướng chi/thu (CẬP NHẬT LOGIC TIMELINE)
class TrendLineChart extends StatefulWidget {
  final List<int> historicalData;
  final String type;
  final DateTime selectedDate;

  const TrendLineChart({
    super.key,
    required this.historicalData,
    required this.type,
    required this.selectedDate,
  });

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  int _displayMonths = 6; 

  @override
  void initState() {
    super.initState();
    // Khởi tạo số tháng hiển thị dựa trên dữ liệu hiện có, tối đa 6
    _displayMonths = widget.historicalData.length > 6 ? 6 : widget.historicalData.length;
    if (_displayMonths < 3) _displayMonths = 3; 
  }

  void _showCustomMonthPicker() {
    final controller = TextEditingController(text: _displayMonths.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tùy chọn số tháng"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Số tháng muốn xem",
            hintText: "Ví dụ: 9",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              int? val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() {
                  _displayMonths = val;
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Áp dụng"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.historicalData.isEmpty) return const SizedBox.shrink();

    // Lấy đúng số tháng yêu cầu tính ngược từ tháng đang chọn (điểm cuối historicalData là selectedDate)
    final dataToShow = widget.historicalData.length > _displayMonths 
        ? widget.historicalData.sublist(widget.historicalData.length - _displayMonths)
        : List<int>.filled(_displayMonths - widget.historicalData.length, 0) + widget.historicalData;

    final color = widget.type == 'credit' ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final maxVal = dataToShow.isEmpty ? 0.0 : dataToShow.reduce((a, b) => a > b ? a : b).toDouble();
    final fullFormatter = NumberFormat.decimalPattern('vi_VN');

    // Tạo danh sách tên tháng kết thúc tại widget.selectedDate
    List<String> monthLabels = [];
    for (int i = _displayMonths - 1; i >= 0; i--) {
      final date = DateTime(widget.selectedDate.year, widget.selectedDate.month - i, 1);
      monthLabels.add(DateFormat('MM/yy').format(date));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📈 Xu hướng ${widget.type == 'credit' ? 'thu nhập' : 'chi tiêu'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            Text(
              'Kết thúc tại ${DateFormat('MM/yyyy').format(widget.selectedDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...[3, 6, 12].map((m) {
                    bool isSelected = _displayMonths == m;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text('$m tháng', style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        backgroundColor: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
                        labelStyle: TextStyle(color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600),
                        onPressed: () => setState(() => _displayMonths = m),
                      ),
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.edit, size: 14),
                    label: const Text('Khác...', style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.grey.shade50,
                    onPressed: _showCustomMonthPicker,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade50, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx < 0 || idx >= monthLabels.length) return const Text('');
                          if (dataToShow.length > 8 && idx % 2 != 0 && idx != dataToShow.length - 1) return const Text('');
                          
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 10,
                            child: Text(
                              monthLabels[idx],
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataToShow.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: color,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: color,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1E293B),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          return LineTooltipItem(
                            '${monthLabels[touchedSpot.x.toInt()]}\n${fullFormatter.format(touchedSpot.y.toInt())} VND',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  minX: 0,
                  maxX: (_displayMonths - 1).toDouble(),
                  maxY: maxVal == 0 ? 1000 : maxVal * 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Widget - Hiển thị Forecast
class ForecastCard extends StatelessWidget {
  final ForecastData? forecast;
  final String type;

  const ForecastCard({
    super.key,
    required this.forecast,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    if (forecast == null) return const SizedBox.shrink();

    final color = type == 'credit' ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final formatter = NumberFormat.decimalPattern('vi_VN');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.auto_graph, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dự báo ${type == 'credit' ? 'thu nhập' : 'chi tiêu'} tháng tới', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Text('${formatter.format(forecast!.predictedAmount)} VND', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _forecastStat('Tỷ lệ thay đổi', '${forecast!.growthRate >= 0 ? '+' : ''}${forecast!.growthRate.toStringAsFixed(1)}%', forecast!.growthRate >= 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
              _forecastStat('Mức trung bình', '${formatter.format(forecast!.benchmarkAmount)} VND', const Color(0xFF1E293B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _forecastStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}
