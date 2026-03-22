import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/admin_web/admin_web_widgets.dart';
import 'package:app/utils/icon_list.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key, required this.repository});

  final AdminWebRepository repository;

  Future<void> _seedDefaultCategories(BuildContext context, AppIcons icons) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khởi tạo danh mục'),
        content: const Text('Hệ thống sẽ tự động thêm 5 danh mục mặc định (Lương, Ăn uống, Di chuyển...) vào danh sách. Tiếp tục?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Khởi tạo ngay')),
        ],
      ),
    );

    if (confirmed == true) {
      // Danh sách 5 mục mặc định chuẩn
      final defaults = [
        {"name": "Lương", "type": "credit", "iconName": "moneyBillWave"},
        {"name": "Ăn uống", "type": "debit", "iconName": "utensils"},
        {"name": "Di chuyển", "type": "debit", "iconName": "car"},
        {"name": "Mua sắm", "type": "debit", "iconName": "cartShopping"},
        {"name": "Tiết kiệm", "type": "debit", "iconName": "piggyBank"},
      ];

      for (var cat in defaults) {
        await repository.saveCategory(
          name: cat['name']!,
          type: cat['type']!,
          iconName: cat['iconName']!,
        );
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã khởi tạo xong 5 danh mục mặc định!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final icons = AppIcons();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Quản lý danh mục hệ thống',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _seedDefaultCategories(context, icons),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Nạp mục mặc định'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _showCategoryDialog(context, icons: icons),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm danh mục'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: AdminPanel(
            child: StreamBuilder<List<CategoryRecord>>(
              stream: repository.watchCategories(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final categories = snapshot.data!;
                
                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có danh mục nào.\nHãy nhấn "Nạp mục mặc định" để bắt đầu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final item = categories[index];
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: item.type == 'credit'
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          child: FaIcon(
                            icons.getIconData(item.iconName),
                            color: item.type == 'credit'
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          item.type == 'credit' ? 'Thu nhập' : 'Chi tiêu',
                          style: TextStyle(
                            color: item.type == 'credit' ? Colors.green : Colors.orange.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                              onPressed: () => _showCategoryDialog(
                                context,
                                record: item,
                                icons: icons,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Xác nhận xóa'),
                                    content: Text('Bạn có chắc muốn xóa danh mục "${item.name}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await repository.deleteCategory(item.id);
                                }
                              },
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
        ),
      ],
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context, {
    CategoryRecord? record,
    required AppIcons icons,
  }) async {
    final nameController = TextEditingController(text: record?.name ?? '');
    var type = record?.type ?? 'debit';
    var iconName = record?.iconName ?? icons.defaultCategories.first['iconName'];

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(record == null ? 'Thêm danh mục' : 'Sửa danh mục'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên danh mục',
                          hintText: 'Ví dụ: Ăn sáng, Tiền điện...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: type,
                        decoration: const InputDecoration(
                          labelText: 'Loại',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'debit', child: Text('Chi tiêu (Debit)')),
                          DropdownMenuItem(value: 'credit', child: Text('Thu nhập (Credit)')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              type = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Chọn biểu tượng:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 250,
                        child: GridView.builder(
                          itemCount: icons.suggestedCategories.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                              ),
                          itemBuilder: (context, index) {
                            final item = icons.suggestedCategories[index];
                            final selected = item['iconName'] == iconName;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    iconName = item['iconName'] as String;
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF6366F1)
                                          : const Color(0xFFE2E8F0),
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    color: selected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                                    size: 20,
                                  ),
                                ),
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
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    await repository.saveCategory(
                      id: record?.id,
                      name: nameController.text.trim(),
                      type: type,
                      iconName: iconName,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
