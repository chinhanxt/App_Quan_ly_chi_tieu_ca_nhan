import 'package:app/utils/app_colors.dart';
import 'package:app/utils/icon_list.dart';
import 'package:app/widgets/app_chrome.dart';
import 'package:app/widgets/custom_alert_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class _ManagedCategory {
  const _ManagedCategory({
    required this.name,
    required this.icon,
    required this.firestoreData,
  });

  final String name;
  final IconData icon;
  final Map<String, dynamic> firestoreData;
}

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _user = FirebaseAuth.instance.currentUser;
  final _appIcons = AppIcons();
  final _nameController = TextEditingController();

  List<_ManagedCategory> _customCategories = <_ManagedCategory>[];
  IconData? _selectedIcon;
  int? _editingIndex;
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isEditing => _editingIndex != null;

  @override
  void initState() {
    super.initState();
    _selectedIcon = _appIcons.suggestedCategories.first['icon'] as IconData;
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (_user == null) {
      if (!mounted) return;
      setState(() {
        _customCategories = <_ManagedCategory>[];
        _isLoading = false;
      });
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .get();

    if (!mounted) return;

    final categories =
        userDoc.data()?['customCategories'] as List<dynamic>? ?? <dynamic>[];

    setState(() {
      _customCategories = categories
          .whereType<Map>()
          .map((cat) => Map<String, dynamic>.from(cat))
          .map((cat) {
            final iconName = cat['iconName']?.toString() ?? '';
            return _ManagedCategory(
              name: cat['name']?.toString() ?? '',
              icon: _appIcons.getIconData(iconName),
              firestoreData: cat,
            );
          })
          .where((cat) => cat.name.trim().isNotEmpty)
          .toList(growable: false);
      _isLoading = false;
    });
  }

  void _startCreate() {
    setState(() {
      _editingIndex = null;
      _nameController.clear();
      _selectedIcon = _appIcons.suggestedCategories.first['icon'] as IconData;
    });
  }

  void _startEdit(int index) {
    final category = _customCategories[index];
    setState(() {
      _editingIndex = index;
      _nameController.text = category.name;
      _selectedIcon = category.icon;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingIndex = null;
      _nameController.clear();
      _selectedIcon = _appIcons.suggestedCategories.first['icon'] as IconData;
    });
  }

  Map<String, dynamic>? _buildCategoryPayload(
    String categoryName,
    IconData icon,
  ) {
    final normalizedName = categoryName.trim();
    if (normalizedName.isEmpty) return null;

    final categoryFromList = _appIcons.suggestedCategories.firstWhere(
      (c) => c['icon'] == icon,
      orElse: () => <String, dynamic>{},
    );

    if (categoryFromList.isEmpty) return null;

    return <String, dynamic>{
      'name': normalizedName,
      'iconName': categoryFromList['name'],
    };
  }

  bool _hasDuplicateName(String categoryName, {int? excludingIndex}) {
    final normalized = categoryName.trim().toLowerCase();
    return _customCategories.asMap().entries.any((entry) {
      if (excludingIndex != null && entry.key == excludingIndex) return false;
      return entry.value.name.trim().toLowerCase() == normalized;
    });
  }

  Future<void> _saveCategory() async {
    if (_user == null || _selectedIcon == null || _isSaving) return;

    final trimmedName = _nameController.text.trim();
    final wasEditing = _isEditing;
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên danh mục')),
      );
      return;
    }

    final payload = _buildCategoryPayload(trimmedName, _selectedIcon!);
    if (payload == null) return;

    final duplicate = _hasDuplicateName(
      trimmedName,
      excludingIndex: _editingIndex,
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Tên danh mục bị trùng' : 'Danh mục này đã tồn tại',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid);

      if (_isEditing) {
        final oldCategory = _customCategories[_editingIndex!].firestoreData;
        final batch = FirebaseFirestore.instance.batch();
        batch.set(userRef, {
          'customCategories': FieldValue.arrayRemove(<Map<String, dynamic>>[
            oldCategory,
          ]),
        }, SetOptions(merge: true));
        batch.set(userRef, {
          'customCategories': FieldValue.arrayUnion(<Map<String, dynamic>>[
            payload,
          ]),
        }, SetOptions(merge: true));
        await batch.commit();
      } else {
        await userRef.set({
          'customCategories': FieldValue.arrayUnion(<Map<String, dynamic>>[
            payload,
          ]),
        }, SetOptions(merge: true));
      }

      await _loadCategories();
      if (!mounted) return;
      _cancelEditing();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasEditing
                ? 'Đã cập nhật danh mục thành công'
                : 'Đã thêm danh mục thành công',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<bool> _checkCategoryUsage(String categoryName) async {
    if (_user == null) return false;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('transactions')
        .where('category', isEqualTo: categoryName.trim())
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  Future<void> _deleteCategory(int index) async {
    if (_user == null) return;

    final category = _customCategories[index];
    final hasTransactions = await _checkCategoryUsage(category.name);

    if (hasTransactions) {
      if (!mounted) return;
      CustomAlertDialog.show(
        context: context,
        title: 'Không Thể Xóa',
        message:
            'Danh mục "${category.name}" đang được sử dụng trong giao dịch. Hãy đổi hoặc xóa giao dịch liên quan trước.',
        type: AlertType.error,
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác Nhận Xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa danh mục "${category.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await FirebaseFirestore.instance.collection('users').doc(_user.uid).set({
      'customCategories': FieldValue.arrayRemove(<Map<String, dynamic>>[
        category.firestoreData,
      ]),
    }, SetOptions(merge: true));

    await _loadCategories();
    if (!mounted) return;

    if (_editingIndex == index) {
      _cancelEditing();
    } else if (_editingIndex != null && _editingIndex! > index) {
      setState(() {
        _editingIndex = _editingIndex! - 1;
      });
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa danh mục')));
  }

  Widget _buildEditorPanel() {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(
            title: _isEditing ? 'Sửa Danh Mục' : 'Thêm Danh Mục',
            subtitle:
                'Chỉnh sửa trực tiếp trên màn hình để tránh lỗi popup lồng nhau.',
            action: TextButton.icon(
              onPressed: _cancelEditing,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Tạo mới'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveCategory(),
            decoration: const InputDecoration(
              labelText: 'Tên danh mục',
              hintText: 'Ví dụ: Giải trí',
              prefixIcon: Icon(Icons.edit_outlined),
              fillColor: Color(0xFFFFF9F1),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chọn icon',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 64,
            ),
            itemCount: _appIcons.suggestedCategories.length,
            itemBuilder: (context, index) {
              final item = _appIcons.suggestedCategories[index];
              final icon = item['icon'] as IconData;
              final isSelected = _selectedIcon == icon;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _selectedIcon = icon;
                  });
                },
                child: Ink(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.10),
                      width: isSelected ? 1.6 : 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _cancelEditing,
                  child: const Text('Làm lại'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCategory,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Lưu cập nhật' : 'Thêm danh mục'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_customCategories.isEmpty) {
      return const AppEmptyState(
        icon: Icons.category_outlined,
        title: 'Chưa có danh mục tùy chỉnh',
        message:
            'Bạn có thể tạo danh mục riêng để dùng trong lúc thêm giao dịch.',
      );
    }

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(
            title: 'Danh Sách Hiện Tại',
            subtitle: 'Sửa hoặc xóa trực tiếp từng danh mục của riêng bạn.',
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _customCategories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final category = _customCategories[index];
              final isEditingThisItem = _editingIndex == index;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isEditingThisItem
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isEditingThisItem
                        ? AppColors.primary.withValues(alpha: 0.28)
                        : AppColors.primary.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: FaIcon(
                          category.icon,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEditingThisItem
                                ? 'Đang chỉnh sửa'
                                : 'Danh mục tùy chỉnh của bạn',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _startEdit(index),
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    ),
                    IconButton(
                      onPressed: () => _deleteCategory(index),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Quản lý danh mục')),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const AppHeroHeader(
            title: 'Danh Mục Tùy Chỉnh',
            subtitle:
                'Quản lý danh mục riêng của bạn trên một màn hình độc lập, không dùng popup nữa.',
          ),
          const SizedBox(height: 16),
          _buildEditorPanel(),
          const SizedBox(height: 16),
          _buildCategoryList(),
        ],
      ),
    );
  }
}
