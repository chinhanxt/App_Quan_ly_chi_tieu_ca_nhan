enum AIChatSender { user, ai }

class AIChatMessage {
  final String id;
  final AIChatSender sender;
  final String text;
  final DateTime timestamp;
  final List<Map<String, dynamic>> transactions;
  final String status;
  final bool isSaved;
  final String source;
  final String responseKind;

  const AIChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.transactions = const <Map<String, dynamic>>[],
    this.status = 'success',
    this.isSaved = false,
    this.source = '',
    this.responseKind = '',
  });

  bool get hasTransactions => transactions.isNotEmpty;

  AIChatMessage copyWith({
    String? id,
    AIChatSender? sender,
    String? text,
    DateTime? timestamp,
    List<Map<String, dynamic>>? transactions,
    String? status,
    bool? isSaved,
    String? source,
    String? responseKind,
  }) {
    return AIChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      transactions: transactions ?? this.transactions,
      status: status ?? this.status,
      isSaved: isSaved ?? this.isSaved,
      source: source ?? this.source,
      responseKind: responseKind ?? this.responseKind,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'sender': sender.name,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'transactions': transactions,
      'status': status,
      'isSaved': isSaved,
      'source': source,
      'responseKind': responseKind,
    };
  }

  factory AIChatMessage.fromJson(Map<String, dynamic> json) {
    final rawTransactions = json['transactions'];
    final transactions = rawTransactions is List
        ? rawTransactions.whereType<Map>().map<Map<String, dynamic>>((item) {
            return Map<String, dynamic>.from(item);
          }).toList()
        : const <Map<String, dynamic>>[];

    return AIChatMessage(
      id: json['id']?.toString() ?? '',
      sender: _senderFromString(json['sender']?.toString()),
      text: json['text']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] is int ? json['timestamp'] as int : 0,
      ),
      transactions: transactions,
      status: json['status']?.toString() ?? 'success',
      isSaved: json['isSaved'] == true,
      source: json['source']?.toString() ?? '',
      responseKind: json['responseKind']?.toString() ?? '',
    );
  }

  static AIChatSender _senderFromString(String? value) {
    return value == AIChatSender.user.name
        ? AIChatSender.user
        : AIChatSender.ai;
  }
}
