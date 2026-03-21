import 'package:app/services/transaction_phrase_lexicon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TransactionPhraseLexicon', () {
    test('parseRaw extracts type and category phrases', () {
      final lexicon = TransactionPhraseLexicon.parseRaw('''
THU (CREDIT/INCOME): luong_ve thuong
CHI (DEBIT/EXPENSE): di_cho do_xang
AN_UONG: di_cho an_sang
''');

      expect(lexicon.inferType('Luong ve 15 trieu'), 'credit');
      expect(lexicon.inferType('Di cho 200k'), 'debit');
      expect(lexicon.bestCategorySection('Di cho 200k'), 'AN_UONG');
    });

    test('loads phrases from bundled data asset', () async {
      final lexicon = await TransactionPhraseLexicon.load();

      expect(lexicon.inferType('Mua ao 200k'), 'debit');
      expect(lexicon.inferType('Luong ve 15 trieu'), 'credit');
      expect(lexicon.bestCategorySection('Dong tien dien 500k'), 'HOA_DON');
      expect(lexicon.bestPrioritySection('grab 50k'), 'DI_LAI');
      expect(lexicon.hasFutureIntent('định mua giày 2tr'), isTrue);
      expect(lexicon.hasPendingDebtIntent('chưa trả tiền điện 600k'), isTrue);
    });
  });
}
