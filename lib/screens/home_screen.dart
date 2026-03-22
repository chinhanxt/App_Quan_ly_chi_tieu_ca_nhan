import 'package:app/screens/add_transaction_screen.dart';
import 'package:app/screens/ai_input_screen.dart';
import 'package:app/utils/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'ai_button',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AIInputScreen()),
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
                constraints: const BoxConstraints(
                  minWidth: 56.0,
                  minHeight: 56.0,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
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
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text("Trang chủ"),
        automaticallyImplyLeading: false,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
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
            HeroCard(userId: userId),
            const SizedBox(height: 18),
            TopSavingGoalsWidget(userId: userId),
            const SizedBox(height: 18),
            TransactionsCard(),
          ],
        ),
      ),
    );
  }
}
