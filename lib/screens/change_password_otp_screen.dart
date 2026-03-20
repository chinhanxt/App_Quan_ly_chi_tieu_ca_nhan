import 'dart:math';
import 'package:app/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class ChangePasswordOTPScreen extends StatefulWidget {
  const ChangePasswordOTPScreen({super.key});

  @override
  State<ChangePasswordOTPScreen> createState() =>
      _ChangePasswordOTPScreenState();
}

class _ChangePasswordOTPScreenState extends State<ChangePasswordOTPScreen> {
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _generatedOTP;
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _isLoading = false;

  // Hàm tạo mã 6 số ngẫu nhiên
  String _generateRandomOTP() {
    var random = Random();
    int otp = 100000 + random.nextInt(900000);
    return otp.toString();
  }

  Future<void> _sendOTP() async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return;

    setState(() => _isLoading = true);

    _generatedOTP = _generateRandomOTP();

    // Cấu hình server SMTP Gmail bằng App Password bạn cung cấp
    final smtpServer = gmail("nhangamer500@gmail.com", "nqth jpnn vxgd wgzg");

    // Tạo nội dung email
    final message = Message()
      ..from = Address("nhangamer500@gmail.com", 'Quản Lý Thu Chi')
      ..recipients.add(userEmail)
      ..subject = 'Mã xác thực đổi mật khẩu: $_generatedOTP'
      ..html =
          """
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #ddd; padding: 20px; border-radius: 10px;">
          <h2 style="color: #FF5C04; text-align: center;">Xác Thực Đổi Mật Khẩu</h2>
          <p>Chào bạn,</p>
          <p>Mã xác thực của bạn để đổi mật khẩu ứng dụng <b>Quản Lý Thu Chi</b> là:</p>
          <div style="background: #f4f4f4; padding: 20px; text-align: center; border-radius: 5px;">
            <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #333;">$_generatedOTP</span>
          </div>
          <p style="margin-top: 20px;">Vui lòng nhập mã này vào ứng dụng để tiếp tục.</p>
          <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="font-size: 12px; color: #888;">Đây là email tự động, vui lòng không trả lời.</p>
        </div>
      """;

    try {
      await send(message, smtpServer);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mã OTP đã được gửi tới Email của bạn!"),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi gửi mail: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _verifyOTP() {
    if (_otpController.text == _generatedOTP) {
      setState(() => _otpVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Xác thực thành công!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mã OTP không đúng!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updatePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập mật khẩu mới")),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu xác nhận không khớp!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Cập nhật mật khẩu trực tiếp (không hỏi mật khẩu cũ)
      await user.updatePassword(_newPasswordController.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đổi mật khẩu thành công!"),
          backgroundColor: Colors.green,
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = "Lỗi: ${e.message}";
      // Xử lý lỗi bảo mật của Firebase
      if (e.code == 'requires-recent-login') {
        message =
            "Vì lý do bảo mật, vui lòng Đăng xuất và Đăng nhập lại trước khi đổi mật khẩu mới.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF252634),
      appBar: AppBar(
        title: const Text("Đổi Mật Khẩu OTP"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.security, size: 80, color: Color(0xFFFF5C04)),
            const SizedBox(height: 24),

            if (!_otpSent) ...[
              const Text(
                "Xác thực chủ sở hữu qua mã OTP 6 số gửi tới Email để đổi mật khẩu.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              _buildActionButton("GỬI MÃ OTP", _sendOTP),
            ] else if (!_otpVerified) ...[
              const Text(
                "Nhập mã 6 số đã nhận:",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _otpController,
                "Mã OTP",
                Icons.numbers,
                maxLength: 6,
              ),
              const SizedBox(height: 24),
              _buildActionButton("XÁC THỰC", _verifyOTP),
              TextButton(
                onPressed: _sendOTP,
                child: const Text(
                  "Gửi lại mã",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ] else ...[
              const Text(
                "Thiết lập mật khẩu mới:",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _newPasswordController,
                "Mật khẩu mới",
                Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _confirmPasswordController,
                "Xác nhận mật khẩu",
                Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 32),
              _buildActionButton("CẬP NHẬT MẬT KHẨU", _updatePassword),
              const SizedBox(height: 20),
              const Text(
                "Nếu gặp lỗi yêu cầu đăng nhập lại vì lý do bảo mật, hãy nhấn nút bên dưới:",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white30, fontSize: 12),
              ),
              TextButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  // AuthGate sẽ tự động đưa về LoginView khi thấy user null
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(
                  Icons.refresh,
                  color: Color(0xFFFF5C04),
                  size: 18,
                ),
                label: const Text(
                  "ĐĂNG NHẬP LẠI NGAY",
                  style: TextStyle(
                    color: Color(0xFFFF5C04),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: CircularProgressIndicator(color: Color(0xFFFF5C04)),
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
    bool isPassword = false,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: const Color(0xFFFF5C04)),
        fillColor: const Color(0xAA494A59),
        filled: true,
        counterStyle: const TextStyle(color: Colors.white30),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildActionButton(String text, dynamic onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5C04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
