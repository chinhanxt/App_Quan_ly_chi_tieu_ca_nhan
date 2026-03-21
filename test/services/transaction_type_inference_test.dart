import 'package:app/services/transaction_type_inference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionTypeInference', () {
    test('fixes "duoc tang" to credit', () {
      final refined = TransactionTypeInference.refineTransaction(
        input: 'Duoc tang 100k',
        transaction: <String, dynamic>{
          'title': 'Duoc tang',
          'type': 'debit',
          'category': 'Qua tang',
        },
      );

      expect(refined['type'], 'credit');
    });

    test('fixes salary income to credit', () {
      final refined = TransactionTypeInference.refineTransaction(
        input: 'Luong ve 15 trieu',
        transaction: <String, dynamic>{
          'title': 'Luong ve',
          'type': 'debit',
          'category': 'Luong',
        },
      );

      expect(refined['type'], 'credit');
    });

    test('keeps giving money away as debit', () {
      final refined = TransactionTypeInference.refineTransaction(
        input: 'Tang me 100k',
        transaction: <String, dynamic>{
          'title': 'Tang me',
          'type': 'credit',
          'category': 'Qua tang',
        },
      );

      expect(refined['type'], 'debit');
    });

    test('uses transaction-specific context in mixed input', () {
      final income = TransactionTypeInference.refineTransaction(
        input: 'An sang 30k va duoc hoan tien 10k',
        transaction: <String, dynamic>{
          'title': 'Duoc hoan tien',
          'type': 'debit',
          'category': 'Hoan tien',
        },
      );

      final expense = TransactionTypeInference.refineTransaction(
        input: 'An sang 30k va duoc hoan tien 10k',
        transaction: <String, dynamic>{
          'title': 'An sang',
          'type': 'credit',
          'category': 'An uong',
        },
      );

      expect(income['type'], 'credit');
      expect(expense['type'], 'debit');
    });

    test('maps type aliases from AI output', () {
      final refined = TransactionTypeInference.refineTransaction(
        input: 'Thu no 2 trieu',
        transaction: <String, dynamic>{
          'title': 'Thu no',
          'type': 'thu',
          'category': 'Thu no',
        },
      );

      expect(refined['type'], 'credit');
    });

    test('treats di cho as debit', () {
      final refined = TransactionTypeInference.refineTransaction(
        input: 'Di cho 10tr',
        transaction: <String, dynamic>{
          'title': 'Di cho',
          'type': 'credit',
          'category': 'Mua sam',
        },
      );

      expect(refined['type'], 'debit');
    });
  });
}
