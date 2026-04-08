enum AssistantActionType {
  openBudget,
  openSavings,
  switchToTransaction,
  openAddTransaction,
}

class AssistantActionSuggestion {
  const AssistantActionSuggestion({
    required this.id,
    required this.label,
    required this.type,
    this.payload,
  });

  final String id;
  final String label;
  final AssistantActionType type;
  final String? payload;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'type': type.name,
      'payload': payload,
    };
  }

  factory AssistantActionSuggestion.fromJson(Map<String, dynamic> json) {
    final typeName = json['type']?.toString() ?? '';
    return AssistantActionSuggestion(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: AssistantActionType.values.firstWhere(
        (item) => item.name == typeName,
        orElse: () => AssistantActionType.switchToTransaction,
      ),
      payload: json['payload']?.toString(),
    );
  }
}
