import 'package:app/models/voice_transaction_interpretation.dart';
import 'package:app/services/voice_transaction_interpreter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const interpreter = VoiceTransactionInterpreter();
  const categories = <Map<String, dynamic>>[
    <String, dynamic>{'name': 'Ăn uống', 'iconName': 'utensils'},
    <String, dynamic>{'name': 'Di chuyển', 'iconName': 'car'},
    <String, dynamic>{'name': 'Lương', 'iconName': 'moneyBillWave'},
  ];

  test('returns ready result for a clear single transaction', () async {
    final result = await interpreter.interpret(
      transcript: 'ăn sáng 45k',
      availableCategories: categories,
      now: DateTime(2026, 4, 8, 8, 0),
    );

    expect(result.reviewStatus, VoiceReviewStatus.ready);
    expect(result.intentMode, VoiceIntentMode.single);
    expect(result.draftTransactions, hasLength(1));
    expect(result.draftTransactions.first['amount'], 45000);
  });

  test('returns ready result for explicit multi-intent transcript', () async {
    final result = await interpreter.interpret(
      transcript: 'ăn sáng 45k và đổ xăng 50k',
      availableCategories: categories,
      now: DateTime(2026, 4, 8, 8, 0),
    );

    expect(result.reviewStatus, VoiceReviewStatus.ready);
    expect(result.intentMode, VoiceIntentMode.multi);
    expect(result.draftTransactions.length, 2);
  });

  test('returns recommendation flow for ambiguous transcript', () async {
    final result = await interpreter.interpret(
      transcript: 'ăn sáng với cafe 45k',
      availableCategories: categories,
      now: DateTime(2026, 4, 8, 8, 0),
    );

    expect(result.reviewStatus, VoiceReviewStatus.needsReview);
    expect(result.hasRecommendations, isTrue);
    expect(result.recommendations, isNotEmpty);
  });
}
