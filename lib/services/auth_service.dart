import 'package:app/services/db.dart';
import 'package:app/widgets/custom_alert_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final Db db = Db();

  String _getErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Địa chỉ Email không hợp lệ. Vui lòng kiểm tra lại.';
        case 'user-disabled':
          return 'Tài khoản này đã bị khóa. Vui lòng liên hệ hỗ trợ.';
        case 'user-not-found':
          return 'Email này chưa được đăng ký tài khoản.';
        case 'wrong-password':
          return 'Mật khẩu không chính xác. Vui lòng thử lại.';
        case 'email-already-in-use':
          return 'Email này đã được sử dụng cho một tài khoản khác.';
        case 'operation-not-allowed':
          return 'Phương thức đăng nhập này hiện chưa được hỗ trợ.';
        case 'weak-password':
          return 'Mật khẩu quá yếu. Vui lòng nhập mật khẩu mạnh hơn.';
        case 'network-request-failed':
          return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại internet của bạn.';
        case 'too-many-requests':
          return 'Bạn đã thử quá nhiều lần. Vui lòng quay lại sau ít phút.';
        case 'channel-error':
          return 'Vui lòng điền đầy đủ thông tin Email và Mật khẩu.';
        default:
          return 'Đã xảy ra lỗi hệ thống: ${e.message}';
      }
    }
    return 'Lỗi không xác định: ${e.toString()}';
  }

  void _showError(BuildContext context, String title, dynamic e) {
    if (!context.mounted) return;
    CustomAlertDialog.show(
      context: context,
      title: title,
      message: _getErrorMessage(e),
      type: AlertType.error,
    );
  }

  Future<bool> createUsser(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: data['email'],
        password: data['password'],
      );

      data['id'] = userCredential.user!.uid; 
      await db.addUser(data);
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      _showError(context, "Đăng Ký Thất Bại", e);
      return false;
    }
  }

  Future<bool> login(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: data['email'],
        password: data['password'],
      );
      if (!context.mounted) return false;
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      _showError(context, "Đăng Nhập Thất Bại", e);
      return false;
    }
  }

  // Gửi email khôi phục mật khẩu
  Future<void> resetPassword(String email, BuildContext context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!context.mounted) return;
      CustomAlertDialog.show(
        context: context,
        title: 'Thành Công',
        message: "Email khôi phục đã được gửi! Vui lòng kiểm tra hộp thư của bạn.",
        type: AlertType.success,
      );
    } catch (e) {
      _showError(context, "Lỗi Gửi Email", e);
    }
  }
}
