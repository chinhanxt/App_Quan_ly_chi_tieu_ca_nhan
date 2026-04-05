import 'package:app/widgets/transaction_card.dart';
import 'package:app/widgets/app_chrome.dart';
import 'package:app/widgets/hero_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TransactionsCard extends StatelessWidget {
  const TransactionsCard({
    super.key,
    required this.filterMode,
    required this.selectedPeriod,
  });

  final HeroFilterMode filterMode;
  final DateTime selectedPeriod;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        children: [
          const AppSectionTitle(
            title: "Giao dịch gần đây",
            subtitle: "Cập nhật nhanh các biến động mới nhất trong ví của bạn.",
          ),
          const SizedBox(height: 10),
          RecentTransactionsList(
            filterMode: filterMode,
            selectedPeriod: selectedPeriod,
          ),
        ],
      ),
    );
  }
}

class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({
    super.key,
    required this.filterMode,
    required this.selectedPeriod,
  });

  final HeroFilterMode filterMode;
  final DateTime selectedPeriod;

  bool _matchesFilter(DateTime date) {
    switch (filterMode) {
      case HeroFilterMode.total:
        return true;
      case HeroFilterMode.year:
        return date.year == selectedPeriod.year;
      case HeroFilterMode.month:
        return date.year == selectedPeriod.year &&
            date.month == selectedPeriod.month;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text("Chưa có thông tin người dùng. Vui lòng đăng nhập lại."),
      );
    }
    final userId = user.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.hasError) {
              return const Text('Có lỗi xảy ra');
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('Chưa có giao dịch nào gần đây.'),
              );
            }
            final filteredDocs = snapshot.data!.docs
                .where((doc) {
                  final rawTimestamp = doc.data()['timestamp'];
                  final timestamp = rawTimestamp is num
                      ? rawTimestamp.toInt()
                      : int.tryParse(rawTimestamp?.toString() ?? '');
                  if (timestamp == null) return false;
                  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
                  return _matchesFilter(date);
                })
                .take(20)
                .toList(growable: false);

            if (filteredDocs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('Không có giao dịch nào trong bộ lọc hiện tại.'),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: filteredDocs.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final carData = filteredDocs[index].data();
                final docId = filteredDocs[index].id;

                return TransactionCard(data: carData, docId: docId);
              },
            );
          },
    );
  }
}
