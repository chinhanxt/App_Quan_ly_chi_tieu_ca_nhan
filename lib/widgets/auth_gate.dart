import 'package:app/screens/admin/admin_dashboard.dart';
import 'package:app/screens/admin/mobile_admin_redirect.dart';
import 'package:app/screens/dashboard.dart';
import 'package:app/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Gán vào biến cục bộ để tránh lỗi null-safety khi truy cập data!
        final user = snapshot.data;

        if (user == null) {
          return LoginView();
        }

        // Dùng StreamBuilder để lắng nghe vai trò người dùng real-time
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final data = userSnapshot.data!.data() as Map<String, dynamic>?;
              
              if (data != null) {
                String role = data['role'] ?? 'user';
                String status = data['status'] ?? 'active';

                if (status == 'locked') {
                  // Đăng xuất ngay lập tức nếu tài khoản bị khóa
                  Future.microtask(() => FirebaseAuth.instance.signOut());
                  return LoginView();
                }

                if (role == 'admin') {
                  // Nếu là Web thì cho vào Dashboard Admin
                  if (kIsWeb) {
                    return const AdminDashboard();
                  } else {
                    // Nếu là Mobile thì đưa tới màn hình điều hướng sang Web
                    return const MobileAdminRedirect();
                  }
                }
              }
            }

            // Mặc định vào Dashboard người dùng
            return const Dashboard();
          },
        );
      },
    );
  }
}
