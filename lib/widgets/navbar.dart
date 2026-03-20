import 'package:flutter/material.dart';
import 'package:app/utils/app_colors.dart';

class Navbar extends StatelessWidget {
  const Navbar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      indicatorColor: AppColors.primary,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      height: 50,

      destinations: const <Widget>[
        NavigationDestination(
          icon: Icon(Icons.home),
          selectedIcon: Icon(Icons.home, color: Colors.white),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore),
          selectedIcon: Icon(Icons.explore, color: Colors.white),
          label: 'Transaction',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet, color: Colors.white),
          label: 'Budget',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart),
          selectedIcon: Icon(Icons.bar_chart, color: Colors.white),
          label: 'Report',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          selectedIcon: Icon(Icons.settings, color: Colors.white),
          label: 'Settings',
        ),
      ],
    );
  }
}
