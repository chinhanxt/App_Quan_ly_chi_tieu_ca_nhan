import 'dart:async';

import 'package:app/screens/admin/admin_dashboard.dart';
import 'package:app/screens/admin/mobile_admin_redirect.dart';
import 'package:app/screens/dashboard.dart';
import 'package:app/screens/login_screen.dart';
import 'package:app/screens/system_access_blocked_screen.dart';
import 'package:app/utils/runtime_schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Timer? _maintenanceRefreshTimer;
  DateTime? _scheduledMaintenanceTick;

  @override
  void dispose() {
    _maintenanceRefreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleMaintenanceRefresh(Map<String, dynamic> controls) {
    final nextTick = nextMaintenanceTransitionAt(controls);
    if (_scheduledMaintenanceTick == nextTick) {
      return;
    }

    _maintenanceRefreshTimer?.cancel();
    _scheduledMaintenanceTick = nextTick;
    if (nextTick == null) {
      return;
    }

    final delay = nextTick.difference(DateTime.now()) + const Duration(seconds: 1);
    _maintenanceRefreshTimer = Timer(
      delay.isNegative ? const Duration(seconds: 1) : delay,
      () {
        if (!mounted) {
          return;
        }
        setState(() {
          _scheduledMaintenanceTick = null;
        });
      },
    );
  }

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

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('system_configs')
              .doc('app_controls')
              .snapshots(),
          builder: (context, appControlSnapshot) {
            if (appControlSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final canReadAppControls =
                appControlSnapshot.error is! FirebaseException ||
                (appControlSnapshot.error as FirebaseException).code !=
                    'permission-denied';
            final appControls = canReadAppControls
                ? appControlSnapshot.data?.data() ?? const <String, dynamic>{}
                : const <String, dynamic>{};
            _scheduleMaintenanceRefresh(appControls);
            final maintenanceMode =
                canReadAppControls && isMaintenanceActive(appControls);

            if (maintenanceMode) {
              return SystemAccessBlockedScreen(
                title: 'Hệ thống đang bảo trì',
                message: 'Vui lòng thử lại sau khi quá trình bảo trì hoàn tất.',
                actionLabel: 'Đăng xuất',
                onAction: () => FirebaseAuth.instance.signOut(),
              );
            }

            // Dùng StreamBuilder để lắng nghe vai trò người dùng real-time
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
                  final data = userSnapshot.data!.data();

                  if (data != null) {
                    final role = data['role']?.toString() ?? 'user';
                    final email =
                        data['email']?.toString() ??
                        user.email?.toLowerCase() ??
                        '';
                    final status = data['status']?.toString() ?? 'active';

                    if (status == 'locked') {
                      return SystemAccessBlockedScreen(
                        title: 'Tài khoản đã bị khóa',
                        message:
                            'Tài khoản của bạn hiện không thể truy cập. Vui lòng liên hệ hỗ trợ để biết thêm chi tiết.',
                        actionLabel: 'Đăng xuất',
                        onAction: () => FirebaseAuth.instance.signOut(),
                      );
                    }

                    if (role == 'admin' ||
                        role == 'super_admin' ||
                        email.toLowerCase() == 'admin@gmail.com') {
                      if (kIsWeb) {
                        return const AdminDashboard();
                      } else {
                        return const MobileAdminRedirect();
                      }
                    }
                  }
                }

                return const Dashboard();
              },
            );
          },
        );
      },
    );
  }
}
