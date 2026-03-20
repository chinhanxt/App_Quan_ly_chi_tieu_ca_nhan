import 'package:app/utils/icon_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CategoryDropdown extends StatelessWidget {
  CategoryDropdown({
    super.key,
    this.cattype,
    required this.onChanged,
  });

  final String? cattype;
  final ValueChanged<String?> onChanged;
  final appIcons = AppIcons();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      // Lấy danh mục từ Admin
      stream: FirebaseFirestore.instance.collection('categories').orderBy('createdAt').snapshots(),
      builder: (context, globalSnapshot) {
        return StreamBuilder<DocumentSnapshot>(
          // Lấy danh mục riêng của User
          stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (!globalSnapshot.hasData) return const LinearProgressIndicator();

            // 1. Danh mục từ Admin
            List<Map<String, dynamic>> allCategories = globalSnapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return {
                'name': data['name'],
                'icon': appIcons.getIconData(data['iconName'] ?? ""),
              };
            }).toList();

            // 2. Nếu Admin chưa tạo gì (hiếm khi xảy ra), dùng mặc định trong code
            if (allCategories.isEmpty) {
              allCategories = appIcons.defaultCategories;
            }

            // 3. Thêm danh mục riêng của User
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final data = userSnapshot.data!.data() as Map<String, dynamic>?;
              final customCategories = data?['customCategories'] as List<dynamic>? ?? [];
              for (var cat in customCategories) {
                allCategories.add({
                  'name': cat['name'],
                  'icon': appIcons.getIconData(cat['iconName'] ?? ""),
                });
              }
            }

            // Đảm bảo giá trị chọn hiện tại hợp lệ
            String? currentValue = cattype;
            if (currentValue == null || !allCategories.any((e) => e['name'] == currentValue)) {
              currentValue = allCategories.first['name'];
            }

            return DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              hint: const Text("Chọn danh mục"),
              items: allCategories.map((e) => DropdownMenuItem<String>(
                value: e['name'],
                child: Row(
                  children: [
                    Icon(e['icon'], color: Colors.black54),
                    const SizedBox(width: 10),
                    Text(e['name'], style: const TextStyle(color: Colors.black45)),
                  ],
                ),
              )).toList(),
              onChanged: onChanged,
            );
          },
        );
      },
    );
  }
}
