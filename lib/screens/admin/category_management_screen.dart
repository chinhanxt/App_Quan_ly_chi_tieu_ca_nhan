import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/icon_list.dart';
import '../../widgets/responsive_layout.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final CollectionReference _globalCategories = FirebaseFirestore.instance.collection('categories');
  final appIcons = AppIcons();

  Future<void> _initializeDefaultCategories() async {
    var snapshot = await _globalCategories.get();
    if (snapshot.docs.isEmpty) {
      for (var cat in appIcons.defaultCategories) {
        await _globalCategories.add({
          'name': cat['name'],
          'type': cat['name'] == 'Lương' ? 'credit' : 'debit',
          'iconName': cat['iconName'],
          'isDefault': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeDefaultCategories();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildBody(context),
      desktopBody: AdminWebLayout(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      appBar: isDesktop ? null : AppBar(
        title: const Text("Quản lý danh mục hệ thống"),
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        backgroundColor: Colors.purple[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _globalCategories.orderBy('createdAt', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Chưa có danh mục hệ thống nào.\nHãy thêm danh mục mới."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var category = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String docId = snapshot.data!.docs[index].id;
              String name = category['name'] ?? "Không tên";
              String type = category['type'] ?? "debit";
              String iconName = category['iconName'] ?? "cartShopping";

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: type == 'credit' ? Colors.green[50] : Colors.red[50],
                    child: FaIcon(
                      appIcons.getIconData(iconName),
                      color: type == 'credit' ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(
                    type == 'credit' ? "Thu nhập" : "Chi tiêu",
                    style: TextStyle(color: type == 'credit' ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.w500),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => _showCategoryDialog(context, docId: docId, categoryData: category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteCategory(docId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, {String? docId, Map<String, dynamic>? categoryData}) {
    final nameController = TextEditingController(text: categoryData?['name'] ?? "");
    String selectedType = categoryData?['type'] ?? 'debit';
    String selectedIconName = categoryData?['iconName'] ?? appIcons.suggestedCategories[0]['iconName'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(docId == null ? "Thêm danh mục" : "Sửa danh mục"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: "Tên danh mục", hintText: 'Ví dụ: Ăn uống'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: "Loại"),
                        items: const [
                          DropdownMenuItem(value: 'debit', child: Text("Chi tiêu")),
                          DropdownMenuItem(value: 'credit', child: Text("Thu nhập")),
                        ],
                        onChanged: (value) => setDialogState(() => selectedType = value!),
                      ),
                      const SizedBox(height: 16),
                      const Text("Chọn Icon:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: appIcons.suggestedCategories.length,
                          itemBuilder: (context, index) {
                            var item = appIcons.suggestedCategories[index];
                            bool isSelected = selectedIconName == item['iconName'];
                            return GestureDetector(
                              onTap: () => setDialogState(() => selectedIconName = item['iconName']),
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
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    
                    final data = {
                      'name': nameController.text,
                      'type': selectedType,
                      'iconName': selectedIconName,
                      'isDefault': true,
                      'updatedAt': FieldValue.serverTimestamp(),
                      if (docId == null) 'createdAt': FieldValue.serverTimestamp(),
                    };

                    if (docId == null) {
                      await _globalCategories.add(data);
                    } else {
                      await _globalCategories.doc(docId).update(data);
                    }
                    
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text("Lưu"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCategory(String docId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa danh mục hệ thống này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(
            onPressed: () async {
              await _globalCategories.doc(docId).delete();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
