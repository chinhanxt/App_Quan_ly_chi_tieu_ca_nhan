import 'package:app/utils/appvalidator.dart';
import 'package:app/utils/icon_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AITransactionDraftEditor extends StatefulWidget {
  const AITransactionDraftEditor({
    super.key,
    required this.initialTransaction,
    required this.categoryOptions,
  });

  final Map<String, dynamic> initialTransaction;
  final List<Map<String, dynamic>> categoryOptions;

  @override
  State<AITransactionDraftEditor> createState() =>
      _AITransactionDraftEditorState();
}

class _AITransactionDraftEditorState extends State<AITransactionDraftEditor> {
  final _formKey = GlobalKey<FormState>();
  final _validator = Appvalidator();
  final _appIcons = AppIcons();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _dateController;
  late final TextEditingController _noteController;

  late DateTime _selectedDateTime;
  late String _type;
  late String _category;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = _parseInitialDateTime(widget.initialTransaction);
    _type = widget.initialTransaction['type']?.toString() == 'credit'
        ? 'credit'
        : 'debit';
    _category =
        widget.initialTransaction['selectedCategory']?.toString().trim().isNotEmpty ==
            true
        ? widget.initialTransaction['selectedCategory'].toString().trim()
        : widget.initialTransaction['category']?.toString().trim().isNotEmpty ==
              true
        ? widget.initialTransaction['category'].toString().trim()
        : 'Khác';

    _titleController = TextEditingController(
      text: widget.initialTransaction['title']?.toString() ?? '',
    );
    _amountController = TextEditingController(
      text: widget.initialTransaction['amount']?.toString() ?? '',
    );
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_selectedDateTime),
    );
    _noteController = TextEditingController(
      text: widget.initialTransaction['note']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  DateTime _parseInitialDateTime(Map<String, dynamic> transaction) {
    final dateTimeRaw = transaction['dateTime']?.toString().trim() ?? '';
    if (dateTimeRaw.isNotEmpty) {
      try {
        return DateFormat('dd/MM/yyyy HH:mm').parseStrict(dateTimeRaw);
      } catch (_) {}
    }

    final dateRaw = transaction['date']?.toString().trim() ?? '';
    if (dateRaw.isNotEmpty) {
      try {
        return DateFormat('dd/MM/yyyy').parseStrict(dateRaw);
      } catch (_) {}
    }

    return DateTime.now();
  }

  List<Map<String, dynamic>> get _effectiveCategoryOptions {
    final normalized = <String>{};
    final options = <Map<String, dynamic>>[];

    void addOption(Map<String, dynamic> item) {
      final name = item['name']?.toString().trim() ?? '';
      if (name.isEmpty) return;
      if (!normalized.add(name.toLowerCase())) return;
      options.add(<String, dynamic>{
        'name': name,
        'iconName': item['iconName']?.toString() ?? 'cartShopping',
      });
    }

    for (final item in widget.categoryOptions) {
      addOption(item);
    }

    addOption(<String, dynamic>{
      'name': _category,
      'iconName':
          widget.initialTransaction['selectedIconName']?.toString() ??
          widget.initialTransaction['suggestedIcon']?.toString() ??
          widget.initialTransaction['fallbackIconName']?.toString() ??
          'cartShopping',
    });

    return options;
  }

  String _resolveIconName(String category) {
    for (final item in _effectiveCategoryOptions) {
      if (item['name'] == category) {
        return item['iconName']?.toString() ?? 'cartShopping';
      }
    }
    return _type == 'credit' ? 'moneyBillWave' : 'cartShopping';
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime.isAfter(now) ? now : _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: now,
      locale: const Locale('vi', 'VN'),
      helpText: 'CHỌN NGÀY GIAO DỊCH',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
    );

    if (picked == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDateTime.hour,
        _selectedDateTime.minute,
      );
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDateTime);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền phải lớn hơn 0')),
      );
      return;
    }

    final selectedIconName = _resolveIconName(_category);
    final normalizedTitle = _titleController.text.trim();
    final normalizedNote = _noteController.text.trim();
    final normalizedDate = DateFormat('dd/MM/yyyy').format(_selectedDateTime);
    final normalizedTime = DateFormat('HH:mm').format(_selectedDateTime);
    final normalizedDateTime = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(_selectedDateTime);

    final updated = Map<String, dynamic>.from(widget.initialTransaction)
      ..['title'] = normalizedTitle
      ..['amount'] = amount
      ..['type'] = _type
      ..['note'] = normalizedNote
      ..['date'] = normalizedDate
      ..['time'] = normalizedTime
      ..['dateTime'] = normalizedDateTime
      ..['selectedCategory'] = _category
      ..['selectedIconName'] = selectedIconName;

    final isNewCategory = updated['isNewCategory'] == true;
    final confirmCreateCategory = updated['confirmCreateCategory'] ?? true;

    if (isNewCategory && confirmCreateCategory == false) {
      updated['fallbackCategory'] = _category;
      updated['fallbackIconName'] = selectedIconName;
    } else {
      updated['category'] = _category;
      updated['suggestedIcon'] = selectedIconName;
      updated['fallbackCategory'] = _category;
      updated['fallbackIconName'] = selectedIconName;
    }

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: screen.width > 560 ? 520 : screen.width - 32,
        constraints: BoxConstraints(maxHeight: screen.height * 0.86),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Sửa card giao dịch',
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
                  'Kiểm tra lại thông tin trước khi lưu giao dịch AI.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  validator: _validator.isEmptyCheck,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(labelText: 'Tiêu đề'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  validator: _validator.isEmptyCheck,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Số tiền (VND)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: const InputDecoration(
                    labelText: 'Ngày giao dịch',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Loại giao dịch',
                    prefixIcon: Icon(Icons.sync_alt_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'credit', child: Text('Thu nhập')),
                    DropdownMenuItem(value: 'debit', child: Text('Chi tiêu')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _type = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _effectiveCategoryOptions.map((item) {
                    final iconName =
                        item['iconName']?.toString() ?? 'cartShopping';
                    final name = item['name']?.toString() ?? 'Khác';
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_appIcons.getIconData(iconName), size: 16),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(name, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null || value.trim().isEmpty) return;
                    setState(() {
                      _category = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Lưu thay đổi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
