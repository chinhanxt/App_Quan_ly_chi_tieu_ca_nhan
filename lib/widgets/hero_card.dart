import 'package:app/services/transaction_summary_helper.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/mobile_adaptive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum HeroFilterMode { total, year, month }

class HeroCard extends StatefulWidget {
  const HeroCard({
    super.key,
    required this.userId,
    required this.filterMode,
    required this.selectedPeriod,
    required this.onFilterChanged,
    required this.onPickPeriod,
  });

  final String userId;
  final HeroFilterMode filterMode;
  final DateTime selectedPeriod;
  final ValueChanged<HeroFilterMode> onFilterChanged;
  final Future<void> Function() onPickPeriod;

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard> {
  bool _matchesFilter(DateTime date) {
    switch (widget.filterMode) {
      case HeroFilterMode.total:
        return true;
      case HeroFilterMode.year:
        return date.year == widget.selectedPeriod.year;
      case HeroFilterMode.month:
        return date.year == widget.selectedPeriod.year &&
            date.month == widget.selectedPeriod.month;
    }
  }

  TransactionSummary _buildSummary(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var totalCredit = 0;
    var totalDebit = 0;

    for (final doc in docs) {
      final data = doc.data();
      final rawTimestamp = data['timestamp'];
      final timestamp = rawTimestamp is num
          ? rawTimestamp.toInt()
          : int.tryParse(rawTimestamp?.toString() ?? '');
      if (timestamp == null) continue;

      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (!_matchesFilter(date)) continue;

      final amount = TransactionSummaryHelper.normalizeAmount(data['amount']);
      final type = data['type']?.toString() ?? 'debit';
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

  String _periodTitle() {
    switch (widget.filterMode) {
      case HeroFilterMode.total:
        return 'Tổng quan tất cả';
      case HeroFilterMode.year:
        return 'Năm ${widget.selectedPeriod.year}';
      case HeroFilterMode.month:
        return 'Tháng ${widget.selectedPeriod.month}/${widget.selectedPeriod.year}';
    }
  }

  String _periodButtonLabel() {
    switch (widget.filterMode) {
      case HeroFilterMode.total:
        return 'Tất cả';
      case HeroFilterMode.year:
        return 'Năm ${widget.selectedPeriod.year}';
      case HeroFilterMode.month:
        return DateFormat('MM/yyyy').format(widget.selectedPeriod);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('transactions')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: transactionsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Có lỗi xảy ra');
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Text('Đang tải...');
        }

        final docs = snapshot.data?.docs ?? const [];
        final summary = _buildSummary(docs);

        return _HeroCardBody(
          summary: summary,
          filterMode: widget.filterMode,
          title: _periodTitle(),
          periodButtonLabel: _periodButtonLabel(),
          onFilterChanged: widget.onFilterChanged,
          onPickPeriod: widget.onPickPeriod,
        );
      },
    );
  }
}

class _HeroCardBody extends StatelessWidget {
  const _HeroCardBody({
    required this.summary,
    required this.filterMode,
    required this.title,
    required this.periodButtonLabel,
    required this.onFilterChanged,
    required this.onPickPeriod,
  });

  final TransactionSummary summary;
  final HeroFilterMode filterMode;
  final String title;
  final String periodButtonLabel;
  final ValueChanged<HeroFilterMode> onFilterChanged;
  final Future<void> Function() onPickPeriod;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern('vi');
    final compact = MobileAdaptive.useCompactLayout(context);

    final formattedRemaining = formatter.format(summary.remainingAmount);
    final formattedCredit = formatter.format(summary.totalCredit);
    final formattedDebit = formatter.format(summary.totalDebit);

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              compact ? 18 : 20,
              20,
              compact ? 14 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _FilterChip(
                      label: 'Tổng',
                      selected: filterMode == HeroFilterMode.total,
                      onTap: () => onFilterChanged(HeroFilterMode.total),
                    ),
                    _FilterChip(
                      label: 'Năm',
                      selected: filterMode == HeroFilterMode.year,
                      onTap: () => onFilterChanged(HeroFilterMode.year),
                    ),
                    _FilterChip(
                      label: 'Tháng',
                      selected: filterMode == HeroFilterMode.month,
                      onTap: () => onFilterChanged(HeroFilterMode.month),
                    ),
                    if (filterMode != HeroFilterMode.total)
                      InkWell(
                        onTap: onPickPeriod,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                periodButtonLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.calendar_month_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: compact ? 14 : 18),
                const Text(
                  'Tổng Số Dư',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$formattedRemaining VND',
                    style: TextStyle(
                      fontSize: compact ? 34 : 40,
                      color: Colors.white,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              color: Colors.white.withValues(alpha: 0.96),
            ),
            child: compact
                ? Column(
                    children: [
                      _AmountCard(
                        color: const Color(0xFF1D9A63),
                        heading: 'Thu Nhập',
                        amount: formattedCredit,
                      ),
                      const SizedBox(height: 10),
                      _AmountCard(
                        color: const Color(0xFFC45A43),
                        heading: 'Chi Tiêu',
                        amount: formattedDebit,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _AmountCard(
                        color: const Color(0xFF1D9A63),
                        heading: 'Thu Nhập',
                        amount: formattedCredit,
                      ),
                      const SizedBox(width: 10),
                      _AmountCard(
                        color: const Color(0xFFC45A43),
                        heading: 'Chi Tiêu',
                        amount: formattedDebit,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.color,
    required this.heading,
    required this.amount,
  });

  final Color color;
  final String heading;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final compact = MobileAdaptive.useCompactLayout(context);
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading,
                    style: TextStyle(
                      color: color,
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$amount VND',
                      style: TextStyle(
                        color: color,
                        fontSize: compact ? 17 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: compact ? 38 : 42,
              height: compact ? 38 : 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                heading == 'Thu Nhập'
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: color,
                size: compact ? 18 : 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
