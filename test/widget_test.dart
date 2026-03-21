import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:app/providers/settings_provider.dart';

void main() {
  testWidgets('App shell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => SettingsProvider(),
        child: MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: Center(
              child: Text('App shell ready'),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('App shell ready'), findsOneWidget);
  });
}
