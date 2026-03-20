import 'package:app/models/budget_model.dart';
import 'package:app/services/db.dart';
import 'package:app/widgets/budget_progress_card.dart';
import 'package:app/widgets/category_dropdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime _selectedMonth = DateTime.now();

  String get currentMonthYear => "${_selectedMonth.month} ${_selectedMonth.year}";

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

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));
    }

    String displayMonthYear = DateFormat('MMMM yyyy', 'vi').format(_selectedMonth);
    displayMonthYear = displayMonthYear[0].toUpperCase() + displayMonthYear.substring(1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Ngân Sách', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF3498DB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "Chưa có ngân sách nào trong tháng này.\nHãy nhấn + để thêm mới.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(context),
        backgroundColor: Colors.blue.shade900,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDeleteBudget(BuildContext context, Budget budget) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa Ngân Sách'),
          content: Text('Bạn có chắc chắn muốn xóa ngân sách cho danh mục "${budget.categoryName}" không?'),
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
  const AddBudgetDialog({super.key, required this.monthyear});

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  String? category;
  final TextEditingController amountController = TextEditingController();
  bool isLoading = false;

  void _saveBudget() async {
    if (amountController.text.isEmpty || category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục và nhập số tiền!')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final int amount = int.parse(amountController.text.replaceAll(',', '').replaceAll('.', ''));
      
      final budget = Budget(
        id: const Uuid().v4(),
        categoryName: category!,
        limitAmount: amount,
        monthyear: widget.monthyear,
        createdAt: DateTime.now(),
      );

      await Db().setBudget(budget);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm ngân sách thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm Ngân Sách Mới'),
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
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Định mức (VND)',              border: OutlineInputBorder(),
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900),
          child: isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Lưu', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
