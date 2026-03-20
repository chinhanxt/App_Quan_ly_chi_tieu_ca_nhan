import 'package:app/screens/home_screen.dart';
import 'package:app/screens/transaction_screen.dart';
import 'package:app/screens/report_screen.dart';
import 'package:app/screens/settings_screen.dart';
import 'package:app/screens/budget_screen.dart';
import 'package:app/widgets/navbar.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  var isLogOutLoading = false;
  int currentIndex = 0;
  var pageViewList = [
    HomeScreen(),
    TransactionScreen(),
    BudgetScreen(),
    ReportScreen(),
    SettingsScreen(),
  ];

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