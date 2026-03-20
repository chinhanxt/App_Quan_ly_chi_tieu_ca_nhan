/// Report Widgets - Các widget UI cho báo cáo
import 'package:app/screens/category_analysis_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app/models/report_models.dart';

/// Thẻ tóm tắt (Summary Card)
class SummaryCard extends StatelessWidget {
  final String title;
  final int amount;
  final String icon;
  final Color backgroundColor;
  final Color textColor;

  const SummaryCard({
    Key? key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _formatCurrencyVND(amount),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrencyVND(int amount) {
    final formatter = NumberFormat.decimalPattern('vi_VN');
    return '${formatter.format(amount)} VND';
  }
}

/// Thẻ so sánh tháng
class ComparisonCard extends StatelessWidget {
  final String title;
  final MonthComparison comparison;

  const ComparisonCard({
    Key? key,
    required this.title,
    required this.comparison,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isIncome = title.toLowerCase().contains('thu');
    final current = comparison.currentAmount;
    final previous = comparison.previousAmount;

    Color trendColor;
    String trendIcon;
    String trendLabelText;

    final colorGood = const Color(0xFF27AE60);
    final colorBad = const Color(0xFFE74C3C);
    final colorNeutral = Colors.grey[600]!;
    final colorWarning = const Color(0xFFF39C12);

    if (previous == 0 && current == 0) {
      trendLabelText = 'Không phát sinh';
      trendIcon = '➖';
      trendColor = colorNeutral;
    } 
    else if (previous == 0 && current > 0) {
      trendLabelText = 'Mới phát sinh';
      trendIcon = isIncome ? '✨' : '⚠️';
      trendColor = isIncome ? colorGood : colorWarning;
    } 
    else if (previous > 0 && current == 0) {
      trendLabelText = 'Cắt giảm hoàn toàn';
      trendIcon = isIncome ? '❌' : '🎉';
      trendColor = isIncome ? colorBad : colorGood;
    } 
    else if (current == previous) {
      trendLabelText = 'Cân bằng hoàn hảo';
      trendIcon = '⚖️';
      trendColor = Colors.blue;
    } 
    else {
      double percent = ((current - previous) / previous).abs() * 100;
      if (current > previous) {
        trendColor = isIncome ? colorGood : colorBad;
        if (percent <= 20) {
          trendLabelText = 'Tăng nhẹ';
          trendIcon = '📈';
        } else if (percent <= 50) {
          trendLabelText = 'Tăng đáng kể';
          trendIcon = '⬆️';
        } else {
          trendLabelText = 'Tăng mạnh';
          trendIcon = isIncome ? '🚀' : '🚨';
        }
      } 
      else {
        trendColor = isIncome ? colorBad : colorGood;
        if (percent <= 20) {
          trendLabelText = 'Giảm nhẹ';
          trendIcon = '📉';
        } else {
          trendLabelText = 'Giảm sâu';
          trendIcon = isIncome ? '⚠️' : '🎊';
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tháng này', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text(_formatCurrencyVND(current), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: trendColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('$trendIcon $trendLabelText', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: trendColor)),
                    ),
                    const SizedBox(height: 6),
                    Text('Trước: ${_formatCurrencyVND(previous)}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrencyVND(int amount) {
    final formatter = NumberFormat.decimalPattern('vi_VN');
    return '${formatter.format(amount)} VND';
  }
}

/// Danh sách giao dịch chi tiết
class TransactionListWidget extends StatefulWidget {
  final List<TransactionDetail> transactions;
  const TransactionListWidget({Key? key, required this.transactions}) : super(key: key);

  @override
  State<TransactionListWidget> createState() => _TransactionListWidgetState();
}

class _CategoryAggregate {
  final String category;
  final int totalAmount;
  final int count;
  _CategoryAggregate({required this.category, required this.totalAmount, required this.count});
}

class _TransactionListWidgetState extends State<TransactionListWidget> {
  late List<_CategoryAggregate> _aggregated;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _updateAggregates();
  }

  void _updateAggregates() {
    final filtered = widget.transactions.where((t) => _filterType == 'all' || t.type == _filterType).toList();
    final Map<String, _CategoryAggregate> map = {};
    for (var t in filtered) {
      if (map.containsKey(t.category)) {
        var existing = map[t.category]!;
        map[t.category] = _CategoryAggregate(category: existing.category, totalAmount: existing.totalAmount + t.amount, count: existing.count + 1);
      } else {
        map[t.category] = _CategoryAggregate(category: t.category, totalAmount: t.amount, count: 1);
      }
    }
    _aggregated = map.values.toList();
    _aggregated.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('Tất cả', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Thu nhập', 'credit'),
              const SizedBox(width: 8),
              _buildFilterChip('Chi tiêu', 'debit'),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _aggregated.length,
          itemBuilder: (context, index) {
            final agg = _aggregated[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
              child: ListTile(
                title: Text(agg.category, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('${agg.count} giao dịch', style: const TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_formatCurrencyVND(agg.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    IconButton(
                      icon: const Icon(Icons.analytics_outlined, color: Colors.blue, size: 18),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryAnalysisScreen(categoryName: agg.category))),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _filterType == type;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12)),
      selected: isSelected,
      selectedColor: const Color(0xFF3498DB),
      onSelected: (_) => setState(() { _filterType = type; _updateAggregates(); }),
    );
  }

  String _formatCurrencyVND(int amount) {
    final formatter = NumberFormat.decimalPattern('vi_VN');
    return '${formatter.format(amount)} VND';
  }
}

/// Giao dịch cực trị
class ExtremTransactionsWidget extends StatelessWidget {
  final ExtremTransaction? largest;
  final ExtremTransaction? smallest;
  final String type;

  const ExtremTransactionsWidget({Key? key, required this.largest, required this.smallest, required this.type}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (largest == null && smallest == null) return const SizedBox.shrink();
    final isCredit = type == 'credit';
    final borderColor = isCredit ? const Color(0xFF27AE60) : const Color(0xFFF39C12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(isCredit ? '💰 Thu nhập tiêu biểu' : '💸 Chi tiêu tiêu biểu', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        if (largest != null) _buildExtremCard(largest!, 'Lớn nhất', isCredit ? const Color(0xFFD4EDDA) : const Color(0xFFFFF3CD), borderColor),
        if (smallest != null) _buildExtremCard(smallest!, 'Nhỏ nhất', isCredit ? const Color(0xFFD4EDDA) : const Color(0xFFFFF3CD), borderColor.withOpacity(0.6)),
      ],
    );
  }

  Widget _buildExtremCard(ExtremTransaction item, String label, Color bg, Color border) {
    final formatter = NumberFormat.decimalPattern('vi_VN');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
            Text(item.transaction.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
          Text('${formatter.format(item.transaction.amount)} VND', style: TextStyle(fontWeight: FontWeight.bold, color: border, fontSize: 14)),
        ],
      ),
    );
  }
}
