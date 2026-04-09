import 'package:app/models/voice_transaction_interpretation.dart';
import 'package:app/services/transaction_amount_parser.dart';
import 'package:app/services/transaction_category_resolver.dart';
import 'package:app/services/transaction_confidence.dart';
import 'package:app/services/transaction_datetime_inference.dart';
import 'package:app/services/transaction_segmenter.dart';
import 'package:app/services/transaction_type_inference.dart';
import 'package:intl/intl.dart';

class VoiceTransactionInterpreter {
  static const double _safeConfidenceThreshold = 0.75;

  const VoiceTransactionInterpreter();

  Future<VoiceTransactionInterpretation> interpret({
    required String transcript,
    required List<Map<String, dynamic>> availableCategories,
    DateTime? now,
  }) async {
    final rawTranscript = transcript.trim();
    final normalized = TransactionTypeInference.normalizeText(rawTranscript);
    if (normalized.isEmpty) {
      return const VoiceTransactionInterpretation(
        rawTranscript: '',
        normalizedTranscript: '',
        reviewStatus: VoiceReviewStatus.clarification,
        intentMode: VoiceIntentMode.uncertain,
        message: 'Mình chưa nghe rõ nội dung giao dịch. Bạn thử nói lại giúp mình nhé.',
      );
    }

    final current = now ?? DateTime.now();
    final baseSegments = TransactionSegmenter.split(rawTranscript);
    final amountMatches = TransactionAmountParser.extractAmounts(rawTranscript);
    final inferredSegments = _inferSegmentsWithoutSeparators(
      rawTranscript,
      amountMatches,
    );
    final hasExplicitConnector = _hasExplicitConnector(rawTranscript);
    final connectorClauses = _splitConnectorClauses(rawTranscript);

    final VoiceIntentMode intentMode;
    final List<String> chosenSegments;
    final List<VoiceAmbiguityReason> reasons = <VoiceAmbiguityReason>[];

    if (baseSegments.length >= 2) {
      intentMode = VoiceIntentMode.multi;
      chosenSegments = baseSegments.map((item) => item.text).toList(growable: false);
    } else if (hasExplicitConnector &&
        connectorClauses.length >= 2 &&
        amountMatches.length <= 1) {
      intentMode = VoiceIntentMode.uncertain;
      chosenSegments = <String>[rawTranscript];
      reasons.add(VoiceAmbiguityReason.uncertainSegmentation);
      reasons.add(VoiceAmbiguityReason.multipleCandidates);
    } else if (amountMatches.length <= 1 && !hasExplicitConnector) {
      intentMode = VoiceIntentMode.single;
      chosenSegments = <String>[rawTranscript];
    } else if (inferredSegments.length >= 2) {
      intentMode = hasExplicitConnector
          ? VoiceIntentMode.multi
          : VoiceIntentMode.uncertain;
      chosenSegments = inferredSegments;
      if (!hasExplicitConnector) {
        reasons.add(VoiceAmbiguityReason.uncertainSegmentation);
      }
    } else {
      intentMode = amountMatches.length >= 2
          ? VoiceIntentMode.uncertain
          : VoiceIntentMode.single;
      chosenSegments = <String>[rawTranscript];
      if (amountMatches.length >= 2) {
        reasons.add(VoiceAmbiguityReason.conflictingSignals);
      }
    }

    final parsedTransactions = <Map<String, dynamic>>[];
    final missingFields = <String>{};
    final confidences = <double>[];

    for (final segment in chosenSegments) {
      final parsed = await _parseSegment(
        segmentText: segment,
        fullInput: rawTranscript,
        availableCategories: availableCategories,
        now: current,
        isMultiSegment: chosenSegments.length > 1,
      );

      if (parsed == null) {
        missingFields.add('amount');
        reasons.add(VoiceAmbiguityReason.missingAmount);
        continue;
      }

      parsedTransactions.add(parsed);
      confidences.add((parsed['confidence'] as num?)?.toDouble() ?? 0);

      if ((parsed['amount'] as int? ?? 0) <= 0) {
        missingFields.add('amount');
      }
      if ((parsed['title']?.toString().trim().isEmpty ?? true)) {
        missingFields.add('title');
      }
      if ((parsed['category']?.toString().trim().isEmpty ?? true)) {
        missingFields.add('category');
      }
      if (((parsed['confidence'] as num?)?.toDouble() ?? 0) <
          _safeConfidenceThreshold) {
        reasons.add(VoiceAmbiguityReason.lowConfidence);
      }
      if (chosenSegments.length > 1 &&
          ((parsed['confidence'] as num?)?.toDouble() ?? 0) <
              (_safeConfidenceThreshold + 0.1)) {
        reasons.add(VoiceAmbiguityReason.multipleCandidates);
      }
    }

    final double confidence = confidences.isEmpty
        ? 0.0
        : confidences.reduce((a, b) => a + b) / confidences.length;
    final isCombineOrSplitAmbiguity =
        hasExplicitConnector &&
        connectorClauses.length >= 2 &&
        amountMatches.length <= 1 &&
        parsedTransactions.isNotEmpty;
    final safeTransactions = parsedTransactions
        .where(_isSafeTransaction)
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);

    if (safeTransactions.isNotEmpty &&
        safeTransactions.length == parsedTransactions.length &&
        missingFields.isEmpty &&
        intentMode != VoiceIntentMode.uncertain) {
      return VoiceTransactionInterpretation(
        rawTranscript: rawTranscript,
        normalizedTranscript: normalized,
        reviewStatus: VoiceReviewStatus.ready,
        intentMode: intentMode,
        message: safeTransactions.length > 1
            ? 'Mình đã tách ${safeTransactions.length} giao dịch từ giọng nói. Bạn xem lại rồi lưu nhé.'
            : 'Mình đã dựng card giao dịch từ giọng nói. Bạn xem lại rồi lưu nhé.',
        draftTransactions: safeTransactions,
      ).copyWith(confidence: confidence);
    }

    final recommendations = _buildRecommendations(
      rawTranscript: rawTranscript,
      parsedTransactions: parsedTransactions,
      inferredSegments: inferredSegments,
      connectorClauses: connectorClauses,
      availableCategories: availableCategories,
      missingFields: missingFields.toList(growable: false),
      askCombineOrSplit: isCombineOrSplitAmbiguity,
    );

    if (recommendations.isNotEmpty) {
      return VoiceTransactionInterpretation(
        rawTranscript: rawTranscript,
        normalizedTranscript: normalized,
        reviewStatus: VoiceReviewStatus.needsReview,
        intentMode: intentMode,
        message: isCombineOrSplitAmbiguity
            ? 'Câu này có thể là một giao dịch chung hoặc hai giao dịch riêng. Bạn chọn giúp mình cách hiểu đúng hơn nhé.'
            : 'Mình nghe được một phần rồi. Bạn chọn cách hiểu gần đúng nhất hoặc mở bản nháp để sửa tiếp nhé.',
        recommendations: recommendations,
        missingFields: missingFields.toList(growable: false),
        ambiguityReasons: reasons.toSet().toList(growable: false),
      ).copyWith(confidence: confidence);
    }

    return VoiceTransactionInterpretation(
      rawTranscript: rawTranscript,
      normalizedTranscript: normalized,
      reviewStatus: VoiceReviewStatus.clarification,
      intentMode: intentMode,
      message: missingFields.contains('amount')
          ? 'Mình chưa nghe chắc số tiền. Bạn nói lại rõ hơn hoặc nhập tay giúp mình nhé.'
          : 'Mình chưa đủ chắc để dựng giao dịch từ câu này. Bạn thử nói chậm hơn hoặc tách từng ý giúp mình nhé.',
      missingFields: missingFields.toList(growable: false),
      ambiguityReasons: reasons.toSet().toList(growable: false),
    ).copyWith(confidence: confidence);
  }

  Future<Map<String, dynamic>?> _parseSegment({
    required String segmentText,
    required String fullInput,
    required List<Map<String, dynamic>> availableCategories,
    required DateTime now,
    required bool isMultiSegment,
  }) async {
    final amounts = TransactionAmountParser.extractAmounts(segmentText);
    if (amounts.isEmpty) return null;

    final amount = amounts.last.amount;
    final provisionalTitle = _buildTitle(segmentText, 'Giao dịch');
    final resolvedCategory = await TransactionCategoryResolver.resolve(
      input: segmentText,
      title: provisionalTitle,
      availableCategories: availableCategories,
    );
    final inferredType =
        TransactionTypeInference.inferType(
          input: segmentText,
          title: provisionalTitle,
          category: resolvedCategory.category,
        ) ??
        _defaultTypeForCategory(resolvedCategory.category);
    final resolvedDateTime = TransactionDateTimeInference.resolveDateTime(
      input: fullInput,
      transaction: <String, dynamic>{'title': provisionalTitle},
      now: now,
    );
    final confidence = TransactionConfidence.score(
      hasAmount: amount > 0,
      hasType: inferredType.isNotEmpty,
      hasCategory: resolvedCategory.category.trim().isNotEmpty,
      hasKnownCategory: resolvedCategory.isKnownCategory,
      hasTitle: provisionalTitle.trim().isNotEmpty,
      isMultiSegment: isMultiSegment,
    );

    return <String, dynamic>{
      'title': provisionalTitle,
      'amount': amount,
      'type': inferredType,
      'category': resolvedCategory.category,
      'note': segmentText.trim(),
      'date': DateFormat('dd/MM/yyyy').format(resolvedDateTime),
      'time': DateFormat('HH:mm').format(resolvedDateTime),
      'dateTime': DateFormat('dd/MM/yyyy HH:mm').format(resolvedDateTime),
      'isNewCategory': resolvedCategory.isNewCategory,
      'confirmCreateCategory': resolvedCategory.isNewCategory,
      'suggestedIcon': resolvedCategory.iconName,
      'confidence': confidence,
      'confidenceLabel': TransactionConfidence.label(confidence),
      'source': 'voice_parse',
    };
  }

  List<VoiceRecommendationOption> _buildRecommendations({
    required String rawTranscript,
    required List<Map<String, dynamic>> parsedTransactions,
    required List<String> inferredSegments,
    required List<String> connectorClauses,
    required List<Map<String, dynamic>> availableCategories,
    required List<String> missingFields,
    bool askCombineOrSplit = false,
  }) {
    final options = <VoiceRecommendationOption>[];
    final recommendationSegments =
        inferredSegments.length >= 2
        ? inferredSegments
        : connectorClauses.length >= 2
        ? connectorClauses
        : const <String>[];

    if (parsedTransactions.isNotEmpty) {
      options.add(
        VoiceRecommendationOption(
          id: 'draft_seed',
          title: askCombineOrSplit
              ? 'Gộp chung thành 1 giao dịch'
              : 'Dùng bản nháp gần đúng',
          subtitle: askCombineOrSplit
              ? 'Nếu đây thực ra là một ý liền nhau, mình sẽ giữ thành một thẻ để bạn xem lại.'
              : missingFields.isEmpty
              ? 'Mở thẻ giao dịch để chỉnh lại chi tiết nếu cần.'
              : 'Giữ phần mình nghe chắc, rồi bạn bổ sung ${missingFields.join(', ')}.',
          transactions: parsedTransactions
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false),
          missingFields: missingFields,
          requiresEdit: !askCombineOrSplit,
        ),
      );
    }

    if (recommendationSegments.length >= 2) {
      final candidateTransactions = <Map<String, dynamic>>[];
      final splitMissingFields = <String>{};
      for (var index = 0; index < recommendationSegments.length; index++) {
        final segment = recommendationSegments[index];
        final amounts = TransactionAmountParser.extractAmounts(segment);
        final amount = amounts.isNotEmpty ? amounts.last.amount : 0;
        if (amount <= 0) {
          splitMissingFields.add('amount');
        }
        candidateTransactions.add(
          <String, dynamic>{
            'title': _buildTitle(segment, 'Giao dịch ${index + 1}'),
            'amount': amount,
            'type': TransactionTypeInference.inferType(input: segment) ?? 'debit',
            'category': _bestEffortCategoryName(segment, availableCategories),
            'note': segment,
            'isNewCategory': false,
            'confirmCreateCategory': false,
            'suggestedIcon': 'cartShopping',
            'source': 'voice_recommendation',
          },
        );
      }

      options.add(
        VoiceRecommendationOption(
          id: 'split_guess',
          title: askCombineOrSplit
              ? 'Tách riêng từng giao dịch'
              : 'Tách thành ${recommendationSegments.length} giao dịch',
          subtitle: splitMissingFields.contains('amount')
              ? 'Mình đã tách ý chính, bạn chỉ cần bổ sung số tiền còn thiếu.'
              : 'Áp dụng cách tách này rồi chỉnh từng thẻ nếu cần.',
          transactions: candidateTransactions,
          missingFields: splitMissingFields.toList(growable: false),
          requiresEdit: true,
        ),
      );
    }

    if (options.isEmpty && rawTranscript.isNotEmpty) {
      options.add(
        VoiceRecommendationOption(
          id: 'manual_retry',
          title: 'Chuyển lời đã nghe xuống ô nhập',
          subtitle: 'Giữ nguyên nội dung đã nghe để bạn chỉnh tay nhanh hơn.',
          transactions: const <Map<String, dynamic>>[],
          requiresEdit: false,
        ),
      );
    }

    return options.take(3).toList(growable: false);
  }

  List<String> _inferSegmentsWithoutSeparators(
    String rawTranscript,
    List<ParsedAmount> amounts,
  ) {
    if (amounts.length < 2) {
      return const <String>[];
    }

    final segments = <String>[];
    var start = 0;
    for (var index = 0; index < amounts.length; index++) {
      final nextStart = index + 1 < amounts.length ? amounts[index + 1].start : -1;
      if (nextStart == -1) {
        final segment = rawTranscript.substring(start).trim();
        if (segment.isNotEmpty) {
          segments.add(segment);
        }
        break;
      }

      final segment = rawTranscript.substring(start, nextStart).trim();
      if (segment.isNotEmpty) {
        segments.add(segment);
      }
      start = nextStart;
    }

    final cleaned = segments
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return cleaned.length >= 2 ? cleaned : const <String>[];
  }

  bool _hasExplicitConnector(String rawTranscript) {
    final normalized = TransactionTypeInference.normalizeText(rawTranscript);
    const connectors = <String>[
      'va',
      'voi',
      'roi',
      'sau do',
      'xong',
    ];
    return connectors.any(
      (item) => RegExp('(^| )${RegExp.escape(item)}(?= |\\\$)').hasMatch(normalized),
    );
  }

  List<String> _splitConnectorClauses(String rawTranscript) {
    final parts = rawTranscript
        .split(
          RegExp(
            r'\s*(?:\b(?:và|va|với|voi|rồi|roi|sau đó|sau do|xong)\b)\s*',
            caseSensitive: false,
            unicode: true,
          ),
        )
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return parts;
  }

  bool _isSafeTransaction(Map<String, dynamic> tx) {
    final amount = tx['amount'] as int? ?? 0;
    final confidence = (tx['confidence'] as num?)?.toDouble() ?? 0;
    final title = tx['title']?.toString().trim() ?? '';
    final category = tx['category']?.toString().trim() ?? '';
    return amount > 0 &&
        confidence >= _safeConfidenceThreshold &&
        title.isNotEmpty &&
        category.isNotEmpty;
  }

  String _buildTitle(String input, String fallbackCategory) {
    var title = input.trim();
    title = title.replaceAll(
      RegExp(
        r'\b\d[\d\.,]*(?:\s*)(k|ngan|nghin|tr|trieu|cu|m|lit|ve|xị|xi)?\b',
        caseSensitive: false,
      ),
      ' ',
    );
    title = title.replaceAll(
      RegExp(
        r'\b(luc|lúc|ngay|ngày|hom|hôm|nay|qua|mai|toi|tối|sang|sáng|trua|trưa|chieu|chiều|dem|đêm|khuya|va|và|voi|với|roi|rồi|sau do|sau đó|xong|thu|thứ|tuan|tuần|thang|tháng|nam|năm|dau|đầu|cuoi|cuối)\b',
        caseSensitive: false,
        unicode: true,
      ),
      ' ',
    );
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (title.isEmpty) return fallbackCategory;
    final words = title.split(' ').where((item) => item.trim().isNotEmpty);
    final trimmed = words.take(6).join(' ').trim();
    if (trimmed.isEmpty) return fallbackCategory;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  String _defaultTypeForCategory(String category) {
    final normalized = TransactionTypeInference.normalizeText(category);
    if (normalized.contains('luong') ||
        normalized.contains('thu nhap') ||
        normalized.contains('doanh thu') ||
        normalized.contains('thuong') ||
        normalized.contains('hoan tien')) {
      return 'credit';
    }
    return 'debit';
  }

  String _bestEffortCategoryName(
    String transcript,
    List<Map<String, dynamic>> availableCategories,
  ) {
    final normalizedInput = TransactionTypeInference.normalizeText(transcript);
    for (final item in availableCategories) {
      final name = item['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      final normalizedName = TransactionTypeInference.normalizeText(name);
      if (normalizedInput.contains(normalizedName)) {
        return name;
      }
    }
    return 'Khác';
  }
}
