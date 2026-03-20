import 'package:app/screens/ai_input_screen.dart';
import 'package:app/widgets/add_transactions_form.dart';
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

  _dialoBuilder(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(content: AddTransactionsForm());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Nút AI nổi (Floating AI Button)
          FloatingActionButton(
            heroTag: 'ai_button',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AIInputScreen()),
              );
            },
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.purple[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Container(
                constraints: const BoxConstraints(minWidth: 56.0, minHeight: 56.0),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Nút thêm truyền thống
          FloatingActionButton(
            heroTag: 'add_button',
            backgroundColor: Colors.blue.shade900,
            onPressed: (() {
              _dialoBuilder(context);
            }),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Trang Chủ", style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false, // tắt mũi tên
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SystemBroadcastWidget(),
            HeroCard(userId: userId),
            TopSavingGoalsWidget(userId: userId),
            TransactionsCard(),
          ],
        ),
      ),
    );
  }
}
