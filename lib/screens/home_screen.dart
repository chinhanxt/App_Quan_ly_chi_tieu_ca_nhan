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

    return AppScaffold(
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
