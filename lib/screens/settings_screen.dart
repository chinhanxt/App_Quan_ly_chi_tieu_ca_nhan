import 'package:app/widgets/custom_alert_dialog.dart';
import 'package:app/widgets/app_chrome.dart';
import 'package:app/widgets/account_dialog.dart';
import 'package:app/widgets/category_management_dialog.dart';
import 'package:app/providers/settings_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // Lấy provider
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const AppHeroHeader(
            title: "Không gian cá nhân",
            subtitle:
                "Quản lý tài khoản, giao diện và các tuỳ chọn quan trọng ở một nơi gọn gàng hơn.",
          ),
          const SizedBox(height: 16),
          AppPanel(
            child: Column(
              children: [
                // Quản lý tài khoản
                _buildSectionHeader('Quản Lý Tài Khoản'),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Thông Tin Cá Nhân'),
                  subtitle: Text(user?.email ?? 'Chưa có email'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _openAccountScreen(),
                ),

                // Quản lý danh mục
                _buildSectionHeader('Quản Lý Danh Mục'),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Danh Mục Tùy Chỉnh'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showCategoryManagement(),
                ),

                // Giao diện
                _buildSectionHeader('Giao Diện'),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('Chế Độ Tối'),
                  value: isDarkMode,
                  onChanged: (value) {
                    settingsProvider.toggleTheme(value);
                  },
                ),

                // Về ứng dụng
                _buildSectionHeader('Về Ứng Dụng'),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Thông Tin Ứng Dụng'),
                  subtitle: const Text('Phiên bản 1.0.0'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showAboutDialog(),
                ),

                ListTile(
                  leading: const Icon(Icons.contact_support),
                  title: const Text('Liên Hệ Hỗ Trợ'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showContactDialog(),
                ),

                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Chính Sách Bảo Mật'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showPrivacyDialog(),
                ),

                // Đăng xuất
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('Đăng Xuất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  void _openAccountScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountScreen(
          user: user,
          onProfileUpdated: () {
            setState(() {});
          },
        ),
      ),
    );
  }

  void _showCategoryManagement() {
    showDialog(
      context: context,
      builder: (context) => CategoryManagementDialog(
        onCategoryChanged: () {
          // Refresh if needed
        },
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Expense Tracker',
      applicationVersion: '1.0.0',
      applicationIcon: const FlutterLogo(),
      children: [const Text('Ứng dụng theo dõi chi tiêu cá nhân')],
    );
  }

  void _showContactDialog() {
    CustomAlertDialog.show(
      context: context,
      title: 'Liên Hệ Hỗ Trợ',
      message: 'Email: support@expensetracker.com\nPhone: 0123-456-789',
      type: AlertType.info,
    );
  }

  void _showPrivacyDialog() {
    CustomAlertDialog.show(
      context: context,
      title: 'Chính Sách Bảo Mật',
      message: 'Chúng tôi cam kết bảo vệ thông tin cá nhân của bạn...',
      type: AlertType.info,
    );
  }

  void _showLogoutDialog() {
    CustomAlertDialog.show(
      context: context,
      title: 'Đăng Xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất?',
      type: AlertType.warning,
      onConfirm: () async {
        await FirebaseAuth.instance.signOut();
        // Không cần Navigator ở đây vì AuthGate sẽ tự động bắt sự kiện signOut
        // và chuyển về màn hình đăng nhập.
      },
    );
  }
}
