import 'package:app/screens/sign_up.dart';
import 'package:app/screens/forgot_password_otp_screen.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/appvalidator.dart';
import 'package:app/widgets/app_chrome.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passWordController = TextEditingController();
  bool _obscurePassword = true;

  var authService = AuthService();
  var isLoader = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoader = true;
      });

      var data = {
        "email": _emailController.text,
        "password": _passWordController.text,
      };

      await authService.login(data, context);
      if (!mounted) return;

      setState(() {
        isLoader = false;
      });
    }
  }

  var appvalidator = Appvalidator();

  @override
  void dispose() {
    _emailController.dispose();
    _passWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "Đăng nhập tài khoản",
      subtitle: "Đăng nhập để quản lý thu chi và theo dõi tài khoản của bạn.",
      headerIcon: Icons.account_balance_wallet_rounded,
      form: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: _buildInputDecoration(
                "Email",
                Icons.mail_outline_rounded,
              ),
              validator: appvalidator.validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passWordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration:
                  _buildInputDecoration(
                    "Mật khẩu",
                    Icons.lock_outline_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ),
              validator: appvalidator.validatePassWord,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ForgotPasswordOTPScreen(
                        initialEmail: _emailController.text,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Quên mật khẩu?",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: isLoader ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.primaryDark,
              ),
              child: isLoader
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Text("Đăng nhập"),
            ),
          ],
        ),
      ),
      footer: Column(
        children: [
          const Divider(color: Colors.white24, height: 32),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const SignUpView(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                ),
              );
            },
            child: const Text(
              "Chưa có tài khoản? Tạo ngay",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData prefixIcon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      labelStyle: const TextStyle(color: Colors.white70),
      labelText: label,
      prefixIcon: Icon(prefixIcon, color: AppColors.gold),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
