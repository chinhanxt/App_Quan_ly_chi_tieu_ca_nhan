import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MobileAdminRedirect extends StatefulWidget {
  const MobileAdminRedirect({super.key});

  @override
  State<MobileAdminRedirect> createState() => _MobileAdminRedirectState();
}

class _MobileAdminRedirectState extends State<MobileAdminRedirect> {
  bool _isRedirecting = false;

  String get adminWebUrl {
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.port == 8080 || uri.host == 'localhost' || uri.host == '127.0.0.1') {
        final scheme = uri.scheme.isNotEmpty ? uri.scheme : 'http';
        final host = uri.host.isNotEmpty ? uri.host : 'localhost';
        return '$scheme://$host:8081';
      }
    }
    return "https://appp-73d34.web.app";
  }

  @override
  void initState() {
    super.initState();
    // Tự động chuyển hướng sang cổng Web Admin sau khi render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoRedirect();
    });
  }

  Future<void> _autoRedirect() async {
    if (_isRedirecting) return;
    setState(() => _isRedirecting = true);

    // Chờ 800ms để người dùng thấy thông báo chuyển hướng mượt mà
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    await _launchAdminWeb();
  }

  Future<void> _launchAdminWeb() async {
    final targetUrl = adminWebUrl;
    final Uri url = Uri.parse(targetUrl);
    try {
      if (kIsWeb) {
        // Trên trình duyệt, chuyển hướng tab hiện tại sang Web Admin
        await launchUrl(url, webOnlyWindowName: '_self');
      } else {
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          throw Exception('Could not launch $url');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRedirecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Không thể tự động mở trang Web: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetUrl = adminWebUrl;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon quản trị viên
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E293B),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 52,
                      color: Color(0xFF818CF8),
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    "TÀI KHOẢN QUẢN TRỊ VIÊN",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    "Cổng ứng dụng này chỉ dành cho người dùng cá nhân. Toàn bộ tính năng Quản trị được vận hành chuyên biệt trên Cổng Web Admin.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Khối thông tin chuyển hướng
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Đang tự động chuyển hướng...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                targetUrl,
                                style: const TextStyle(
                                  color: Color(0xFF818CF8),
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Nút bấm thủ công nếu không tự chuyển
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _launchAdminWeb,
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      label: const Text(
                        "MỞ CỔNG QUẢN TRỊ WEB",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nút đăng xuất
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFF87171)),
                      label: const Text(
                        "Đăng xuất (Đổi tài khoản User)",
                        style: TextStyle(
                          color: Color(0xFFF87171),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
