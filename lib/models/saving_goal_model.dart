import 'package:cloud_firestore/cloud_firestore.dart';

class SavingGoal {
  final String id;
  final String name;
  final int targetAmount;
  final int currentAmount;
  final DateTime startDate;
  final DateTime targetDate;
  final String icon;
  final String color;
  final String status; // 'active', 'completed', 'withdrawn'
  final DateTime createdAt;

  SavingGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.startDate,
    required this.targetDate,
    required this.icon,
    required this.color,
    required this.status,
    required this.createdAt,
  });

  factory SavingGoal.fromFirestore(String id, Map<String, dynamic> data) {
    return SavingGoal(
      id: id,
      name: data['goal_name'] ?? '',
      targetAmount: data['target_amount'] ?? 0,
      currentAmount: data['current_amount'] ?? 0,
      startDate: (data['start_date'] as Timestamp).toDate(),
      targetDate: (data['target_date'] as Timestamp).toDate(),
      icon: data['icon'] ?? 'star',
      color: data['color'] ?? '#3498DB',
      status: data['status'] ?? 'active',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goal_name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'start_date': Timestamp.fromDate(startDate),
      'target_date': Timestamp.fromDate(targetDate),
      'icon': icon,
      'color': color,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  double get progress => (currentAmount / targetAmount).clamp(0.0, 1.0);
  int get remainingToSave => targetAmount - currentAmount;
  int get daysLeft {
    final diff = targetDate.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }
  
  int get dailySavingRequired {
    if (daysLeft <= 0) return remainingToSave > 0 ? remainingToSave : 0;
    return (remainingToSave / daysLeft).round();
  }
}
