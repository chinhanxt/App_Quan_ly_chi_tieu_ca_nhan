import 'package:app/services/db.dart';
import 'package:app/services/transaction_summary_helper.dart';
import 'package:app/utils/app_colors.dart';
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

  bool isLoader = false;
  final Appvalidator appvalidator = Appvalidator();
  late TextEditingController amountEditController;
  late TextEditingController titleEditController;
  late TextEditingController noteEditController;
  late TextEditingController dateController;
  late DateTime _selectedDate;

  final AppIcons appIcons = AppIcons();

  @override
  void initState() {
    super.initState();
    titleEditController = TextEditingController(
      text: widget.transactionData['title'],
    );
    amountEditController = TextEditingController(
      text: TransactionSummaryHelper.normalizeAmount(
        widget.transactionData['amount'],
      ).toString(),
    );
    noteEditController = TextEditingController(
      text: widget.transactionData['note'] ?? '',
    );
    type = widget.transactionData['type'];
    category = widget.transactionData['category']?.toString();

    final timestamp =
        widget.transactionData['timestamp'] ??
        DateTime.now().millisecondsSinceEpoch;
    _selectedDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_selectedDate),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
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

      final newCategory = {
        'name': categoryName,
        'iconName': appIcons.getIconNameFromIcon(icon),
      };
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'customCategories': FieldValue.arrayUnion([newCategory]),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        category = categoryName;
      });
    } catch (e) {
      debugPrint('Lỗi thêm danh mục: $e');
    }
  }

  @override
  void dispose() {
    titleEditController.dispose();
    amountEditController.dispose();
    noteEditController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (category == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục')));
      return;
    }

    setState(() {
      isLoader = true;
    });

    final newAmount = int.parse(amountEditController.text);
    final newTimestamp = _selectedDate.millisecondsSinceEpoch;
    final newMonthYear = '${_selectedDate.month} ${_selectedDate.year}';

    final newData = {
      'title': titleEditController.text,
      'amount': newAmount,
      'type': type,
      'category': category,
      'timestamp': newTimestamp,
      'monthyear': newMonthYear,
      'note': noteEditController.text,
    };

    final success = await Db().updateTransaction(
      widget.transactionId,
      widget.transactionData,
      newData,
    );

    if (success && mounted) {
      Navigator.pop(context);
    }

    if (mounted) {
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
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Sửa giao dịch',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      tooltip: 'Đóng',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cập nhật thông tin giao dịch mà không làm gián đoạn việc chọn danh mục.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleEditController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: appvalidator.isEmptyCheck,
                  decoration: const InputDecoration(labelText: 'Tiêu đề'),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CategoryDropdown(
                        cattype: category,
                        onChanged: (String? value) {
                          if (value == null) return;
                          setState(() {
                            category = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog<void>(
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
                DropdownButtonFormField<String>(
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
                    if (value == null) return;
                    setState(() {
                      type = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteEditController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoader ? null : _submitForm,
                  child: isLoader
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text('Cập Nhật Giao Dịch'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
