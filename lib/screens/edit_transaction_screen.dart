import 'package:app/screens/saving_goals_screen.dart';
import 'package:app/services/db.dart';
import 'package:app/services/transaction_summary_helper.dart';
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

class EditTransactionScreen extends StatefulWidget {
  const EditTransactionScreen({
    super.key,
    required this.transactionId,
    required this.transactionData,
  });

  final String transactionId;
  final Map<String, dynamic> transactionData;

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Appvalidator _appvalidator = Appvalidator();
  final AppIcons _appIcons = AppIcons();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  late String _type;
  String? _category;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.transactionData['title']?.toString() ?? '';
    _amountController.text = TransactionSummaryHelper.normalizeAmount(
      widget.transactionData['amount'],
    ).toString();
    _noteController.text = widget.transactionData['note']?.toString() ?? '';
    _type = widget.transactionData['type']?.toString() ?? 'credit';
    _category = widget.transactionData['category']?.toString();

    final rawTimestamp = widget.transactionData['timestamp'];
    final timestamp = rawTimestamp is int
        ? rawTimestamp
        : int.tryParse(rawTimestamp?.toString() ?? '');
    _selectedDate = timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  TextStyle get _fieldTextStyle => const TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w600,
  );

  Future<void> _selectDate() async {
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
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      });
    }
  }

  Future<void> _scanBill(ImageSource source) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Đang phân tích...'),
            ],
          ),
        );
      },
    );

    try {
      final result = await OcrHelper.scanImage(source);
      if (!mounted) return;
      Navigator.pop(context);

      if (result.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không đọc được chữ từ ảnh.')),
        );
        return;
      }

      setState(() {
        _titleController.text = result['title'] ?? _titleController.text;
        _amountController.text = result['amount'] ?? _amountController.text;
        _noteController.text = result['note'] ?? _noteController.text;
        if (result['date'] != null) {
          try {
            var scannedDate = DateFormat('dd/MM/yyyy').parse(result['date']!);
            final now = DateTime.now();
            if (scannedDate.isAfter(now)) {
              scannedDate = now;
            }
            _selectedDate = scannedDate;
            _dateController.text = DateFormat(
              'dd/MM/yyyy',
            ).format(_selectedDate);
          } catch (_) {}
        }
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _addNewCategory(String categoryName, IconData icon) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final categoryFromList = _appIcons.suggestedCategories.firstWhere(
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

      if (!mounted) return;
      setState(() {
        _category = categoryName;
      });
    } catch (e) {
      debugPrint('Lỗi thêm danh mục: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_category == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final timestamp = _selectedDate.millisecondsSinceEpoch;
      final monthyear = '${_selectedDate.month} ${_selectedDate.year}';
      final amount = int.parse(_amountController.text);

      final data = {
        'title': _titleController.text,
        'amount': amount,
        'type': _type,
        'timestamp': timestamp,
        'monthyear': monthyear,
        'category': _category,
        'note': _noteController.text,
      };

      final success = await Db().updateTransaction(
        widget.transactionId,
        widget.transactionData,
        data,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật giao dịch thành công')),
        );
        Navigator.pop(context);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể cập nhật giao dịch')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi cập nhật giao dịch: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Sửa giao dịch'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Chỉnh sửa giao dịch',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Cập nhật khoản thu hoặc chi với cùng trải nghiệm như màn hình thêm giao dịch.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _scanBill(ImageSource.camera),
                              icon: const Icon(
                                Icons.camera_alt_rounded,
                                size: 18,
                              ),
                              label: const Text('Chụp ảnh'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _scanBill(ImageSource.gallery),
                              icon: const Icon(Icons.image_outlined, size: 18),
                              label: const Text('Chọn ảnh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentStrong,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        style: _fieldTextStyle,
                        cursorColor: AppColors.primary,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: _appvalidator.isEmptyCheck,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề',
                          fillColor: Color(0xFFFFF9F1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amountController,
                        style: _fieldTextStyle,
                        cursorColor: AppColors.primary,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: _appvalidator.isEmptyCheck,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: false,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Số tiền (VND)',
                          fillColor: Color(0xFFFFF9F1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dateController,
                        style: _fieldTextStyle,
                        cursorColor: AppColors.primary,
                        readOnly: true,
                        onTap: _selectDate,
                        decoration: const InputDecoration(
                          labelText: 'Ngày giao dịch',
                          suffixIcon: Icon(Icons.calendar_today),
                          fillColor: Color(0xFFFFF9F1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CategoryDropdown(
                        cattype: _category,
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _category = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
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
                        label: const Text('Thêm danh mục'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _type,
                        style: _fieldTextStyle,
                        decoration: const InputDecoration(
                          labelText: 'Loại giao dịch',
                          prefixIcon: Icon(Icons.sync_alt_rounded),
                          fillColor: Color(0xFFFFF9F1),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'credit',
                            child: Text('Thu Nhập'),
                          ),
                          DropdownMenuItem(
                            value: 'debit',
                            child: Text('Chi Tiêu'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _type = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noteController,
                        style: _fieldTextStyle,
                        cursorColor: AppColors.primary,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú',
                          alignLabelWithHint: true,
                          fillColor: Color(0xFFFFF9F1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SavingGoalsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.savings_outlined),
                        label: const Text('Góp tiết kiệm'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _submitForm,
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text('Lưu cập nhật'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
