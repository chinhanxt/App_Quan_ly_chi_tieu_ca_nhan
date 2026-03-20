import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class ForgotPasswordOTPScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordOTPScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordOTPScreen> createState() => _ForgotPasswordOTPScreenState();
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

  String _generateRandomOTP() {
    var random = Random();
    int otp = 100000 + random.nextInt(900000);
    return otp.toString();
  }

  Future<void> _sendOTP() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập Email")));
      return;
    }

    setState(() => _isLoading = true);
    _generatedOTP = _generateRandomOTP();

    final smtpServer = gmail("nhangamer500@gmail.com", "nqth jpnn vxgd wgzg");
    final message = Message()
      ..from = Address("nhangamer500@gmail.com", 'Quản Lý Thu Chi')
      ..recipients.add(_emailController.text)
      ..subject = 'Xác thực khôi phục mật khẩu: $_generatedOTP'
      ..html = """
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mã OTP đã được gửi!"), backgroundColor: Colors.blue));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
    }
  }

  void _verifyOTP() {
    if (_otpController.text == _generatedOTP) {
      setState(() => _otpVerified = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mã OTP không đúng!"), backgroundColor: Colors.red));
    }
  }

  Future<void> _sendFinalResetLink() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text);
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("✅ Đã Gửi Link Reset"),
          content: const Text("Hệ thống đã gửi một Email chứa Link đặt lại mật khẩu tới bạn.\n\nVui lòng mở Email đó và nhấn vào đường dẫn để chọn mật khẩu mới. Sau đó bạn có thể quay lại đăng nhập."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text("TÔI ĐÃ HIỂU"),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF252634),
      appBar: AppBar(title: const Text("Khôi Phục Mật Khẩu"), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.shield_outlined, size: 80, color: Color(0xFFFF5C04)),
            const SizedBox(height: 24),
            
            if (!_otpSent) ...[
              const Text("Nhập Email tài khoản cần khôi phục:", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 24),
              _buildTextField(_emailController, "Email", Icons.email),
              const SizedBox(height: 32),
              _buildActionButton("GỬI MÃ XÁC THỰC", _sendOTP),
            ] else if (!_otpVerified) ...[
              Text("Nhập mã 6 số đã gửi tới:\n${_emailController.text}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              _buildTextField(_otpController, "Mã OTP 6 số", Icons.numbers, maxLength: 6),
              const SizedBox(height: 24),
              _buildActionButton("XÁC THỰC MÃ", _verifyOTP),
              TextButton(onPressed: _sendOTP, child: const Text("Gửi lại mã", style: TextStyle(color: Colors.white54)))
            ] else ...[
              const Icon(Icons.verified_user, size: 60, color: Colors.green),
              const SizedBox(height: 16),
              const Text("Xác Thực Thành Công!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                "Để đảm bảo bảo mật theo tiêu chuẩn Google, vui lòng nhấn nút dưới đây để nhận Link đặt lại mật khẩu chính thức.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              _buildActionButton("NHẬN LINK ĐẶT LẠI MẬT KHẨU", _sendFinalResetLink),
            ],
            
            if (_isLoading) const Padding(padding: EdgeInsets.only(top: 20), child: CircularProgressIndicator(color: Color(0xFFFF5C04))),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int? maxLength}) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: const Color(0xFFFF5C04)),
        fillColor: const Color(0xAA494A59),
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5C04), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}