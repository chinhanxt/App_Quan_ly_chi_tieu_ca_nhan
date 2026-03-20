import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../models/saving_goal_model.dart';
import '../screens/saving_goals_screen.dart';
import '../screens/saving_goal_detail_screen.dart';

class TopSavingGoalsWidget extends StatelessWidget {
  final String userId;
  const TopSavingGoalsWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.decimalPattern('vi_VN');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Mục tiêu tiết kiệm",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavingGoalsScreen(),
                    ),
                  );
                },
                child: const Text("Xem tất cả"),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('saving_goals')
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Lỗi tải dữ liệu: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Lấy dữ liệu và lọc 'active' ngay tại đây để không cần Index phức tạp
              final allGoals =
                  snapshot.data?.docs
                      .map(
                        (doc) => SavingGoal.fromFirestore(
                          doc.id,
                          doc.data() as Map<String, dynamic>,
                        ),
                      )
                      .toList() ??
                  [];

              final activeGoals = allGoals
                  .where((goal) => goal.status == 'active')
                  .take(3)
                  .toList();

              if (activeGoals.isEmpty) {
                return Center(
                  child: Text(
                    "Chưa có mục tiêu nào. Hãy bắt đầu ngay!",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: activeGoals.length,
                itemBuilder: (context, index) {
                  final goal = activeGoals[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SavingGoalDetailScreen(goal: goal),
                        ),
                      );
                    },
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getIconData(goal.icon),
                                size: 20,
                                color: AppColors.accentStrong,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  goal.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            "Còn thiếu ${currencyFormat.format(goal.remainingToSave)} VND",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: goal.progress,
                              minHeight: 6,
                              backgroundColor: Colors.grey[100],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.accentStrong,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${(goal.progress * 100).toStringAsFixed(0)}%",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'flight':
        return Icons.flight;
      case 'phone':
        return Icons.smartphone;
      case 'laptop':
        return Icons.laptop;
      case 'gift':
        return Icons.card_giftcard;
      case 'shopping':
        return Icons.shopping_bag;
      default:
        return Icons.star;
    }
  }
}
