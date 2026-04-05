import 'package:app/services/transaction_datetime_inference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionDateTimeInference', () {
    final now = DateTime(2026, 3, 20, 14, 45);

    test('uses current date and time when input has no date or time', () {
      final refined = TransactionDateTimeInference.refineTransaction(
        input: 'Mua sua 50k',
        transaction: <String, dynamic>{'title': 'Mua sua'},
        now: now,
      );

      expect(refined['dateTime'], '20/03/2026 14:45');
    });

    test(
      'keeps explicit date and current time when user only gives a date',
      () {
        final refined = TransactionDateTimeInference.refineTransaction(
          input: 'Hom qua mua sua 50k',
          transaction: <String, dynamic>{'title': 'Mua sua'},
          now: now,
        );

        expect(refined['dateTime'], '19/03/2026 14:45');
      },
    );

    test('uses time bucket when input mentions morning without exact hour', () {
      final refined = TransactionDateTimeInference.refineTransaction(
        input: 'Sang nay an pho 50k',
        transaction: <String, dynamic>{'title': 'An pho'},
        now: now,
      );

      expect(refined['dateTime'], '20/03/2026 08:00');
    });

    test('uses explicit numeric date and time when provided', () {
      final refined = TransactionDateTimeInference.refineTransaction(
        input: 'An toi 120k luc 18:30 ngay 18/03',
        transaction: <String, dynamic>{'title': 'An toi'},
        now: now,
      );

      expect(refined['dateTime'], '18/03/2026 18:30');
    });

    test('keeps ai date but fills current time when user omits time', () {
      final refined = TransactionDateTimeInference.refineTransaction(
        input: 'Mua ao 200k',
        transaction: <String, dynamic>{'title': 'Mua ao', 'date': '18/03/2026'},
        now: now,
      );

      expect(refined['dateTime'], '18/03/2026 14:45');
    });

    test('maps evening phrase to representative hour', () {
      final refined = TransactionDateTimeInference.refineTransaction(
        input: 'Toi qua do xang 50k',
        transaction: <String, dynamic>{'title': 'Do xang'},
        now: now,
      );

      expect(refined['dateTime'], '19/03/2026 19:00');
    });

    test('anchors month-only input to the current day in that month', () {
      final refined = TransactionDateTimeInference.refineTransaction(
        input: 'Thang 3 chi tieu an uong 400k',
        transaction: <String, dynamic>{'title': 'An uong'},
        now: now,
      );

      expect(refined['dateTime'], '20/03/2026 14:45');
    });

    test('maps future month name back to the previous year when needed', () {
      final refined = TransactionDateTimeInference.refineTransaction(
        input: 'Thang 12 mua ao 200k',
        transaction: <String, dynamic>{'title': 'Mua ao'},
        now: now,
      );

      expect(refined['dateTime'], '20/12/2025 14:45');
    });
  });
}
