import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/budget_model.dart';

class Db {
  final CollectionReference<Map<String, dynamic>> users =
      FirebaseFirestore.instance.collection('users');

  // ==========================================
  // BUDGET SERVICES
  // ==========================================

  /// Thêm hoặc cập nhật một ngân sách
  Future<void> setBudget(Budget budget) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Lưu vào sub-collection 'budgets' của user hiện tại
      await users
          .doc(userId)
          .collection('budgets')
          .doc(budget.id)
          .set(budget.toMap());
    } catch (error) {
      debugPrint("Error setting budget: $error");
      rethrow;
    }
  }

  /// Lắng nghe danh sách ngân sách của một tháng cụ thể
  Stream<List<Budget>> getBudgets(String monthyear) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return users
        .doc(userId)
        .collection('budgets')
        .where('monthyear', isEqualTo: monthyear)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Budget.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Xóa một ngân sách
  Future<void> deleteBudget(String budgetId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await users.doc(userId).collection('budgets').doc(budgetId).delete();
    } catch (error) {
      debugPrint("Error deleting budget: $error");
      rethrow;
    }
  }

  // ==========================================
  // USER & TRANSACTION SERVICES
  // ==========================================

  Future<void> addUser(Map<String, dynamic> data) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      
      // Thêm các trường mặc định cho phân quyền và quản lý
      data['role'] = data['role'] ?? 'user';
      data['status'] = data['status'] ?? 'active';
      data['createdAt'] = FieldValue.serverTimestamp();
      
      await users.doc(userId).set(data);
      debugPrint("User Added");
    } catch (error) {
      rethrow;
    }
  }

  // Hàm xóa giao dịch
  Future<bool> deleteTransaction(
    String transactionId,
    Map<String, dynamic> transactionData,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final int amount = transactionData['amount'];
      final String type = transactionData['type'];
      int timestamp = DateTime.now().millisecondsSinceEpoch;

      // Lấy thông tin user hiện tại
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      int remainingAmount = userDoc['remainingAmount'];
      int totalCredit = userDoc['totalCredit'];
      int totalDebit = userDoc['totalDebit'];

      // Tính toán lại các giá trị sau khi xóa
      if (type == 'credit') {
        remainingAmount -= amount;
        totalCredit -= amount;
      } else {
        remainingAmount += amount;
        totalDebit -= amount;
      }

      // Cập nhật user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            "remainingAmount": remainingAmount,
            "totalCredit": totalCredit,
            "totalDebit": totalDebit,
            "updatedAt": timestamp,
          });

      // Xóa giao dịch
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transactionId)
          .delete();

      return true;
    } catch (e) {
      debugPrint("Delete error: $e");
      return false;
    }
  }

  // Hàm cập nhật giao dịch
  Future<bool> updateTransaction(
    String transactionId,
    Map<String, dynamic> oldTransactionData,
    Map<String, dynamic> newTransactionData,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      int currentTimestamp = DateTime.now().millisecondsSinceEpoch;

      // Lấy thông tin user hiện tại
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      int remainingAmount = userDoc['remainingAmount'];
      int totalCredit = userDoc['totalCredit'];
      int totalDebit = userDoc['totalDebit'];

      // Hoàn tác giao dịch cũ
      final int oldAmount = oldTransactionData['amount'];
      final String oldType = oldTransactionData['type'];

      if (oldType == 'credit') {
        remainingAmount -= oldAmount;
        totalCredit -= oldAmount;
      } else {
        remainingAmount += oldAmount;
        totalDebit += oldAmount;
      }

      // Áp dụng giao dịch mới
      final int newAmount = newTransactionData['amount'];
      final String newType = newTransactionData['type'];

      if (newType == 'credit') {
        remainingAmount += newAmount;
        totalCredit += newAmount;
      } else {
        remainingAmount -= newAmount;
        totalDebit -= newAmount;
      }

      // Cập nhật user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            "remainingAmount": remainingAmount,
            "totalCredit": totalCredit,
            "totalDebit": totalDebit,
            "updatedAt": currentTimestamp, // Thời điểm cập nhật hồ sơ
          });

      // Cập nhật giao dịch
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transactionId)
          .update({
            'title': newTransactionData['title'],
            'amount': newAmount,
            'type': newType,
            'category': newTransactionData['category'],
            // 👇 FIX: Lấy timestamp và monthyear từ form thay vì lấy giờ hiện tại
            'timestamp': newTransactionData['timestamp'],
            'monthyear': newTransactionData['monthyear'],
            'note': newTransactionData['note'],
            
            'totalCredit': totalCredit,
            'totalDebit': totalDebit,
            'remainingAmount': remainingAmount,
          });

      return true;
    } catch (e) {
      debugPrint("Update error: $e");
      return false;
    }
  }
}
