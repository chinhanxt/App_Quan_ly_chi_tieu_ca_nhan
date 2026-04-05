import 'package:app/utils/icon_list.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddCategoryDialog extends StatefulWidget {
  final Function(String categoryName, IconData icon) onCategoryAdded;

  const AddCategoryDialog({super.key, required this.onCategoryAdded});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final TextEditingController nameController = TextEditingController();
  final appIcons = AppIcons();
  late Map<String, dynamic> selectedIcon;

  @override
  void initState() {
    super.initState();
    selectedIcon = appIcons.suggestedCategories[0];
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    return AlertDialog(
      title: const Text(
        'Thêm Danh Mục',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: screen.width > 560 ? 460 : screen.width * 0.9,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screen.height * 0.58),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Tên Danh Mục',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chọn Icon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: appIcons.suggestedCategories.length,
                  itemBuilder: (context, index) {
                    final category = appIcons.suggestedCategories[index];
                    final isSelected = selectedIcon['name'] == category['name'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIcon = category;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey,
                            width: isSelected ? 3 : 1,
                          ),
                          color: isSelected
                              ? Colors.blue.withValues(alpha: 0.1)
                              : Colors.transparent,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              category['icon'] as IconData,
                              size: 28,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              category['name'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.blue : Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng nhập tên danh mục')),
              );
              return;
            }

            widget.onCategoryAdded(
              nameController.text.trim(),
              selectedIcon['icon'] as IconData,
            );
            Navigator.pop(context);
          },
          child: const Text('Tạo'),
        ),
      ],
    );
  }
}
