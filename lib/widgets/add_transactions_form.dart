import 'package:app/screens/saving_goals_screen.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/appvalidator.dart';
import 'package:app/utils/icon_list.dart';
import 'package:app/utils/ocr_helper.dart';
import 'package:app/widgets/add_category_dialog.dart';
import 'package:app/widgets/category_dropdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddTransactionsForm extends StatefulWidget {
  const AddTransactionsForm({super.key});

  @override
  State<AddTransactionsForm> createState() => _AddTransactionsFormState();
}

class _AddTransactionsFormState extends State<AddTransactionsForm> {
  var type = "credit";
  String?
  category; // Bắt đầu bằng null để CategoryDropdown tự chọn cái đầu tiên
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  var isLoader = false;
  var appvalidator = Appvalidator();
  var amountEditController = TextEditingController();
  var titleEditController = TextEditingController();
  var noteEditController = TextEditingController();

  var dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  var uid = Uuid();
  final appIcons = AppIcons();

  @override
  void initState() {
    super.initState();
    dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    amountEditController.dispose();
    titleEditController.dispose();
    noteEditController.dispose();
    dateController.dispose();
    super.dispose();
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      });
    }
  }

  Future<void> _scanBill(ImageSource source) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                const Text("Đang phân tích..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final result = await OcrHelper.scanImage(source);
      if (!mounted) return;
      Navigator.pop(context);

      if (result.isNotEmpty) {
        setState(() {
          titleEditController.text =
              result['title'] ?? titleEditController.text;
          amountEditController.text =
              result['amount'] ?? amountEditController.text;
          noteEditController.text = result['note'] ?? noteEditController.text;
          if (result['date'] != null) {
            try {
              DateTime scannedDate = DateFormat(
                'dd/MM/yyyy',
              ).parse(result['date']!);
              final now = DateTime.now();
              if (scannedDate.isAfter(now)) {
                scannedDate = now;
              }
              _selectedDate = scannedDate;
              dateController.text = DateFormat(
                'dd/MM/yyyy',
              ).format(_selectedDate);
            } catch (e) {
              // ignore
            }
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không đọc được chữ từ ảnh.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  Future<void> _addNewCategory(String categoryName, IconData icon) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final categoryFromList = appIcons.suggestedCategories.firstWhere(
        (c) => c['icon'] == icon,
        orElse: () => {},
      );

      if (categoryFromList.isEmpty) return;

      final newCategory = {
        'name': categoryName,
        'iconName': categoryFromList['name'],
      };

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'customCategories': FieldValue.arrayUnion([newCategory]),
        },
      );

      setState(() {
        category = categoryName;
      });
    } catch (e) {
      debugPrint("Lỗi: $e");
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (category == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Vui lòng chọn danh mục")));
        return;
      }

      setState(() {
        isLoader = true;
      });
      final user = FirebaseAuth.instance.currentUser;

      int timestamp = _selectedDate.millisecondsSinceEpoch;
      String monthyear = "${_selectedDate.month} ${_selectedDate.year}";

      var amount = int.parse(amountEditController.text);
      var id = uid.v4();

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      int remainingAmount = userDoc['remainingAmount'];
      int totalCredit = userDoc['totalCredit'];
      int totalDebit = userDoc['totalDebit'];

      if (type == 'credit') {
        remainingAmount += amount;
        totalCredit += amount;
      } else {
        remainingAmount -= amount;
        totalDebit -= amount;
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            "remainingAmount": remainingAmount,
            "totalCredit": totalCredit,
            "totalDebit": totalDebit,
            "updatedAt": DateTime.now().millisecondsSinceEpoch,
          });

      var data = {
        "id": id,
        "title": titleEditController.text,
        "amount": amount,
        "type": type,
        "timestamp": timestamp,
        "totalCredit": totalCredit,
        "totalDebit": totalDebit,
        "remainingAmount": remainingAmount,
        "monthyear": monthyear,
        "category": category,
        "note": noteEditController.text,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection("transactions")
          .doc(id)
          .set(data);

      if (mounted) {
        Navigator.pop(context);
      }

      setState(() {
        isLoader = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        width: screen.width > 560 ? 520 : screen.width - 32,
        constraints: BoxConstraints(maxHeight: screen.height * 0.82),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color:
              Theme.of(context).dialogTheme.backgroundColor ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Thêm giao dịch",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Nhập nhanh thu chi hoặc quét hóa đơn.",
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _scanBill(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text(
                          "Chụp Ảnh",
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _scanBill(ImageSource.gallery),
                        icon: const Icon(Icons.image, size: 18),
                        label: const Text(
                          "Chọn Ảnh",
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: AppColors.accentStrong,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Số tiền (VND)'),
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
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
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
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Loại giao dịch',
                    prefixIcon: Icon(Icons.sync_alt_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'credit', child: Text('Thu Nhập')),
                    DropdownMenuItem(value: 'debit', child: Text('Chi Tiêu')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        type = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteEditController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ghi Chú',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavingGoalsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.savings_outlined),
                  label: const Text("Góp Tiết Kiệm"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentStrong,
                    side: const BorderSide(color: AppColors.accentStrong),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (isLoader == false) {
                      _submitForm();
                    }
                  },
                  child: isLoader
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text("Thêm Giao Dịch"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
