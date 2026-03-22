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
    DateTime readDate(dynamic value, {DateTime? fallback}) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? (fallback ?? DateTime.now());
      }
      return fallback ?? DateTime.now();
    }

    int readInt(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    String readString(dynamic value, {String fallback = ''}) {
      if (value == null) {
        return fallback;
      }
      if (value is String) {
        final trimmed = value.trim();
        return trimmed.isEmpty ? fallback : trimmed;
      }
      return value.toString();
    }

    return SavingGoal(
      id: id,
      name: readString(data['goal_name'] ?? data['name']),
      targetAmount: readInt(data['target_amount'] ?? data['targetAmount']),
      currentAmount: readInt(data['current_amount'] ?? data['currentAmount']),
      startDate: readDate(
        data['start_date'] ?? data['startDate'],
        fallback: DateTime.now(),
      ),
      targetDate: readDate(
        data['target_date'] ?? data['targetDate'],
        fallback: DateTime.now().add(const Duration(days: 30)),
      ),
      icon: readString(data['icon'], fallback: 'star'),
      color: readString(data['color'], fallback: '#3498DB'),
      status: readString(data['status'], fallback: 'active'),
      createdAt: readDate(
        data['created_at'] ?? data['createdAt'],
        fallback: DateTime.now(),
      ),
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
