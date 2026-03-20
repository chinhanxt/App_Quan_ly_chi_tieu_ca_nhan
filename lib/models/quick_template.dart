class QuickTemplate {
  final String id;
  final String label;
  final String title;
  final int amount;
  final String type;
  final String category;
  final String note;
  final String iconName;

  const QuickTemplate({
    required this.id,
    required this.label,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.note,
    required this.iconName,
  });

  bool get isCredit => type == 'credit';

  String get amountPreview {
    final prefix = isCredit ? '+' : '-';
    return '$prefix${amount.toString()}';
  }

  QuickTemplate copyWith({
    String? id,
    String? label,
    String? title,
    int? amount,
    String? type,
    String? category,
    String? note,
    String? iconName,
  }) {
    return QuickTemplate(
      id: id ?? this.id,
      label: label ?? this.label,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
      iconName: iconName ?? this.iconName,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'note': note,
      'iconName': iconName,
    };
  }

  factory QuickTemplate.fromJson(Map<String, dynamic> json) {
    return QuickTemplate(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      amount: _parseAmount(json['amount']),
      type: json['type']?.toString() == 'credit' ? 'credit' : 'debit',
      category: json['category']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      iconName: json['iconName']?.toString() ?? '',
    );
  }

  static int _parseAmount(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    final text = value?.toString() ?? '';
    return int.tryParse(text) ?? 0;
  }
}
