import 'package:app/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AIService local parser', () {
    final service = AIService();

    test('parses a simple expense without AI', () async {
      final result = await service.processInput('Ăn sáng 30k');

      expect(result['success'], true);
      expect(result['source'], 'local_parse');

      final txs = result['transactions'] as List;
      expect(txs.length, 1);

      final tx = txs.first as Map<String, dynamic>;
      expect(tx['amount'], 30000);
      expect(tx['type'], 'debit');
      expect(tx['category'], 'Ăn uống');
    });

    test('parses multiple transactions in one sentence', () async {
      final result = await service.processInput(
        'Ăn sáng 30k và được hoàn tiền 10k',
      );

      expect(result['success'], true);

      final txs = result['transactions'] as List;
      expect(txs.length, 2);

      final first = txs.first as Map<String, dynamic>;
      final second = txs.last as Map<String, dynamic>;

      expect(first['amount'], 30000);
      expect(first['type'], 'debit');
      expect(second['amount'], 10000);
      expect(second['type'], 'credit');
    });

    test('suggests a new category when not in defaults', () async {
      final result = await service.processInput('Đóng tiền điện 500k');

      expect(result['success'], true);

      final tx = (result['transactions'] as List).first as Map<String, dynamic>;
      expect(tx['category'], 'Hóa đơn');
      expect(tx['isNewCategory'], true);
      expect(tx['confirmCreateCategory'], true);
    });

    test('returns clarification when amount is missing', () async {
      final result = await service.processInput('Lương về');

      expect(result['success'], false);
      expect(result['status'], 'clarification');
    });

    test('parses common shorthand cafe expense', () async {
      final result = await service.processInput('cf 25k');

      expect(result['success'], true);
      final tx = (result['transactions'] as List).first as Map<String, dynamic>;
      expect(tx['amount'], 25000);
      expect(tx['type'], 'debit');
      expect(tx['category'], 'Ăn uống');
    });

    test('parses common shorthand transport expense', () async {
      final result = await service.processInput('grab 42k');

      expect(result['success'], true);
      final tx = (result['transactions'] as List).first as Map<String, dynamic>;
      expect(tx['amount'], 42000);
      expect(tx['type'], 'debit');
      expect(tx['category'], 'Di chuyển');
    });

    test('parses million slang correctly', () async {
      final result = await service.processInput('lương về 15 củ');

      expect(result['success'], true);
      final tx = (result['transactions'] as List).first as Map<String, dynamic>;
      expect(tx['amount'], 15000000);
      expect(tx['type'], 'credit');
    });

    test('parses compact million shorthand correctly', () async {
      final result = await service.processInput('thưởng 1m2');

      expect(result['success'], true);
      final tx = (result['transactions'] as List).first as Map<String, dynamic>;
      expect(tx['amount'], 1200000);
      expect(tx['type'], 'credit');
    });

    test('does not flag everyday breakfast input as future', () async {
      final result = await service.processInput('ăn sáng 30k');

      expect(result['success'], true);
      expect(result['status'], 'success');
      expect((result['transactions'] as List).length, 1);
    });

    test('blocks explicit future transaction and does not return cards', () async {
      final result = await service.processInput('mai ăn sáng 10k');

      expect(result['success'], false);
      expect(result['status'], 'clarification');
      expect((result['transactions'] as List), isEmpty);
    });

    test('blocks future intent transaction and does not return cards', () async {
      final result = await service.processInput('định mua giày 2tr');

      expect(result['success'], false);
      expect(result['status'], 'clarification');
      expect((result['transactions'] as List), isEmpty);
    });

    test('blocks pending debt transaction and does not return cards', () async {
      final result = await service.processInput('chưa trả tiền điện 600k');

      expect(result['success'], false);
      expect(result['status'], 'clarification');
      expect((result['transactions'] as List), isEmpty);
    });

    test('infers gift from mother as credit', () async {
      final result = await service.processInput('mẹ cho 500k');

      expect(result['success'], true);
      final tx = (result['transactions'] as List).first as Map<String, dynamic>;
      expect(tx['type'], 'credit');
      expect(tx['amount'], 500000);
    });

    test('splits multiple shorthand transactions', () async {
      final result = await service.processInput('grab 40k, cơm 35k, gửi xe 5k');

      expect(result['success'], true);
      expect((result['transactions'] as List).length, 3);
    });

    test('splits transactions joined by voi', () async {
      final result = await service.processInput('đổ xăng 70k với gửi xe 5k');

      expect(result['success'], true);
      expect((result['transactions'] as List).length, 2);
    });
  });
}
