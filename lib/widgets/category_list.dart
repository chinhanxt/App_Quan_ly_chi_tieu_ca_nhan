import 'package:app/utils/icon_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CategoryList extends StatefulWidget {
  const CategoryList({super.key, required this.onChanges});
  final ValueChanged<String?> onChanges;

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  String currentCategory = "Tất cả";
  List<Map<String, dynamic>> categoryList = [];

  final scrollController = ScrollController();
  final appIcons = AppIcons();
  final addCat = {"name": "Tất cả", "icon": FontAwesomeIcons.cartPlus};

  scrollToSelectedCategory() {
    final selectedCategoryIndex = categoryList.indexWhere(
      (cat) => cat['name'] == currentCategory,
    );
    if (selectedCategoryIndex != -1 && scrollController.hasClients) {
      final itemWidth = 140.0;
      final screenWidth = MediaQuery.sizeOf(context).width;
      final centerOffset = screenWidth / 2 - itemWidth / 2;
      final scrollOffset = selectedCategoryIndex * itemWidth - centerOffset;

      final maxScroll = scrollController.position.maxScrollExtent;
      final clampedOffset = scrollOffset.clamp(0.0, maxScroll);

      scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox(height: 55, child: Center(child: Text("Không có user")));
    }

    return SizedBox(
      height: 55,
      child: StreamBuilder<QuerySnapshot>(
        // Lấy danh mục hệ thống (mặc định cho tất cả user)
        stream: FirebaseFirestore.instance.collection('categories').orderBy('createdAt').snapshots(),
        builder: (context, globalSnapshot) {
          return StreamBuilder<DocumentSnapshot>(
            // Lấy danh mục riêng của user
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, userSnapshot) {
              if (globalSnapshot.hasError || userSnapshot.hasError) {
                return const Center(child: Text('Lỗi tải danh mục'));
              }

              if (globalSnapshot.connectionState == ConnectionState.waiting && categoryList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              List<Map<String, dynamic>> systemCategories = [];
              if (globalSnapshot.hasData) {
                systemCategories = globalSnapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return {
                    'name': data['name'],
                    'icon': appIcons.getIconData(data['iconName'] ?? ""),
                  };
                }).toList();
              }

              List<Map<String, dynamic>> loadedCustomCategories = [];
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                if (data != null) {
                  final customCategories = data['customCategories'] as List<dynamic>? ?? [];
                  for (var cat in customCategories) {
                    if (cat is Map<String, dynamic>) {
                      final iconName = cat['iconName'] as String?;
                      if (iconName != null) {
                        loadedCustomCategories.add({
                          'name': cat['name'] as String,
                          'icon': appIcons.getIconData(iconName),
                        });
                      }
                    }
                  }
                }
              }

              // Tổng hợp danh mục: Tất cả + Hệ thống (do Admin quản lý) + Custom (của riêng User)
              categoryList = [
                addCat,
                if (systemCategories.isEmpty) ...appIcons.defaultCategories else ...systemCategories,
                ...loadedCustomCategories,
              ];

              return ListView.builder(
                controller: scrollController,
                itemCount: categoryList.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  var data = categoryList[index];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        currentCategory = data['name'];
                        widget.onChanges(data['name']);
                      });
                      scrollToSelectedCategory();
                    },
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      decoration: BoxDecoration(
                        color: currentCategory == data['name']
                            ? Colors.green
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Row(
                          children: [
                            Icon(
                              data['icon'],
                              size: 15,
                              color: currentCategory == data['name']
                                  ? Colors.white
                                  : Colors.blue,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              data['name'],
                              style: TextStyle(
                                color: currentCategory == data['name']
                                    ? Colors.white
                                    : Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
