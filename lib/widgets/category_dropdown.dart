import 'package:app/utils/app_colors.dart';
import 'package:app/utils/icon_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class CategoryDropdown extends StatefulWidget {
  const CategoryDropdown({
    super.key,
    this.cattype,
    required this.onChanged,
  });

  final String? cattype;
  final ValueChanged<String?> onChanged;

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  final AppIcons _appIcons = AppIcons();
  String? _lastAutoResolvedValue;

  void _syncResolvedValue(String? resolvedValue) {
    if (resolvedValue == null) return;

    if (widget.cattype == resolvedValue) {
      _lastAutoResolvedValue = null;
      return;
    }

    if (_lastAutoResolvedValue == resolvedValue) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _lastAutoResolvedValue = resolvedValue;
      widget.onChanged(resolvedValue);
    });
  }

  List<Map<String, dynamic>> _buildCategories(
    QuerySnapshot<Object?> globalSnapshot,
    DocumentSnapshot<Object?>? userSnapshot,
  ) {
    final categoriesByName = <String, Map<String, dynamic>>{};

    for (final doc in globalSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name']?.toString().trim();
      if (name == null || name.isEmpty) continue;

      categoriesByName[name] = {
        'name': name,
        'icon': _appIcons.getIconData(data['iconName']?.toString() ?? ''),
      };
    }

    if (categoriesByName.isEmpty) {
      for (final category in _appIcons.defaultCategories) {
        final name = category['name']?.toString().trim();
        if (name == null || name.isEmpty) continue;
        categoriesByName[name] = category;
      }
    }

    if (userSnapshot != null && userSnapshot.exists) {
      final data = userSnapshot.data() as Map<String, dynamic>?;
      final customCategories = data?['customCategories'] as List<dynamic>? ?? [];

      for (final cat in customCategories.whereType<Map>()) {
        final name = cat['name']?.toString().trim();
        if (name == null || name.isEmpty) continue;

        categoriesByName[name] = {
          'name': name,
          'icon': _appIcons.getIconData(cat['iconName']?.toString() ?? ''),
        };
      }
    }

    return categoriesByName.values.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return DropdownButtonFormField<String>(
        items: const [],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: 'Danh mục',
          prefixIcon: Icon(Icons.category_outlined),
          fillColor: Color(0xFFFFF9F1),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return DropdownButtonFormField<String>(
        items: const [],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: 'Danh mục',
          prefixIcon: Icon(Icons.category_outlined),
          fillColor: Color(0xFFFFF9F1),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, globalSnapshot) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (globalSnapshot.connectionState == ConnectionState.waiting &&
                !globalSnapshot.hasData) {
              return const LinearProgressIndicator();
            }

            if (globalSnapshot.hasError || userSnapshot.hasError) {
              return DropdownButtonFormField<String>(
                items: const [],
                onChanged: null,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  prefixIcon: Icon(Icons.category_outlined),
                  errorText: 'Không tải được danh mục',
                  fillColor: Color(0xFFFFF9F1),
                ),
              );
            }

            final allCategories = _buildCategories(
              globalSnapshot.data!,
              userSnapshot.data,
            );

            final requestedValue = widget.cattype?.trim();
            final availableNames = allCategories
                .map((category) => category['name'] as String)
                .toSet();

            String? resolvedValue = requestedValue;
            if (resolvedValue == null || !availableNames.contains(resolvedValue)) {
              resolvedValue = allCategories.isNotEmpty
                  ? allCategories.first['name'] as String
                  : null;
            }

            _syncResolvedValue(resolvedValue);

            return DropdownButtonFormField<String>(
              key: ValueKey(resolvedValue ?? 'empty-category'),
              initialValue: resolvedValue,
              isExpanded: true,
              menuMaxHeight: 320,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              dropdownColor: const Color(0xFFFFF9F1),
              decoration: const InputDecoration(
                labelText: 'Danh mục',
                prefixIcon: Icon(Icons.category_outlined),
                fillColor: Color(0xFFFFF9F1),
              ),
              items: allCategories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category['name'] as String,
                      child: Row(
                        children: [
                          Icon(category['icon'] as IconData, color: Colors.black54),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              category['name'] as String,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: allCategories.isEmpty ? null : widget.onChanged,
            );
          },
        );
      },
    );
  }
}
