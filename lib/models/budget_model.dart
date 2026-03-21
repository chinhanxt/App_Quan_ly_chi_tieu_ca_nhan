class Budget {
  final String id;
  final String categoryName;
  final int limitAmount;
  final String monthyear;
  final DateTime createdAt;

  Budget({
    required this.id,
    required this.categoryName,
    required this.limitAmount,
    required this.monthyear,
    required this.createdAt,
  });

  /// Chuyển đổi từ Firestore document sang model Budget
  factory Budget.fromFirestore(String docId, Map<String, dynamic> data) {
    return Budget(
      id: docId,
      categoryName: data['categoryName'] ?? 'Khác',
      limitAmount: data['limitAmount'] ?? 0,
      monthyear: data['monthyear'] ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
    );
  }

  /// Chuyển đổi model Budget sang dạng Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'limitAmount': limitAmount,
      'monthyear': monthyear,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'Budget(category: $categoryName, limit: $limitAmount, month: $monthyear)';
  }
}
