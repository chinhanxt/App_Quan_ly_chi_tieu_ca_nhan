import 'package:app/screens/edit_transaction_screen.dart';
import 'package:app/services/db.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/icon_list.dart';
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
    // Safely get timestamp with a fallback
    int timestamp = 0;
    if (data['timestamp'] != null) {
      if (data['timestamp'] is int) {
        timestamp = data['timestamp'];
      } else {
        timestamp = int.tryParse(data['timestamp'].toString()) ?? 0;
      }
    }

    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String formatedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

    // THÊM DÒNG NÀY: Khởi tạo formatter chuẩn Việt Nam
    final formatter = NumberFormat.decimalPattern('vi');

    // Xử lý format cho amount và remainingAmount an toàn hơn
    final formattedAmount = formatter.format(
      num.tryParse(data['amount']?.toString() ?? '0') ?? 0,
    );
    final formattedRemaining = formatter.format(
      num.tryParse(data['remainingAmount']?.toString() ?? '0') ?? 0,
    );

    final accentColor = data['type'] == 'credit'
        ? const Color(0xFF1D9A63)
        : const Color(0xFFC45A43);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, accentColor.withValues(alpha: 0.04)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 12),
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 18,
            ),
          ],
        ),
        child: ListTile(
          minVerticalPadding: 10,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          leading: SizedBox(
            width: 58,
            height: 58,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: accentColor.withValues(alpha: 0.14),
              ),
              child: Center(
                child: FaIcon(
                  appIcons.getExpenseCategoryIcons('${data['category'] ?? ''}'),
                  color: accentColor,
                ),
              ),
            ),
          ),

          title: Row(
            children: [
              Expanded(
                child: Text(
                  "${data['title'] ?? 'Không có tiêu đề'}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${data['type'] == 'credit' ? '+' : '-'}$formattedAmount VND",
                    style: TextStyle(
                      color: accentColor,
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
          subtitle:
              data['note'] != null && data['note'].toString().trim().isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "${data['note']}",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : null,
          trailing: PopupMenuButton(
            color: Colors.white,
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('Sửa'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('Xóa'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _openEditScreen(context);
              } else if (value == 'delete') {
                _confirmDelete(context);
              }
            },
          ),
        ),
      ),
    );
  }

  void _openEditScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(
          transactionData: Map<String, dynamic>.from(data as Map),
          transactionId: docId,
        ),
      ),
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
                  debugPrint("Delete failed");
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
