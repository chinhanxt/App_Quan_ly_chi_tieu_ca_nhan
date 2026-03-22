import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 1. Import thêm thư viện intl

class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    final Stream<DocumentSnapshot> usersStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots();
    return StreamBuilder<DocumentSnapshot>(
      stream: usersStream,
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Có lỗi xảy ra');
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text("Tài liệu không tồn tại");
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text("Đang tải...");
            }
            var data = snapshot.data!.data() as Map<String, dynamic>;

            return Cards(data: data);
          },
    );
  }
}

class Cards extends StatelessWidget {
  const Cards({super.key, required this.data});

  final Map data;

  @override
  Widget build(BuildContext context) {
    // 2. Tạo đối tượng format số theo chuẩn Việt Nam
    final formatter = NumberFormat.decimalPattern('vi');

    // 3. Xử lý format số tiền trước khi hiển thị (ép kiểu an toàn đề phòng dữ liệu bị sai)
    final formattedRemaining = formatter.format(
      num.tryParse(data['remainingAmount'].toString()) ?? 0,
    );
    final formattedCredit = formatter.format(
      num.tryParse(data['totalCredit'].toString()) ?? 0,
    );
    final formattedDebit = formatter.format(
      num.tryParse(data['totalDebit'].toString()) ?? 0,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    "Tổng quan hiện tại",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Tổng Số Dư",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                Text(
                  "$formattedRemaining VND",
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              color: Colors.white.withValues(alpha: 0.96),
            ),
            child: Row(
              children: [
                CardOne(
                  color: const Color(0xFF1D9A63),
                  heading: 'Thu Nhập',
                  amount: formattedCredit,
                ),
                const SizedBox(width: 10),
                CardOne(
                  color: const Color(0xFFC45A43),
                  heading: 'Chi Tiêu',
                  amount: formattedDebit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CardOne extends StatelessWidget {
  const CardOne({
    super.key,
    required this.color,
    required this.heading,
    required this.amount,
  });

  final Color color;
  final String heading;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "$amount VND",
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                heading == "Thu Nhập"
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
