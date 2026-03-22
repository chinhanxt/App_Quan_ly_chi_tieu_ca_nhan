import 'package:app/utils/app_colors.dart';
import 'package:app/widgets/transaction_list.dart';
import 'package:flutter/material.dart';

class TypeTabBar extends StatelessWidget {
  const TypeTabBar({
    super.key,
    required this.category,
    required this.monthYear,
  });

  final String category;
  final String monthYear;
  // final String type;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            tabs: const [
              Tab(text: "Thu Nhập"),
              Tab(text: "Chi Tiêu"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                TransactionList(
                  category: category,
                  monthYear: monthYear,
                  type: 'credit',
                ),
                TransactionList(
                  category: category,
                  monthYear: monthYear,
                  type: 'debit',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
