import 'package:app/models/voice_transaction_interpretation.dart';
import 'package:app/widgets/ai_voice_recommendation_panel.dart';
import 'package:app/widgets/ai_voice_session_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AiVoiceSessionPanel shows listening transcript', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AiVoiceSessionPanel(
            isListening: true,
            transcript: 'ăn sáng 45k',
            statusMessage: 'Đang nghe',
          ),
        ),
      ),
    );

    expect(find.text('Đang nghe giọng nói'), findsOneWidget);
    expect(find.text('ăn sáng 45k'), findsOneWidget);
    expect(find.text('Đang nghe'), findsOneWidget);
  });

  testWidgets('AiVoiceSessionPanel shows recovery text when permission blocked', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AiVoiceSessionPanel(
            isListening: false,
            transcript: '',
            statusMessage: 'Quyền micro đang bị chặn.',
          ),
        ),
      ),
    );

    expect(find.text('Quyền micro đang bị chặn.'), findsOneWidget);
  });

  testWidgets('AiVoiceRecommendationPanel exposes recommendation actions', (
    WidgetTester tester,
  ) async {
    VoiceRecommendationOption? selected;

    final interpretation = VoiceTransactionInterpretation(
      rawTranscript: 'ăn sáng với cafe 45k',
      normalizedTranscript: 'an sang voi cafe 45k',
      reviewStatus: VoiceReviewStatus.needsReview,
      intentMode: VoiceIntentMode.uncertain,
      recommendations: const <VoiceRecommendationOption>[
        VoiceRecommendationOption(
          id: 'draft_seed',
          title: 'Dùng bản nháp gần đúng',
          subtitle: 'Mở thẻ giao dịch để chỉnh lại chi tiết nếu cần.',
          transactions: <Map<String, dynamic>>[
            <String, dynamic>{'title': 'Ăn sáng', 'amount': 45000},
          ],
          requiresEdit: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: AiVoiceRecommendationPanel(
            interpretation: interpretation,
            onChooseOption: (option) {
              selected = option;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Dùng bản nháp gần đúng'));
    await tester.pump();

    expect(selected, isNotNull);
    expect(selected!.requiresEdit, isTrue);
  });
}
