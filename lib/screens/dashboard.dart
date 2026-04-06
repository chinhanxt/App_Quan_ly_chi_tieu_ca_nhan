import 'package:app/screens/home_screen.dart';
import 'package:app/screens/transaction_screen.dart';
import 'package:app/screens/report_screen.dart';
import 'package:app/screens/settings_screen.dart';
import 'package:app/screens/budget_screen.dart';
import 'package:app/widgets/navbar.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  var isLogOutLoading = false;
  late int currentIndex;
  var pageViewList = [
    HomeScreen(),
    TransactionScreen(),
    BudgetScreen(),
    ReportScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex.clamp(0, pageViewList.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar:
      Navbar(
      selectedIndex: currentIndex,
      onDestinationSelected: (int vaule){
        setState(() {
          currentIndex = vaule;
        });
      }),

      body: pageViewList[currentIndex],
    );
  }
}
