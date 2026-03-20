import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:app/main.dart';
import 'package:app/providers/settings_provider.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => SettingsProvider(),
        child: const MyApp(),
      ),
    );

    // Xóa assert cũ vì app hiện tại không còn là app counter mặc định nữa.
    // Thêm một assert đơn giản để đảm bảo app không bị crash khi khởi tạo.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
