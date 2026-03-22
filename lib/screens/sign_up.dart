import 'package:app/services/auth_service.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/appvalidator.dart';
import 'package:app/widgets/app_chrome.dart';
import 'package:app/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _userNameController = TextEditingController();

  final _emailController = TextEditingController();

  final _phoneController = TextEditingController();

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
        "name": _userNameController.text,
        "email": _emailController.text,
        "phone": _phoneController.text,
        "password": _passWordController.text,
        'remainingAmount': 0,
        'totalCredit': 0,
        'totalDebit': 0,
        'quickTemplates': [
          {
            'id': 'breakfast-30k',
            'label': 'Ăn sáng 30k',
            'title': 'Ăn sáng',
            'amount': 30000,
            'type': 'debit',
            'category': 'Ăn uống',
            'note': 'Mẫu chọn nhanh',
            'iconName': 'utensils',
          },
          {
            'id': 'salary-15m',
            'label': 'Lương 15 triệu',
            'title': 'Lương về',
            'amount': 15000000,
            'type': 'credit',
            'category': 'Lương',
            'note': 'Mẫu chọn nhanh',
            'iconName': 'moneyBillWave',
          },
          {
            'id': 'gas-50k',
            'label': 'Đổ xăng 50k',
            'title': 'Đổ xăng',
            'amount': 50000,
            'type': 'debit',
            'category': 'Di chuyển',
            'note': 'Mẫu chọn nhanh',
            'iconName': 'car',
          },
        ],
      };
      bool result = await authService.createUsser(data, context);

      if (!mounted) return;
      setState(() {
        isLoader = false;
      });

      if (result) {
        CustomAlertDialog.show(
          context: context,
          title: "Đăng Ký Thành Công",
          message: "Chào mừng bạn! Hãy bắt đầu quản lý tài chính ngay nhé.",
          type: AlertType.success,
          onConfirm: () {
            Navigator.pop(context);
          },
        );
      }
    }
  }

  var appvalidator = Appvalidator();

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "Tạo tài khoản mới",
      subtitle:
          "Bắt đầu với không gian tài chính mới, tối giản hơn nhưng vẫn nổi bật và dễ dùng.",
      headerIcon: Icons.person_add_alt_1_rounded,
      canPop: true,
      form: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _userNameController,
              style: const TextStyle(color: Colors.white),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: _buildInputDecoration(
                "Tên người dùng",
                Icons.person_outline_rounded,
              ),
              validator: appvalidator.validateUsername,
            ),
            const SizedBox(height: 16),
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
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: _buildInputDecoration(
                "Số điện thoại",
                Icons.call_outlined,
              ),
              validator: appvalidator.validatePhoneNumber,
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
            const SizedBox(height: 24),
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
                  : const Text("Tạo tài khoản"),
            ),
          ],
        ),
      ),
      footer: TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Text(
          "Đã có tài khoản? Đăng nhập",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData suffixIcon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      labelStyle: const TextStyle(color: Colors.white70),
      labelText: label,
      prefixIcon: Icon(suffixIcon, color: AppColors.gold),
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
