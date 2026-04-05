import 'package:app/screens/add_transaction_screen.dart';
import 'package:app/screens/ai_input_screen.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/mobile_adaptive.dart';
import 'package:app/widgets/app_chrome.dart';
import 'package:app/widgets/hero_card.dart';
import 'package:app/widgets/system_broadcast_widget.dart';
import 'package:app/widgets/top_saving_goals_widget.dart';
import 'package:app/widgets/transactions_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// igore_for_file: prefer_const_constructors
// igore_for_file: prefer_const_literals_to_create_immutables

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  HeroFilterMode _heroFilterMode = HeroFilterMode.total;
  DateTime _selectedPeriod = DateTime.now();

  Future<void> _pickHeroPeriod() async {
    if (_heroFilterMode == HeroFilterMode.total) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPeriod,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('vi', 'VN'),
    );

    if (picked == null || !mounted) return;
    setState(() {
      _selectedPeriod = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MobileAdaptive.useCompactLayout(context);
    final fabBottomPadding = MediaQuery.of(context).padding.bottom + 84;

    return AppScaffold(
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: fabBottomPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: compact ? 48 : 56,
              height: compact ? 48 : 56,
              child: FloatingActionButton(
                mini: compact,
                heroTag: 'ai_button',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIInputScreen(),
                    ),
                  );
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Ink(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.gold, AppColors.accentStrong],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: compact ? 48.0 : 56.0,
                      minHeight: compact ? 48.0 : 56.0,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: compact ? 20 : 24,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 12 : 16),
            SizedBox(
              width: compact ? 48 : 56,
              height: compact ? 48 : 56,
              child: FloatingActionButton(
                mini: compact,
                heroTag: 'add_button',
                backgroundColor: AppColors.primary,
                onPressed: (() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTransactionScreen(),
                    ),
                  );
                }),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: compact ? 22 : 28,
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Trang chủ"),
        automaticallyImplyLeading: false,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          compact ? 6 : 8,
          16,
          compact ? 150 : 136,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeroHeader(
              title: "Tài chính của bạn",
              subtitle:
                  "Tổng quan đẹp mắt, rõ ràng và vẫn giữ nguyên mọi chức năng đang dùng.",
            ),
            const SizedBox(height: 18),
            const SystemBroadcastWidget(),
            const SizedBox(height: 18),
            HeroCard(
              userId: userId,
              filterMode: _heroFilterMode,
              selectedPeriod: _selectedPeriod,
              onFilterChanged: (mode) {
                setState(() {
                  _heroFilterMode = mode;
                });
              },
              onPickPeriod: _pickHeroPeriod,
            ),
            const SizedBox(height: 18),
            TopSavingGoalsWidget(userId: userId),
            const SizedBox(height: 18),
            TransactionsCard(
              filterMode: _heroFilterMode,
              selectedPeriod: _selectedPeriod,
            ),
          ],
        ),
      ),
    );
  }
}
