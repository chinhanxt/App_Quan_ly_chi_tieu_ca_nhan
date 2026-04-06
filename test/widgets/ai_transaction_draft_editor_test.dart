import 'package:app/widgets/ai_transaction_draft_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AITransactionDraftEditor returns normalized edited draft', (
    WidgetTester tester,
  ) async {
    Map<String, dynamic>? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => const AITransactionDraftEditor(
                        initialTransaction: <String, dynamic>{
                          'title': 'An sang',
                          'amount': 30000,
                          'type': 'debit',
                          'category': 'Ăn uống',
                          'note': 'Banh mi',
                          'date': '06/04/2026',
                          'dateTime': '06/04/2026 08:00',
                          'isNewCategory': false,
                          'confirmCreateCategory': true,
                          'suggestedIcon': 'utensils',
                        },
                        categoryOptions: <Map<String, dynamic>>[
                          <String, dynamic>{
                            'name': 'Ăn uống',
                            'iconName': 'utensils',
                          },
                          <String, dynamic>{
                            'name': 'Di chuyển',
                            'iconName': 'car',
                          },
                        ],
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tiêu đề'),
      'Di chuyen Grab',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Số tiền (VND)'),
      '45000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ghi chú'),
      'Đi làm',
    );

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Lưu thay đổi'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!['title'], 'Di chuyen Grab');
    expect(result!['amount'], 45000);
    expect(result!['type'], 'debit');
    expect(result!['note'], 'Đi làm');
    expect(result!['category'], 'Ăn uống');
    expect(result!['selectedCategory'], 'Ăn uống');
    expect(result!['selectedIconName'], 'utensils');
    expect(result!['date'], '06/04/2026');
    expect(result!['dateTime'], '06/04/2026 08:00');
  });
}
