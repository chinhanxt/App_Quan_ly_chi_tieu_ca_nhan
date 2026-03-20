import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 1. Import thêm thư viện intl

class HeroCard extends StatelessWidget {
  HeroCard({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    final Stream<DocumentSnapshot> _usersStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots();
    return StreamBuilder<DocumentSnapshot>(
      stream: _usersStream,
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
      color: Colors.blue.shade900, //màu nền app phía sau
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tổng Số Dư",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                Text(
                  "$formattedRemaining VND", // 4. Sử dụng biến đã format
                  style: TextStyle(
                    fontSize: 44,
                    color: Colors.white,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: EdgeInsets.only(top: 30, bottom: 10, left: 10, right: 10),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              color: Colors.white,
            ),
            child: Row(
              children: [
                // 5. Truyền biến đã format vào CardOne
                CardOne(
                  color: Colors.green,
                  heading: 'Thu Nhập',
                  amount: formattedCredit,
                ),
                SizedBox(width: 10),
                CardOne(
                  color: Colors.red,
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
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // 1. Dùng Expanded bọc Column để lấy hết khoảng trống, đẩy Icon sát lề phải
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(heading, style: TextStyle(color: color, fontSize: 14)),

                    // 2. FittedBox tự động thu nhỏ chữ nếu số tiền quá dài (tránh vỡ giao diện)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "$amount VND",
                        style: TextStyle(
                          color: color,
                          fontSize: 20, // Kích thước chuẩn khi có đủ không gian
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // (Đã xóa Spacer() ở đây để chữ không bị ép nhỏ lại)

              // 3. Icon mũi tên chỉ hiện thị ở một góc nhỏ gọn
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  heading == "Credit"
                      ? Icons.arrow_upward_outlined
                      : Icons.arrow_downward_outlined,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// // Class CardOne giữ nguyên không cần thay đổi gì
// class CardOne extends StatelessWidget {
//   const CardOne({
//     super.key,
//     required this.color,
//     required this.heading,
//     required this.amount,
//   });

//   final Color color;
//   final String heading;
//   final String amount;

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Container(
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(10),
//           child: Row(
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(heading, style: TextStyle(color: color, fontSize: 14)),
//                   Text(
//                     "$amount VND",
//                     style: TextStyle(
//                       color: color,
//                       fontSize: 20,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//               Spacer(),
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Icon(
//                   heading == "Credit"
//                       ? Icons.arrow_upward_outlined
//                       : Icons.arrow_downward_outlined,
//                   color: color,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
