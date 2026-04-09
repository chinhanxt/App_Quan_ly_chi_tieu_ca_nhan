import 'package:app/screens/home_screen.dart';
import 'package:app/screens/transaction_screen.dart';
import 'package:app/screens/report_screen.dart';
import 'package:app/screens/settings_screen.dart';
import 'package:app/screens/budget_screen.dart';
import 'package:app/utils/app_navigation.dart';
import 'package:app/widgets/navbar.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<Dashboard> createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  late int currentIndex;
  late final PageController _pageController;
  late final List<Widget> _pageViewList;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex.clamp(0, 4);
    _pageController = PageController(initialPage: currentIndex);
    dashboardTabRequest.addListener(_handleExternalTabRequest);
    _pageViewList = <Widget>[
      const HomeScreen(),
      TransactionScreen(onRequestPrimaryPage: _handleTransactionEdgeSwipe),
      const BudgetScreen(),
      const ReportScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  void didUpdateWidget(covariant Dashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = widget.initialIndex.clamp(0, _pageViewList.length - 1);
    if (nextIndex != currentIndex) {
      currentIndex = nextIndex;
      _pageController.jumpToPage(nextIndex);
    }
  }

  @override
  void dispose() {
    dashboardTabRequest.removeListener(_handleExternalTabRequest);
    _pageController.dispose();
    super.dispose();
  }

  void _handleExternalTabRequest() {
    final requestedIndex = dashboardTabRequest.value;
    if (requestedIndex == null) return;
    switchToIndex(requestedIndex);
    dashboardTabRequest.value = null;
  }

  void switchToIndex(int index, {bool animated = true}) {
    final nextIndex = index.clamp(0, _pageViewList.length - 1);
    if (nextIndex == currentIndex) return;
    if (animated) {
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    } else {
      _pageController.jumpToPage(nextIndex);
    }
    setState(() {
      currentIndex = nextIndex;
    });
  }

  void _handleTransactionEdgeSwipe(int direction) {
    switchToIndex(currentIndex + direction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Navbar(
        selectedIndex: currentIndex,
        onDestinationSelected: (int value) {
          switchToIndex(value);
        },
      ),
      body: PageView(
        controller: _pageController,
        physics: const PageScrollPhysics(),
        onPageChanged: (value) {
          if (value == currentIndex) return;
          setState(() {
            currentIndex = value;
          });
        },
        children: _pageViewList,
      ),
    );
  }
}
