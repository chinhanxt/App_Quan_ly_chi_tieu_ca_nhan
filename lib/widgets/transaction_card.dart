import 'package:app/services/db.dart';
import 'package:app/utils/icon_list.dart';
import 'package:app/widgets/edit_transactions_form.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class TransactionCard extends StatelessWidget {
  TransactionCard({super.key, required this.data, required this.docId});
  final dynamic data;
  final String docId;

  final appIcons = AppIcons();
  final db = Db();

  @override
  Widget build(BuildContext context) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
    String formatedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
    // String formatedDate = DateFormat('d MMM hh:mma').format(date);

    // THÊM DÒNG NÀY: Khởi tạo formatter chuẩn Việt Nam
    final formatter = NumberFormat.decimalPattern('vi');

    // THÊM 2 DÒNG NÀY: Xử lý format cho amount và remainingAmount
    final formattedAmount = formatter.format(
      num.tryParse(data['amount'].toString()) ?? 0,
    );
    final formattedRemaining = formatter.format(
      num.tryParse(data['remainingAmount'].toString()) ?? 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),

          boxShadow: [
            BoxShadow(
              offset: Offset(0, 10),
              color: Colors.grey.withOpacity(0.09),
              blurRadius: 10.0,
              spreadRadius: 4.0,
            ),
          ],
        ),
        child: ListTile(
          minVerticalPadding: 10,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          leading: Container(
            width: 70,
            height: 100,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: data['type'] == 'credit'
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
              ),
              child: Center(
                child: FaIcon(
                  appIcons.getExpenseCategoryIcons('${data['category']}'),
                  color: data['type'] == 'credit' ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),

          title: Row(
            children: [
              Expanded(
                child: Text(
                  "${data['title']}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${data['type'] == 'credit' ? '+' : '-'}$formattedAmount VND",
                    style: TextStyle(
                      color: data['type'] == 'credit'
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$formattedRemaining VND",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  Text(
                    formatedDate,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          subtitle: data['note'] != null && data['note'].toString().isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "${data['note']}",
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : null,
          trailing: PopupMenuButton(
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Sửa'),
                  ],
                ),
                value: 'edit',
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa'),
                  ],
                ),
                value: 'delete',
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _showEditDialog(context);
              } else if (value == 'delete') {
                _confirmDelete(context);
              }
            },
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Sửa Giao Dịch"),
          content: EditTransactionsForm(
            transactionData: data,
            transactionId: docId,
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Xác Nhận Xóa"),
          content: Text("Bạn có chắc muốn xóa giao dịch này?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Hủy"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Đóng dialog xác nhận

                bool success = await db.deleteTransaction(docId, data);

                if (success) {
                  // Không cần làm gì, StreamBuilder sẽ tự cập nhật
                } else {
                  // Có thể hiển thị thông báo lỗi nếu cần
                  print("Delete failed");
                }
              },
              child: Text("Xóa", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
