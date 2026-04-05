import 'package:app/models/budget_model.dart';
import 'package:app/services/db.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/widgets/app_chrome.dart';
import 'package:app/widgets/budget_progress_card.dart';
import 'package:app/widgets/category_dropdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime _selectedMonth = DateTime.now();

  String get currentMonthYear =>
      "${_selectedMonth.month} ${_selectedMonth.year}";

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'CHỌN THÁNG NGÂN SÁCH',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = picked;
      });
    }
  }

  void _showAddBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AddBudgetDialog(monthyear: currentMonthYear);
      },
    );
  }

  void _showEditBudgetDialog(BuildContext context, Budget budget) {
    showDialog(
      context: context,
      builder: (context) {
        return AddBudgetDialog(
          monthyear: currentMonthYear,
          existingBudget: budget,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));
    }

    String displayMonthYear = DateFormat(
      'MMMM yyyy',
      'vi',
    ).format(_selectedMonth);
    displayMonthYear =
        displayMonthYear[0].toUpperCase() + displayMonthYear.substring(1);

    return AppScaffold(
      appBar: AppBar(title: const Text('Ngân sách')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: _previousMonth,
                ),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayMonthYear,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Budget>>(
              stream: Db().getBudgets(currentMonthYear),
              builder: (context, budgetSnapshot) {
                if (budgetSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final budgets = budgetSnapshot.data ?? [];

                if (budgets.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: "Chưa có ngân sách",
                    message:
                        "Hãy nhấn nút + để tạo ngân sách đầu tiên cho tháng này.",
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('transactions')
                      .where('monthyear', isEqualTo: currentMonthYear)
                      .where('type', isEqualTo: 'debit')
                      .snapshots(),
                  builder: (context, txSnapshot) {
                    if (txSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final transactions = txSnapshot.data?.docs ?? [];

                    return ListView.builder(
                      itemCount: budgets.length,
                      itemBuilder: (context, index) {
                        final budget = budgets[index];

                        int spentAmount = 0;
                        for (var tx in transactions) {
                          final data = tx.data() as Map<String, dynamic>;
                          if (data['category'] == budget.categoryName) {
                            spentAmount += (data['amount'] as num).toInt();
                          }
                        }

                        return BudgetProgressCard(
                          budget: budget,
                          spentAmount: spentAmount,
                          onEdit: () => _showEditBudgetDialog(context, budget),
                          onDelete: () => _confirmDeleteBudget(context, budget),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBudget(BuildContext context, Budget budget) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa Ngân Sách'),
          content: Text(
            'Bạn có chắc chắn muốn xóa ngân sách cho danh mục "${budget.categoryName}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Db().deleteBudget(budget.id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class AddBudgetDialog extends StatefulWidget {
  final String monthyear;
  final Budget? existingBudget;

  const AddBudgetDialog({
    super.key,
    required this.monthyear,
    this.existingBudget,
  });

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  String? category;
  final TextEditingController amountController = TextEditingController();
  bool isLoading = false;

  bool get isEditing => widget.existingBudget != null;

  @override
  void initState() {
    super.initState();
    category = widget.existingBudget?.categoryName;
    if (widget.existingBudget != null) {
      amountController.text = widget.existingBudget!.limitAmount.toString();
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void _saveBudget() async {
    if (amountController.text.isEmpty || category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn danh mục và nhập số tiền!'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final int amount = int.parse(
        amountController.text.replaceAll(',', '').replaceAll('.', ''),
      );

      final budget = Budget(
        id: widget.existingBudget?.id ?? const Uuid().v4(),
        categoryName: category!,
        limitAmount: amount,
        monthyear: widget.monthyear,
        createdAt: widget.existingBudget?.createdAt ?? DateTime.now(),
      );

      await Db().setBudget(budget);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Đã cập nhật ngân sách thành công!'
                  : 'Đã thêm ngân sách thành công!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Sửa Ngân Sách' : 'Thêm Ngân Sách Mới'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CategoryDropdown(
            cattype: category,
            onChanged: (String? value) {
              setState(() {
                category = value;
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Định mức (VND)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _saveBudget,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Lưu', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
