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
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Thêm Danh Mục",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Tên Danh Mục',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Chọn Icon",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 10),
              Container(
                height: 250,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: appIcons.suggestedCategories.length,
                  itemBuilder: (context, index) {
                    var category = appIcons.suggestedCategories[index];
                    bool isSelected = selectedIcon['name'] == category['name'];

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
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              category['icon'],
                              size: 28,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                            SizedBox(height: 5),
                            Text(
                              category['name'],
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
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Hủy"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty) {
                        widget.onCategoryAdded(
                          nameController.text,
                          selectedIcon['icon'],
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Vui lòng nhập tên danh mục")),
                        );
                      }
                    },
                    child: Text("Thêm"),
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
