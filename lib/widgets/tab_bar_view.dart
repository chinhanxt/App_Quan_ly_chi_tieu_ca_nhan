import 'package:app/utils/app_colors.dart';
import 'package:app/widgets/transaction_list.dart';
import 'package:flutter/material.dart';

class TypeTabBar extends StatefulWidget {
  const TypeTabBar({
    super.key,
    required this.category,
    required this.monthYear,
    required this.controller,
    required this.onHorizontalDragEnd,
  });

  final String category;
  final String monthYear;
  final TabController controller;
  final GestureDragEndCallback onHorizontalDragEnd;

  @override
  State<TypeTabBar> createState() => _TypeTabBarState();
}

class _TypeTabBarState extends State<TypeTabBar> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: widget.controller,
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
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: widget.onHorizontalDragEnd,
            child: TabBarView(
              controller: widget.controller,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                TransactionList(
                  category: widget.category,
                  monthYear: widget.monthYear,
                  type: 'credit',
                ),
                TransactionList(
                  category: widget.category,
                  monthYear: widget.monthYear,
                  type: 'debit',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
