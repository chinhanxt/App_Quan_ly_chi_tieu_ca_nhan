enum VoiceIntentMode { single, multi, uncertain }

enum VoiceReviewStatus {
  listening,
  ready,
  needsReview,
  clarification,
  permissionDenied,
  error,
}

enum VoiceAmbiguityReason {
  uncertainSegmentation,
  missingAmount,
  lowConfidence,
  multipleCandidates,
  conflictingSignals,
}

class VoiceRecommendationOption {
  const VoiceRecommendationOption({
    required this.id,
    required this.title,
    required this.subtitle,
    this.transactions = const <Map<String, dynamic>>[],
    this.missingFields = const <String>[],
    this.requiresEdit = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> transactions;
  final List<String> missingFields;
  final bool requiresEdit;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'transactions': transactions,
      'missingFields': missingFields,
      'requiresEdit': requiresEdit,
    };
  }

  factory VoiceRecommendationOption.fromJson(Map<String, dynamic> json) {
    final rawTransactions = json['transactions'];
    final transactions = rawTransactions is List
        ? rawTransactions.whereType<Map>().map<Map<String, dynamic>>((item) {
            return Map<String, dynamic>.from(item);
          }).toList(growable: false)
        : const <Map<String, dynamic>>[];

    final rawMissingFields = json['missingFields'];
    final missingFields = rawMissingFields is List
        ? rawMissingFields.map((item) => item.toString()).toList(growable: false)
        : const <String>[];

    return VoiceRecommendationOption(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      transactions: transactions,
      missingFields: missingFields,
      requiresEdit: json['requiresEdit'] == true,
    );
  }
}

class VoiceTransactionInterpretation {
  const VoiceTransactionInterpretation({
    required this.rawTranscript,
    required this.normalizedTranscript,
    required this.reviewStatus,
    required this.intentMode,
    this.message = '',
    this.draftTransactions = const <Map<String, dynamic>>[],
    this.recommendations = const <VoiceRecommendationOption>[],
    this.missingFields = const <String>[],
    this.ambiguityReasons = const <VoiceAmbiguityReason>[],
    this.confidence = 0,
  });

  final String rawTranscript;
  final String normalizedTranscript;
  final VoiceReviewStatus reviewStatus;
  final VoiceIntentMode intentMode;
  final String message;
  final List<Map<String, dynamic>> draftTransactions;
  final List<VoiceRecommendationOption> recommendations;
  final List<String> missingFields;
  final List<VoiceAmbiguityReason> ambiguityReasons;
  final double confidence;

  bool get hasReadyTransactions => draftTransactions.isNotEmpty;
  bool get hasRecommendations => recommendations.isNotEmpty;

  VoiceTransactionInterpretation copyWith({
    String? rawTranscript,
    String? normalizedTranscript,
    VoiceReviewStatus? reviewStatus,
    VoiceIntentMode? intentMode,
    String? message,
    List<Map<String, dynamic>>? draftTransactions,
    List<VoiceRecommendationOption>? recommendations,
    List<String>? missingFields,
    List<VoiceAmbiguityReason>? ambiguityReasons,
    double? confidence,
  }) {
    return VoiceTransactionInterpretation(
      rawTranscript: rawTranscript ?? this.rawTranscript,
      normalizedTranscript: normalizedTranscript ?? this.normalizedTranscript,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      intentMode: intentMode ?? this.intentMode,
      message: message ?? this.message,
      draftTransactions: draftTransactions ?? this.draftTransactions,
      recommendations: recommendations ?? this.recommendations,
      missingFields: missingFields ?? this.missingFields,
      ambiguityReasons: ambiguityReasons ?? this.ambiguityReasons,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rawTranscript': rawTranscript,
      'normalizedTranscript': normalizedTranscript,
      'reviewStatus': reviewStatus.name,
      'intentMode': intentMode.name,
      'message': message,
      'draftTransactions': draftTransactions,
      'recommendations': recommendations.map((item) => item.toJson()).toList(),
      'missingFields': missingFields,
      'ambiguityReasons': ambiguityReasons.map((item) => item.name).toList(),
      'confidence': confidence,
    };
  }

  factory VoiceTransactionInterpretation.fromJson(Map<String, dynamic> json) {
    final rawDraftTransactions = json['draftTransactions'];
    final draftTransactions = rawDraftTransactions is List
        ? rawDraftTransactions.whereType<Map>().map<Map<String, dynamic>>((
            item,
          ) {
            return Map<String, dynamic>.from(item);
          }).toList(growable: false)
        : const <Map<String, dynamic>>[];

    final rawRecommendations = json['recommendations'];
    final recommendations = rawRecommendations is List
        ? rawRecommendations.whereType<Map>().map<VoiceRecommendationOption>((
            item,
          ) {
            return VoiceRecommendationOption.fromJson(
              Map<String, dynamic>.from(item),
            );
          }).toList(growable: false)
        : const <VoiceRecommendationOption>[];

    final rawMissingFields = json['missingFields'];
    final missingFields = rawMissingFields is List
        ? rawMissingFields.map((item) => item.toString()).toList(growable: false)
        : const <String>[];

    final rawAmbiguityReasons = json['ambiguityReasons'];
    final ambiguityReasons = rawAmbiguityReasons is List
        ? rawAmbiguityReasons
              .map((item) => item.toString())
              .map(_ambiguityReasonFromString)
              .toList(growable: false)
        : const <VoiceAmbiguityReason>[];

    return VoiceTransactionInterpretation(
      rawTranscript: json['rawTranscript']?.toString() ?? '',
      normalizedTranscript: json['normalizedTranscript']?.toString() ?? '',
      reviewStatus: _reviewStatusFromString(json['reviewStatus']?.toString()),
      intentMode: _intentModeFromString(json['intentMode']?.toString()),
      message: json['message']?.toString() ?? '',
      draftTransactions: draftTransactions,
      recommendations: recommendations,
      missingFields: missingFields,
      ambiguityReasons: ambiguityReasons,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }

  static VoiceReviewStatus _reviewStatusFromString(String? value) {
    return VoiceReviewStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => VoiceReviewStatus.clarification,
    );
  }

  static VoiceIntentMode _intentModeFromString(String? value) {
    return VoiceIntentMode.values.firstWhere(
      (item) => item.name == value,
      orElse: () => VoiceIntentMode.uncertain,
    );
  }

  static VoiceAmbiguityReason _ambiguityReasonFromString(String value) {
    return VoiceAmbiguityReason.values.firstWhere(
      (item) => item.name == value,
      orElse: () => VoiceAmbiguityReason.lowConfidence,
    );
  }
}
