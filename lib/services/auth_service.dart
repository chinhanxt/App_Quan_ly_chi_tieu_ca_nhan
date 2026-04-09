import 'package:app/services/db.dart';
import 'package:app/utils/runtime_schedule.dart';
import 'package:app/widgets/custom_alert_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppAccessException implements Exception {
  const AppAccessException(this.message);

  final String message;
}

class AuthService {
  final Db db = Db();

  String _getErrorMessage(dynamic e) {
    if (e is AppAccessException) {
      return e.message;
    }

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Địa chỉ Email không hợp lệ. Vui lòng kiểm tra lại.';
        case 'user-disabled':
          return 'Tài khoản này đã bị khóa. Vui lòng liên hệ hỗ trợ.';
        case 'user-not-found':
          return 'Email này chưa được đăng ký tài khoản.';
        case 'wrong-password':
        case 'invalid-credential':
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
          return 'Không thể thực hiện thao tác lúc này. Vui lòng thử lại sau.';
      }
    }
    return 'Không thể thực hiện thao tác lúc này. Vui lòng thử lại sau.';
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
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
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

  Future<bool> login(Map<String, dynamic> data, BuildContext context) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: data['email'],
        password: data['password'],
      );
      await _ensureAccessAllowed(credential.user);
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
        message:
            "Email khôi phục đã được gửi! Vui lòng kiểm tra hộp thư của bạn.",
        type: AlertType.success,
      );
    } catch (e) {
      _showError(context, "Lỗi Gửi Email", e);
    }
  }

  Future<void> _ensureAccessAllowed(User? user) async {
    if (user == null) {
      throw const AppAccessException(
        'Không tìm thấy thông tin đăng nhập hợp lệ.',
      );
    }

    final firestore = FirebaseFirestore.instance;
    try {
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? const <String, dynamic>{};
      final status = userData['status']?.toString() ?? 'active';

      if (status == 'locked') {
        throw const AppAccessException(
          'Tài khoản này đã bị khóa. Vui lòng liên hệ hỗ trợ.',
        );
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }

    try {
      final appControlsDoc = await firestore
          .collection('system_configs')
          .doc('app_controls')
          .get();
      final appControls = appControlsDoc.data() ?? const <String, dynamic>{};
      final maintenanceMode = isMaintenanceActive(appControls);

      if (maintenanceMode) {
        throw const AppAccessException(
          'Hệ thống đang bảo trì. Vui lòng thử lại sau.',
        );
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }
  }
}
