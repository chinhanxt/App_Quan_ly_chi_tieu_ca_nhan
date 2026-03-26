import 'package:app/screens/edit_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EditTransactionScreen renders add-like editing controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EditTransactionScreen(
          transactionId: 'tx-1',
          transactionData: {
            'title': 'An sang',
            'amount': 45000,
            'note': 'Banh mi',
            'type': 'debit',
            'category': 'Ăn uống',
            'timestamp': 1710000000000,
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sửa giao dịch'), findsOneWidget);
    expect(find.text('Chỉnh sửa giao dịch'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Tiêu đề'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Số tiền (VND)'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Ngày giao dịch'), findsOneWidget);
    expect(find.text('Loại giao dịch'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Ghi chú'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Thêm danh mục'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Lưu cập nhật'), findsOneWidget);
  });
}
