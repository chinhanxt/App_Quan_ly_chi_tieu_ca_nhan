import 'package:app/services/db.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  var db = Db();

  createUsser(data, context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: data['email'],
        password: data['password'],
      );

      data['id'] = userCredential.user!.uid; 
      await db.addUser(data, context);
      
      // Không cần Navigator ở đây vì AuthGate sẽ tự động bắt sự kiện authStateChanges
    } catch (e) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Đăng Ký Thất Bại"),
            content: Text(e.toString()),
          );
        },
      );
    }
  }

  login(data, context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: data['email'],
        password: data['password'],
      );
      // Không cần Navigator ở đây vì AuthGate sẽ tự động bắt sự kiện authStateChanges
      // và thực hiện kiểm tra Role để điều hướng đúng trang.
    } catch (e) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Đăng Nhập Thất Bại"),
            content: Text(e.toString()),
          );
        },
      );
    }
  }

  // Gửi email khôi phục mật khẩu
  Future<void> resetPassword(String email, BuildContext context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email khôi phục đã được gửi! Vui lòng kiểm tra hộp thư của bạn."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Lỗi"),
          content: Text(e.toString()),
        ),
      );
    }
  }
}
