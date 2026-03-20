import 'package:app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MobileAdminRedirect extends StatefulWidget {
  const MobileAdminRedirect({super.key});

  @override
  State<MobileAdminRedirect> createState() => _MobileAdminRedirectState();
}

class _MobileAdminRedirectState extends State<MobileAdminRedirect> {
  // Thay thế URL này bằng URL hosting thực tế của bạn (ví dụ: https://appp-73d34.web.app)
  final String adminWebUrl = "https://appp-73d34.web.app";

  @override
  void initState() {
    super.initState();
    // Tự động mở web khi vào màn hình này
    _launchAdminWeb();
  }

  Future<void> _launchAdminWeb() async {
    final Uri url = Uri.parse(adminWebUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Không thể mở trình duyệt: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: AppColors.accent,
              ),
              const SizedBox(height: 24),
              const Text(
                "QUẢN TRỊ VIÊN",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Giao diện quản trị chỉ hỗ trợ trên phiên bản Web để đảm bảo trải nghiệm tốt nhất.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _launchAdminWeb,
                icon: const Icon(Icons.open_in_browser),
                label: const Text("MỞ TRANG QUẢN TRỊ WEB"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text(
                  "ĐĂNG XUẤT",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
