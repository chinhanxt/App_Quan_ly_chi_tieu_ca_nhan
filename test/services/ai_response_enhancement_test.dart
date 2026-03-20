import 'package:app/services/ai_response_enhancement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AIResponseEnhancement', () {
    test('preflight catches social input', () {
      final result = AIResponseEnhancement.preflight('Ban la ai?');

      expect(result, isNotNull);
      expect(result!['status'], 'clarification');
      expect(result['success'], false);
    });

    test('preflight catches finance action without amount', () {
      final result = AIResponseEnhancement.preflight('Luong ve');

      expect(result, isNotNull);
      expect(result!['status'], 'clarification');
      expect(result['message'], contains('chua noi so tien'));
    });

    test('preflight allows do xang with amount to reach AI', () {
      final result = AIResponseEnhancement.preflight('Đổ xăng 50k');

      expect(result, isNull);
    });

    test('normalizes extended schema into legacy fields', () {
      final result = AIResponseEnhancement.normalizeSchema(<String, dynamic>{
        'status': 'success',
        'message': 'OK',
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'title': 'Luong', 'amount': 15000000},
        ],
      });

      expect(result['success'], true);
      expect((result['transactions'] as List).length, 1);
      expect((result['data'] as List).length, 1);
    });

    test('treats explicit success false as error', () {
      final result = AIResponseEnhancement.normalizeSchema(<String, dynamic>{
        'success': false,
        'message': 'Quota exceeded',
      });

      expect(result['status'], 'error');
      expect(result['success'], false);
    });

    test('postProcess converts negative amount to positive', () {
      final result = AIResponseEnhancement.postProcess(<String, dynamic>{
        'success': true,
        'transactions': <Map<String, dynamic>>[
          <String, dynamic>{'title': 'Hoan tien', 'amount': -50000},
        ],
      }, input: 'Hoan tien 50k');

      final tx = (result['transactions'] as List).first as Map<String, dynamic>;
      expect(tx['amount'], 50000);
    });

    test('postProcess flags single huge transaction for clarification', () {
      final result = AIResponseEnhancement.postProcess(<String, dynamic>{
        'success': true,
        'transactions': <Map<String, dynamic>>[
          <String, dynamic>{'title': 'Tien vao', 'amount': 500000000000},
        ],
      }, input: '500.000.000.000');

      expect(result['status'], 'clarification');
      expect(result['success'], false);
    });
  });
}
