import 'package:app/services/db.dart';
import 'package:app/utils/appvalidator.dart';
import 'package:app/utils/icon_list.dart';
import 'package:app/widgets/add_category_dialog.dart';
import 'package:app/widgets/category_dropdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class EditTransactionsForm extends StatefulWidget {
  final dynamic transactionData;
  final String transactionId;

  const EditTransactionsForm({
    super.key,
    required this.transactionData,
    required this.transactionId,
  });

  @override
  State<EditTransactionsForm> createState() => _EditTransactionsFormState();
}

class _EditTransactionsFormState extends State<EditTransactionsForm> {
  late String type;
  String? category;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  var isLoader = false;
  var appvalidator = Appvalidator();
  late TextEditingController amountEditController;
  late TextEditingController titleEditController;
  late TextEditingController dateController;
  late DateTime _selectedDate;

  var db = Db();
  final appIcons = AppIcons();

  @override
  void initState() {
    super.initState();
    titleEditController = TextEditingController(text: widget.transactionData['title']);
    amountEditController = TextEditingController(text: widget.transactionData['amount'].toString());
    type = widget.transactionData['type'];
    category = widget.transactionData['category'];

    int timestamp = widget.transactionData['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
    _selectedDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(_selectedDate));
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: now,
      locale: const Locale('vi', 'VN'),
      helpText: 'CHỌN NGÀY GIAO DỊCH',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
          _selectedDate.second,
        );
        dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      });
    }
  }

  Future<void> _addNewCategory(String categoryName, IconData icon) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final categoryFromList = appIcons.suggestedCategories.firstWhere((c) => c['icon'] == icon, orElse: () => {});
      if (categoryFromList.isEmpty) return;

      final newCategory = {'name': categoryName, 'iconName': categoryFromList['name']};
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'customCategories': FieldValue.arrayUnion([newCategory]),
      });

      setState(() {
        category = categoryName;
      });
    } catch (e) {
      print("Lỗi thêm danh mục: $e");
    }
  }

  @override
  void dispose() {
    titleEditController.dispose();
    amountEditController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoader = true;
      });

      int newAmount = int.parse(amountEditController.text);
      int newTimestamp = _selectedDate.millisecondsSinceEpoch;
      String newMonthYear = "${_selectedDate.month} ${_selectedDate.year}";

      var newData = {
        "title": titleEditController.text,
        "amount": newAmount,
        "type": type,
        "category": category,
        "timestamp": newTimestamp,
        "monthyear": newMonthYear,
      };

      bool success = await db.updateTransaction(
        widget.transactionId,
        widget.transactionData,
        newData,
      );

      if (success && mounted) {
        Navigator.pop(context);
      }

      setState(() {
        isLoader = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: titleEditController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: appvalidator.isEmptyCheck,
              decoration: const InputDecoration(labelText: 'Tiêu Đề'),
            ),
            TextFormField(
              controller: amountEditController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: appvalidator.isEmptyCheck,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Số Lượng (VND)'),
            ),
            TextFormField(
              controller: dateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: const InputDecoration(
                labelText: 'Ngày giao dịch',
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CategoryDropdown(
                    cattype: category,
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          category = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddCategoryDialog(
                        onCategoryAdded: (categoryName, icon) {
                          _addNewCategory(categoryName, icon);
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm'),
                ),
              ],
            ),
            DropdownButtonFormField(
              value: type,
              items: const [
                DropdownMenuItem(value: 'credit', child: Text('Thu Nhập')),
                DropdownMenuItem(value: 'debit', child: Text('Chi Tiêu')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    type = value as String;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (isLoader == false) {
                  _submitForm();
                }
              },
              child: isLoader
                  ? const CircularProgressIndicator()
                  : const Text('Cập Nhật Giao Dịch'),
            ),
          ],
        ),
      ),
    );
  }
}
