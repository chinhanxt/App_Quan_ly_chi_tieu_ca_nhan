import 'dart:math';
import 'package:app/utils/app_colors.dart';
import 'package:app/widgets/app_chrome.dart';
import 'package:app/widgets/custom_alert_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class ForgotPasswordOTPScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordOTPScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordOTPScreen> createState() =>
      _ForgotPasswordOTPScreenState();
}

class _ForgotPasswordOTPScreenState extends State<ForgotPasswordOTPScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  String? _generatedOTP;
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _generateRandomOTP() {
    var random = Random();
    int otp = 100000 + random.nextInt(900000);
    return otp.toString();
  }

  Future<void> _sendOTP() async {
    if (_emailController.text.isEmpty) {
      CustomAlertDialog.show(
        context: context,
        title: "Thiếu Thông Tin",
        message: "Vui lòng nhập Email để nhận mã xác thực.",
        type: AlertType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);
    _generatedOTP = _generateRandomOTP();

    final smtpServer = gmail("nhangamer500@gmail.com", "nqth jpnn vxgd wgzg");
    final message = Message()
      ..from = Address("nhangamer500@gmail.com", 'Quản Lý Thu Chi')
      ..recipients.add(_emailController.text)
      ..subject = 'Xác thực khôi phục mật khẩu: $_generatedOTP'
      ..html =
          """
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #ddd; padding: 20px; border-radius: 10px;">
          <h2 style="color: #FF5C04; text-align: center;">Xác Minh Danh Tính</h2>
          <p>Chào bạn,</p>
          <p>Mã OTP của bạn để xác minh yêu cầu khôi phục mật khẩu là:</p>
          <div style="background: #f4f4f4; padding: 20px; text-align: center; border-radius: 5px;">
            <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #333;">$_generatedOTP</span>
          </div>
          <p>Nhập mã này vào ứng dụng để nhận Link đặt lại mật khẩu chính thức từ hệ thống.</p>
          <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="font-size: 12px; color: #888;">Đây là bước xác thực an toàn của Quản Lý Thu Chi.</p>
        </div>
      """;

    try {
      await send(message, smtpServer);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpSent = true;
      });
      CustomAlertDialog.show(
        context: context,
        title: "Gửi Mã Thành Công",
        message:
            "Mã xác thực (OTP) đã được gửi đến email của bạn. Vui lòng kiểm tra kỹ cả trong hộp thư rác (Spam).",
        type: AlertType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomAlertDialog.show(
        context: context,
        title: "Gửi Mã Thất Bại",
        message:
            "Không thể gửi email lúc này. Vui lòng kiểm tra lại kết nối mạng hoặc thử lại sau.",
        type: AlertType.error,
      );
    }
  }

  void _verifyOTP() {
    if (_otpController.text == _generatedOTP) {
      setState(() => _otpVerified = true);
      CustomAlertDialog.show(
        context: context,
        title: "Xác Thực Thành Công",
        message:
            "Mã xác thực chính xác. Bạn có thể tiến hành lấy lại mật khẩu ngay bây giờ.",
        type: AlertType.success,
      );
    } else {
      CustomAlertDialog.show(
        context: context,
        title: "Mã Xác Thực Sai",
        message:
            "Mã OTP bạn nhập không chính xác hoặc đã hết hạn. Vui lòng kiểm tra lại.",
        type: AlertType.error,
      );
    }
  }

  Future<void> _sendFinalResetLink() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text,
      );
      if (!mounted) return;
      CustomAlertDialog.show(
        context: context,
        title: "Gửi Link Thành Công",
        message:
            "Hệ thống đã gửi một liên kết đặt lại mật khẩu đến Email của bạn.\n\nHãy nhấn vào liên kết đó để cập nhật mật khẩu mới.",
        type: AlertType.success,
        confirmText: "Đã hiểu",
        onConfirm: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
      );
    } catch (e) {
      if (!mounted) return;
      CustomAlertDialog.show(
        context: context,
        title: "Lỗi Hệ Thống",
        message:
            "Đã xảy ra lỗi khi gửi link đặt lại mật khẩu. Vui lòng thử lại sau.",
        type: AlertType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "Khôi phục mật khẩu",
      subtitle:
          "Xác thực nhanh bằng OTP rồi nhận link đổi mật khẩu chính thức từ hệ thống.",
      headerIcon: Icons.shield_outlined,
      canPop: true,
      form: SingleChildScrollView(
        child: Column(
          children: [
            if (!_otpSent) ...[
              const Text(
                "Nhập email tài khoản cần khôi phục.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              _buildTextField(_emailController, "Email", Icons.email),
              const SizedBox(height: 32),
              _buildActionButton("GỬI MÃ XÁC THỰC", _sendOTP),
            ] else if (!_otpVerified) ...[
              Text(
                "Nhập mã 6 số đã gửi tới:\n${_emailController.text}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                _otpController,
                "Mã OTP 6 số",
                Icons.numbers,
                maxLength: 6,
              ),
              const SizedBox(height: 24),
              _buildActionButton("XÁC THỰC MÃ", _verifyOTP),
              TextButton(
                onPressed: _sendOTP,
                child: const Text(
                  "Gửi lại mã",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ] else ...[
              const Icon(Icons.verified_user, size: 60, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                "Xác thực thành công!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Để đảm bảo bảo mật theo tiêu chuẩn Google, vui lòng nhấn nút dưới đây để nhận Link đặt lại mật khẩu chính thức.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              _buildActionButton(
                "NHẬN LINK ĐẶT LẠI MẬT KHẨU",
                _sendFinalResetLink,
              ),
            ],

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: AppColors.gold),
        fillColor: Colors.white.withValues(alpha: 0.12),
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
