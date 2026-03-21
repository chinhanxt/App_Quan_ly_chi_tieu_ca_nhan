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

    test('routes simple single transaction to local fast path', () {
      final result = AIResponseEnhancement.shouldUseLocalFastPath(
        'Đổ xăng 50k',
      );

      expect(result, isTrue);
    });

    test('keeps multi transaction input on AI path', () {
      final result = AIResponseEnhancement.shouldUseLocalFastPath(
        'Ăn sáng 30k và được hoàn tiền 10k',
      );

      expect(result, isFalse);
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
      expect(result['message'], isNot('OK'));
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

    test('fallbackMessage explains rate limit instead of generic busy', () {
      final message = AIResponseEnhancement.fallbackMessage(
        reasonCode: 'rate_limit',
      );

      expect(message.toLowerCase(), isNot(contains('openai')));
      expect(message.toLowerCase(), contains('giao dịch'));
    });

    test('failureMessage explains auth issues when request truly fails', () {
      final message = AIResponseEnhancement.failureMessage(reasonCode: 'auth');

      expect(
        message.toLowerCase(),
        anyOf(contains('thử lại'), contains('chưa')),
      );
    });

    test('fallbackMessage for local success stays friendly and generic', () {
      final message = AIResponseEnhancement.fallbackMessage(
        reasonCode: 'local_fast_path',
      );

      expect(message.toLowerCase(), isNot(contains('không cần gọi ai')));
      expect(message.toLowerCase(), contains('giao dịch'));
    });

    test('successMessage uses playful success copy', () {
      final message = AIResponseEnhancement.successMessage(1);

      expect(message.toLowerCase(), contains('giao dịch'));
      expect(message.toLowerCase(), anyOf(contains('lưu'), contains('sổ')));
    });
  });
}
