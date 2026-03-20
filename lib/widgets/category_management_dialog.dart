import 'package:app/utils/icon_list.dart';
import 'package:app/widgets/add_category_dialog.dart';
import 'package:app/widgets/custom_alert_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CategoryManagementDialog extends StatefulWidget {
  final VoidCallback onCategoryChanged;

  const CategoryManagementDialog({
    super.key,
    required this.onCategoryChanged,
  });

  @override
  State<CategoryManagementDialog> createState() => _CategoryManagementDialogState();
}

class _CategoryManagementDialogState extends State<CategoryManagementDialog> {
  final user = FirebaseAuth.instance.currentUser;
  final appIcons = AppIcons();
  List<Map<String, dynamic>> customCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (userDoc.exists) {
      final categories = userDoc.data()?['customCategories'] as List<dynamic>? ?? [];

      setState(() {
        customCategories = categories.map((cat) {
          final iconName = cat['iconName'];
          final iconData = appIcons.getExpenseCategoryIcons(iconName);
          return {
            'name': cat['name'],
            'iconName': cat['iconName'],
            'icon': iconData,
          };
        }).toList();
      });
    }
  }

  Future<void> _addCategory() async {
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(
        onCategoryAdded: (categoryName, icon) async {
          await _saveCategoryToFirestore(categoryName, icon);
          await _loadCategories();
          widget.onCategoryChanged();
        },
      ),
    );
  }

  Future<void> _editCategory(int index) async {
    final category = customCategories[index];
    final nameController = TextEditingController(text: category['name']);

    showDialog(
      context: context,
      builder: (context) => EditCategoryDialog(
        nameController: nameController,
        initialIcon: category['icon'],
        onSave: (newName, newIcon) async {
          await _updateCategoryInFirestore(index, newName, newIcon);
          await _loadCategories();
          widget.onCategoryChanged();
        },
      ),
    );
  }

  Future<void> _deleteCategory(int index) async {
    final category = customCategories[index];

    // Check if category is being used in transactions
    final hasTransactions = await _checkCategoryUsage(category['name']);

    if (hasTransactions) {
      CustomAlertDialog.show(
        context: context,
        title: 'Không Thể Xóa',
        message: 'Danh mục "${category['name']}" đang được sử dụng trong các giao dịch. Vui lòng xóa hoặc thay đổi danh mục của các giao dịch trước khi xóa danh mục này.',
        type: AlertType.error,
      );
      return;
    }

    CustomAlertDialog.show(
      context: context,
      title: 'Xác Nhận Xóa',
      message: 'Bạn có chắc chắn muốn xóa danh mục "${category['name']}"?',
      type: AlertType.warning,
      onConfirm: () async {
        await _deleteCategoryFromFirestore(index);
        await _loadCategories();
        widget.onCategoryChanged();
      },
    );
  }

  Future<bool> _checkCategoryUsage(String categoryName) async {
    if (user == null) return false;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('transactions')
        .where('category', isEqualTo: categoryName)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  Future<void> _saveCategoryToFirestore(String categoryName, IconData icon) async {
    if (user == null) return;

    final categoryFromList = appIcons.suggestedCategories
        .firstWhere((c) => c['icon'] == icon, orElse: () => {});

    if (categoryFromList.isEmpty) return;

    final newCategory = {
      'name': categoryName,
      'iconName': categoryFromList['name'],
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .set({
          'customCategories': FieldValue.arrayUnion([newCategory]),
        }, SetOptions(merge: true));
  }

  Future<void> _updateCategoryInFirestore(int index, String newName, IconData newIcon) async {
    if (user == null) return;

    final oldCategory = customCategories[index];
    final categoryFromList = appIcons.suggestedCategories
        .firstWhere((c) => c['icon'] == newIcon, orElse: () => {});

    if (categoryFromList.isEmpty) return;

    final updatedCategory = {
      'name': newName,
      'iconName': categoryFromList['name'],
    };

    // Remove old category and add new one
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .set({
          'customCategories': FieldValue.arrayRemove([oldCategory]),
        }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .set({
          'customCategories': FieldValue.arrayUnion([updatedCategory]),
        }, SetOptions(merge: true));
  }

  Future<void> _deleteCategoryFromFirestore(int index) async {
    if (user == null) return;

    final categoryToDelete = customCategories[index];

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .set({
          'customCategories': FieldValue.arrayRemove([categoryToDelete]),
        }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quản Lý Danh Mục',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Add button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add),
                label: const Text('Thêm Danh Mục Mới'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
            ),

            // Category list
            Expanded(
              child: customCategories.isEmpty
                  ? const Center(
                      child: Text('Chưa có danh mục tùy chỉnh'),
                    )
                  : ListView.builder(
                      itemCount: customCategories.length,
                      itemBuilder: (context, index) {
                        final category = customCategories[index];
                        return ListTile(
                          leading: FaIcon(
                            category['icon'],
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(category['name']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _editCategory(index),
                                icon: const Icon(Icons.edit, color: Colors.blue),
                              ),
                              IconButton(
                                onPressed: () => _deleteCategory(index),
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditCategoryDialog extends StatefulWidget {
  final TextEditingController nameController;
  final IconData initialIcon;
  final Function(String name, IconData icon) onSave;

  const EditCategoryDialog({
    super.key,
    required this.nameController,
    required this.initialIcon,
    required this.onSave,
  });

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  late IconData selectedIcon;
  final appIcons = AppIcons(); // Add AppIcons instance

  @override
  void initState() {
    super.initState();
    selectedIcon = widget.initialIcon;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Chỉnh Sửa Danh Mục",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: widget.nameController,
                decoration: InputDecoration(
                  labelText: 'Tên Danh Mục',
                  hintText: 'Ví dụ: Giải trí',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Chọn Icon:", // Change text
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 250, // Increased height for grid
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: appIcons.suggestedCategories.length,
                  itemBuilder: (context, index) {
                    var item = appIcons.suggestedCategories[index];
                    bool isSelected = selectedIcon == item['icon'];
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = item['icon']),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected ? Colors.blue[50] : null,
                        ),
                        child: Icon(item['icon'], color: isSelected ? Colors.blue : Colors.grey[600]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Hủy"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.nameController.text.isNotEmpty) {
                        widget.onSave(widget.nameController.text, selectedIcon);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Lưu"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}