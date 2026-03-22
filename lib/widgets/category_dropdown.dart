import 'package:app/utils/icon_list.dart';
import 'package:app/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CategoryDropdown extends StatelessWidget {
  CategoryDropdown({super.key, this.cattype, required this.onChanged});

  final String? cattype;
  final ValueChanged<String?> onChanged;
  final appIcons = AppIcons();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, globalSnapshot) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (!globalSnapshot.hasData) return const LinearProgressIndicator();

            List<Map<String, dynamic>> allCategories = globalSnapshot.data!.docs
                .map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return {
                    'name': data['name'],
                    'icon': appIcons.getIconData(data['iconName'] ?? ""),
                  };
                })
                .toList();

            if (allCategories.isEmpty) {
              allCategories = appIcons.defaultCategories;
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final data = userSnapshot.data!.data() as Map<String, dynamic>?;
              final customCategories =
                  data?['customCategories'] as List<dynamic>? ?? [];
              for (var cat in customCategories) {
                allCategories.add({
                  'name': cat['name'],
                  'icon': appIcons.getIconData(cat['iconName'] ?? ""),
                });
              }
            }

            String? currentValue = cattype;
            if (currentValue == null ||
                !allCategories.any((e) => e['name'] == currentValue)) {
              currentValue = allCategories.first['name'];
            }

            return DropdownButtonFormField<String>(
              initialValue: currentValue,
              isExpanded: true,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              dropdownColor: const Color(0xFFFFF9F1),
              decoration: const InputDecoration(
                labelText: "Danh mục",
                prefixIcon: Icon(Icons.category_outlined),
                fillColor: Color(0xFFFFF9F1),
              ),
              items: allCategories
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e['name'],
                      child: Row(
                        children: [
                          Icon(e['icon'], color: Colors.black54),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              e['name'],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            );
          },
        );
      },
    );
  }
}
