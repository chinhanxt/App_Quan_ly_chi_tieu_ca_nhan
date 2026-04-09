import 'package:app/widgets/category_list.dart';
import 'package:app/widgets/app_chrome.dart';
import 'package:app/widgets/tab_bar_view.dart';
import 'package:app/widgets/time_line_month.dart';
import 'package:app/screens/search_screen.dart'; // Import màn hình tìm kiếm
import 'package:app/utils/app_navigation.dart';
import 'package:flutter/material.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({
    super.key,
    this.onRequestPrimaryPage,
    this.initialTarget,
  });

  final ValueChanged<int>? onRequestPrimaryPage;
  final DashboardTransactionTarget? initialTarget;

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with SingleTickerProviderStateMixin {
  String monthYear = "";
  String category = "Tất cả"; // khởi tạo bằng tiếng Việt
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    final initialTarget = widget.initialTarget;
    monthYear = initialTarget?.monthYear.trim().isNotEmpty == true
        ? initialTarget!.monthYear
        : "${now.month} ${now.year}";
    category = initialTarget?.category.trim().isNotEmpty == true
        ? initialTarget!.category
        : "Tất cả";
    _tabController.index = initialTarget?.type == 'debit' ? 1 : 0;
    dashboardTransactionTargetRequest.addListener(_handleTargetRequest);
    _handleTargetRequest();
  }

  @override
  void dispose() {
    dashboardTransactionTargetRequest.removeListener(_handleTargetRequest);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTargetRequest() {
    final target = dashboardTransactionTargetRequest.value;
    if (target == null) return;

    setState(() {
      monthYear = target.monthYear;
      category = target.category;
    });
    _tabController.animateTo(target.type == 'debit' ? 1 : 0);
    dashboardTransactionTargetRequest.value = null;
  }

  void _handleHorizontalSwipeEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return;

    if (velocity < 0) {
      if (_tabController.index < _tabController.length - 1) {
        _tabController.animateTo(_tabController.index + 1);
        return;
      }
      widget.onRequestPrimaryPage?.call(1);
      return;
    }

    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
      return;
    }
    widget.onRequestPrimaryPage?.call(-1);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text("Giao dịch"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              pushAdaptiveScreen(context, const SearchScreen());
            },
          ),
        ],
      ),
      child: GestureDetector(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppHeroHeader(
                title: "Dòng tiền trong tháng",
                subtitle:
                    "Lọc theo tháng, danh mục và mở tìm kiếm nâng cao chỉ với một chạm.",
              ),
            ),
            const SizedBox(height: 10),
            TimeLineMonth(
              selectedMonth: monthYear,
              onChanges: (String? value) {
                if (value != null) {
                  setState(() {
                    monthYear = value;
                  });
                }
              },
            ),
            CategoryList(
              selectedCategory: category,
              onChanges: (String? value) {
                if (value != null) {
                  setState(() {
                    category = value;
                  });
                }
              },
            ),
            Expanded(
              child: TypeTabBar(
                category: category,
                monthYear: monthYear,
                controller: _tabController,
                onHorizontalDragEnd: _handleHorizontalSwipeEnd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
