import 'package:app/widgets/transaction_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TransactionsCard extends StatelessWidget {
  TransactionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Text(
                "Giao Dịch Gần Đây",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        RecentTransactionsList(),
      ],
    );
  }
}

class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({super.key}); // Nên có const ở đây cho tối ưu

  @override
  Widget build(BuildContext context) {
    // 1. Lấy thông tin user hiện tại
    final user = FirebaseAuth.instance.currentUser;

    // 2. Kiểm tra an toàn: Nếu user bị null thì trả về một widget báo lỗi hoặc loading
    if (user == null) {
      return const Center(
        child: Text("Chưa có thông tin người dùng. Vui lòng đăng nhập lại."),
      );
    }

    // 3. Nếu user không null, lấy uid an toàn và chạy StreamBuilder
    final userId = user.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId) // Sử dụng userId đã được kiểm tra an toàn
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text('Có lỗi xảy ra');
        
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Đang tải...");
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Không có giao dịch '));
        }
        var data = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: data.length,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            var carData = data[index];
            var docId = data[index].id;

            return TransactionCard(data: carData, docId: docId);
          },
        );
      },
    );
  }
}
