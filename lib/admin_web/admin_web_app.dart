import 'package:app/admin_web/admin_web_login_screen.dart';
import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/admin_web/admin_web_shell.dart';
import 'package:app/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AdminWebApp extends StatefulWidget {
  const AdminWebApp({super.key});

  @override
  State<AdminWebApp> createState() => _AdminWebAppState();
}

class _AdminWebAppState extends State<AdminWebApp> {
  final AdminWebRepository _repository = AdminWebRepository();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cổng quản trị',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F0E7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      home: StreamBuilder<User?>(
        stream: _repository.authChanges(),
        builder: (context, authSnapshot) {
          final user = authSnapshot.data;
          if (user == null) {
            return AdminWebLoginScreen(repository: _repository);
          }

          return StreamBuilder<AdminProfile?>(
            stream: _repository.watchAdminProfile(user.uid),
            builder: (context, profileSnapshot) {
              if (!profileSnapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final profile = profileSnapshot.data!;
              if (!profile.isAdmin || profile.isLocked) {
                return _AccessDeniedScreen(
                  profile: profile,
                  repository: _repository,
                );
              }

              return AdminWebShell(
                profile: profile,
                repository: _repository,
              );
            },
          );
        },
      ),
    );
  }
}

class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen({
    required this.profile,
    required this.repository,
  });

  final AdminProfile profile;
  final AdminWebRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_person_rounded,
                  size: 72,
                  color: Color(0xFFD92D20),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tài khoản không có quyền vào khu vực quản trị',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.isLocked
                      ? 'Tài khoản hiện đang bị khóa.'
                      : 'Tài khoản này chưa được cấp quyền quản trị.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: repository.signOut,
                  child: const Text('Đăng xuất'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
