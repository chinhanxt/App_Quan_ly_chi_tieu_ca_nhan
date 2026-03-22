import 'package:app/widgets/custom_alert_dialog.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/screens/forgot_password_otp_screen.dart';
import 'package:app/widgets/app_chrome.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountScreen extends StatefulWidget {
  final User? user;
  final VoidCallback onProfileUpdated;

  const AccountScreen({
    super.key,
    required this.user,
    required this.onProfileUpdated,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  Future<void> _loadUserData() async {
    if (widget.user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user!.uid)
          .get();

      if (mounted) {
        if (userDoc.exists) {
          final data = userDoc.data()!;
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? widget.user!.email ?? '';
          _phoneController.text = data['phone'] ?? '';
        } else {
          _emailController.text = widget.user!.email ?? '';
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSavingProfile = true;
    });

    try {
      final user = widget.user;
      if (user == null) {
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      widget.onProfileUpdated();
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: 'Thành Công',
          message: 'Thông tin cá nhân đã được cập nhật',
          type: AlertType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: 'Lỗi',
          message: 'Không thể cập nhật thông tin: ${e.toString()}',
          type: AlertType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final user = widget.user;
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : (user?.email ?? '');

    if (user == null || email.isEmpty) {
      CustomAlertDialog.show(
        context: context,
        title: 'Không thể đổi mật khẩu',
        message: 'Không tìm thấy thông tin tài khoản để xác thực.',
        type: AlertType.error,
      );
      return;
    }

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      CustomAlertDialog.show(
        context: context,
        title: 'Thiếu thông tin',
        message: 'Vui lòng nhập đầy đủ mật khẩu cũ, mật khẩu mới và xác nhận.',
        type: AlertType.warning,
      );
      return;
    }

    if (newPassword.length < 8) {
      CustomAlertDialog.show(
        context: context,
        title: 'Mật khẩu quá ngắn',
        message: 'Mật khẩu mới cần ít nhất 8 ký tự.',
        type: AlertType.warning,
      );
      return;
    }

    if (newPassword == currentPassword) {
      CustomAlertDialog.show(
        context: context,
        title: 'Mật khẩu chưa hợp lệ',
        message: 'Mật khẩu mới phải khác mật khẩu cũ.',
        type: AlertType.warning,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      CustomAlertDialog.show(
        context: context,
        title: 'Không khớp mật khẩu',
        message: 'Xác nhận mật khẩu mới chưa khớp.',
        type: AlertType.warning,
      );
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (!mounted) {
        return;
      }
      CustomAlertDialog.show(
        context: context,
        title: 'Thành Công',
        message: 'Mật khẩu đã được cập nhật thành công.',
        type: AlertType.success,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      CustomAlertDialog.show(
        context: context,
        title: 'Không thể đổi mật khẩu',
        message: e is FirebaseAuthException
            ? (e.code == 'wrong-password'
                  ? 'Mật khẩu cũ chưa chính xác.'
                  : e.code == 'weak-password'
                  ? 'Mật khẩu mới còn quá yếu.'
                  : e.message ?? 'Đã xảy ra lỗi khi đổi mật khẩu.')
            : 'Đã xảy ra lỗi khi đổi mật khẩu.',
        type: AlertType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  void _confirmForgotPasswordFlow() {
    final email = widget.user?.email ?? _emailController.text.trim();
    if (email.isEmpty) {
      CustomAlertDialog.show(
        context: context,
        title: 'Thiếu email',
        message: 'Không tìm thấy email tài khoản để gửi mã OTP.',
        type: AlertType.warning,
      );
      return;
    }

    CustomAlertDialog.show(
      context: context,
      title: 'Xác nhận quên mật khẩu',
      message:
          'Hệ thống sẽ đưa bạn tới màn xác thực OTP giống ở đăng nhập để tiếp tục khôi phục mật khẩu cho $email.',
      type: AlertType.warning,
      confirmText: 'Tiếp tục',
      cancelText: 'Hủy',
      onConfirm: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgotPasswordOTPScreen(initialEmail: email),
          ),
        );
      },
      onCancel: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thông Tin Cá Nhân')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 18),
              Text(
                'Đang tải thông tin cá nhân...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Thông Tin Cá Nhân')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const AppHeroHeader(
            title: "Hồ sơ cá nhân",
            subtitle:
                "Cập nhật thông tin tài khoản và đổi mật khẩu ngay trong một màn hình.",
          ),
          const SizedBox(height: 16),
          AppPanel(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.accentSoft,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.accentStrong,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ Tên',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập họ tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số Điện Thoại',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isSavingProfile ? null : _updateProfile,
                    child: _isSavingProfile
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Text('Lưu Thông Tin'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.accentStrong,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Đổi mật khẩu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.user?.email == null
                          ? null
                          : _confirmForgotPasswordFlow,
                      child: const Text('Quên mật khẩu?'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu cũ',
                    prefixIcon: Icon(Icons.key_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu mới',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isChangingPassword ? null : _changePassword,
                  child: _isChangingPassword
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Text('Đổi Mật Khẩu'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
