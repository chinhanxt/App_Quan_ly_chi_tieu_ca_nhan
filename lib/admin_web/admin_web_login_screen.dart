import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/screens/sign_up.dart';
import 'package:app/utils/app_colors.dart';
import 'package:flutter/material.dart';

class AdminWebLoginScreen extends StatefulWidget {
  const AdminWebLoginScreen({
    super.key,
    required this.repository,
  });

  final AdminWebRepository repository;

  @override
  State<AdminWebLoginScreen> createState() => _AdminWebLoginScreenState();
}

class _AdminWebLoginScreenState extends State<AdminWebLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.repository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF101B1A),
              Color(0xFF18312E),
              Color(0xFFE7DCC7),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            Icons.shield_rounded,
                            size: 58,
                            color: Color(0xFFD6B872),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Cổng quản trị',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -2,
                            ),
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Khu vực quản trị chỉ dành cho tài khoản đã được cấp quyền quản trị.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFFE5E7EB),
                              height: 1.6,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Nếu chưa có tài khoản, hãy đăng ký trước. Sau đó quản trị viên cấp cao sẽ cấp quyền để bạn sử dụng trang này.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFFD6B872),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 440,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Đăng nhập quản trị',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Sử dụng tài khoản hiện có để truy cập khu vực quản trị.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 20),
                              if (_error != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Nhập email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: 'Mật khẩu',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscure = !_obscure;
                                      });
                                    },
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Nhập mật khẩu';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _submitting ? null : _submit,
                                  child: _submitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Đăng nhập'),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const SignUpView(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Chưa có tài khoản? Đăng ký trước',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Sau khi đăng ký, tài khoản cần được cấp quyền quản trị để đăng nhập vào đây.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
