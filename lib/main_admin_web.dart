import 'package:app/admin_web/admin_web_app.dart';
import 'package:app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('vi');
  Intl.defaultLocale = 'vi';

  runApp(const AdminWebBootstrap());
}

class AdminWebBootstrap extends StatelessWidget {
  const AdminWebBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Admin web chi ho tro khi chay tren trinh duyet.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return const AdminWebApp();
  }
}
