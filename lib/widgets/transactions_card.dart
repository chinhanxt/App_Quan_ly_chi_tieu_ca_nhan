import 'package:app/widgets/transaction_card.dart';
import 'package:app/widgets/app_chrome.dart';
import 'package:app/widgets/hero_card.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TransactionsCard extends StatefulWidget {
  const TransactionsCard({
    super.key,
    required this.filterMode,
    required this.selectedPeriod,
  });

  final HeroFilterMode filterMode;
  final DateTime selectedPeriod;

  @override
  State<TransactionsCard> createState() => _TransactionsCardState();
}

class _TransactionsCardState extends State<TransactionsCard> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        children: [
          AppSectionTitle(
            title: "Giao dịch gần đây",
            subtitle: "Cập nhật nhanh các biến động mới nhất trong ví của bạn.",
            action: TextButton(
              onPressed: () {
                setState(() {
                  _showAll = !_showAll;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: Text(_showAll ? 'Thu gọn' : 'Xem tất cả'),
            ),
          ),
          const SizedBox(height: 10),
          RecentTransactionsList(
            filterMode: widget.filterMode,
            selectedPeriod: widget.selectedPeriod,
            showAll: _showAll,
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
    required this.showAll,
  });

  final HeroFilterMode filterMode;
  final DateTime selectedPeriod;
  final bool showAll;
  static const int _recentFetchLimit = 50;

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
          .limit(_recentFetchLimit)
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
                .toList(growable: false);

            if (filteredDocs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('Không có giao dịch nào trong bộ lọc hiện tại.'),
              );
            }

            final visibleDocs = showAll
                ? filteredDocs
                : filteredDocs.take(5).toList(growable: false);

            return ListView.builder(
              shrinkWrap: true,
              itemCount: visibleDocs.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final cardData = visibleDocs[index].data();
                final docId = visibleDocs[index].id;
                final rawTimestamp = cardData['timestamp'];
                final timestamp = rawTimestamp is num
                    ? rawTimestamp.toInt()
                    : int.tryParse(rawTimestamp?.toString() ?? '');

                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: timestamp == null
                      ? null
                      : () {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            timestamp,
                          );
                          dashboardTransactionTargetRequest
                              .value = DashboardTransactionTarget(
                            monthYear: "${date.month} ${date.year}",
                            category:
                                cardData['category']?.toString() ?? 'Tất cả',
                            type: cardData['type']?.toString() ?? 'debit',
                          );
                          dashboardTabRequest.value = 1;
                        },
                  child: TransactionCard(data: cardData, docId: docId),
                );
              },
            );
          },
    );
  }
}
