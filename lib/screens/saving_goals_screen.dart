import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/saving_goal_model.dart';
import 'saving_goal_detail_screen.dart';

class SavingGoalsScreen extends StatefulWidget {
  const SavingGoalsScreen({super.key});

  @override
  State<SavingGoalsScreen> createState() => _SavingGoalsScreenState();
}

class _SavingGoalsScreenState extends State<SavingGoalsScreen> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final currencyFormat = NumberFormat.decimalPattern('vi_VN');

  @override
  Widget build(BuildContext context) {
    if (userId == null)
      return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Mục tiêu Tiết kiệm",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('saving_goals')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final goals =
              snapshot.data?.docs
                  .map(
                    (doc) => SavingGoal.fromFirestore(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList() ??
              [];

          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.savings_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Chưa có mục tiêu tiết kiệm nào",
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddGoalDialog(context),
                    child: const Text("Tạo mục tiêu đầu tiên"),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _buildGoalCard(goal);
            },
          );
        },
      ),
    );
  }

  Widget _buildGoalCard(SavingGoal goal) {
    bool isCompleted = goal.status == 'completed';
    bool isWithdrawn = goal.status == 'withdrawn';
    bool isEarlyWithdrawn = goal.status == 'early_withdrawn';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SavingGoalDetailScreen(goal: goal),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        borderOnForeground: true,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(goal.color.replaceFirst('#', '0xFF')),
                      ).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconData(goal.icon),
                      color: Color(
                        int.parse(goal.color.replaceFirst('#', '0xFF')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isEarlyWithdrawn
                              ? "Rút sớm"
                              : (isWithdrawn
                                    ? "Hoàn thành"
                                    : (isCompleted
                                          ? "Đã đạt mục tiêu"
                                          : "Đang thực hiện")),
                          style: TextStyle(
                            fontSize: 12,
                            color: isEarlyWithdrawn
                                ? Colors.orange
                                : ((isCompleted || isWithdrawn)
                                      ? Colors.green
                                      : Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isWithdrawn && !isCompleted && !isEarlyWithdrawn)
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColors.accentStrong,
                      ),
                      onPressed: () => _showAddMoneyDialog(goal),
                    ),
                  if (isCompleted && !isWithdrawn && !isEarlyWithdrawn)
                    ElevatedButton(
                      onPressed: () => _showWithdrawDialog(goal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Rút tiền"),
                    ),
                  if (!isCompleted &&
                      !isWithdrawn &&
                      !isEarlyWithdrawn &&
                      goal.currentAmount > 0)
                    OutlinedButton(
                      onPressed: () => _showWithdrawDialog(goal),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                      child: const Text("Rút sớm"),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteGoal(goal),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${currencyFormat.format(goal.currentAmount)} VND",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${currencyFormat.format(goal.targetAmount)} VND",
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 10,
                  backgroundColor: Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    (isCompleted || isWithdrawn)
                        ? Colors.green
                        : (isEarlyWithdrawn
                              ? Colors.orange
                              : Color(
                                  int.parse(
                                    goal.color.replaceFirst('#', '0xFF'),
                                  ),
                                )),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!isCompleted && !isWithdrawn && !isEarlyWithdrawn)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: AppColors.accentStrong,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Cần tiết kiệm ${currencyFormat.format(goal.dailySavingRequired)} VND/ngày để kịp tiến độ (${goal.daysLeft} ngày còn lại)",
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.accentStrong,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteGoal(SavingGoal goal) {
    if (goal.currentAmount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Không thể xóa"),
          content: const Text(
            "Mục tiêu này vẫn còn tiền tiết kiệm. Vui lòng rút toàn bộ tiền về ví chính trước khi xóa.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Đã hiểu"),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text(
          "Bạn có chắc chắn muốn xóa mục tiêu '${goal.name}'? Hành động này không thể hoàn tác.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('saving_goals')
                  .doc(goal.id)
                  .delete();
              if (!mounted) return;
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đã xóa mục tiêu tiết kiệm.")),
              );
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'flight':
        return Icons.flight;
      case 'phone':
        return Icons.smartphone;
      case 'laptop':
        return Icons.laptop;
      case 'gift':
        return Icons.card_giftcard;
      case 'shopping':
        return Icons.shopping_bag;
      default:
        return Icons.star;
    }
  }

  Widget _buildDateShortcut(
    String label,
    int days,
    DateTime selectedDate,
    Function(DateTime) onSelected,
  ) {
    DateTime targetDate = DateTime.now().add(Duration(days: days));
    bool isSelected =
        selectedDate.year == targetDate.year &&
        selectedDate.month == targetDate.month &&
        selectedDate.day == targetDate.day;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) onSelected(targetDate);
        },
        selectedColor: AppColors.primary,
        backgroundColor: Colors.grey[200],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));
    String selectedIcon = 'star';
    String selectedColor = '#3498DB';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (stfCtx, setDialogState) => AlertDialog(
          title: const Text("Mục tiêu mới"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Tên mục tiêu"),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: "Số tiền mục tiêu (VND)",
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text("Ngày hoàn thành"),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      locale: const Locale('vi', 'VN'),
                    );
                    if (picked != null)
                      setDialogState(() => selectedDate = picked);
                  },
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDateShortcut(
                        "1 tháng",
                        30,
                        selectedDate,
                        (date) => setDialogState(() => selectedDate = date),
                      ),
                      _buildDateShortcut(
                        "3 tháng",
                        90,
                        selectedDate,
                        (date) => setDialogState(() => selectedDate = date),
                      ),
                      _buildDateShortcut(
                        "6 tháng",
                        180,
                        selectedDate,
                        (date) => setDialogState(() => selectedDate = date),
                      ),
                      _buildDateShortcut(
                        "1 năm",
                        365,
                        selectedDate,
                        (date) => setDialogState(() => selectedDate = date),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Chọn Icon:"),
                Wrap(
                  spacing: 10,
                  children:
                      [
                            'star',
                            'car',
                            'home',
                            'flight',
                            'phone',
                            'laptop',
                            'gift',
                            'shopping',
                          ]
                          .map(
                            (icon) => GestureDetector(
                              onTap: () =>
                                  setDialogState(() => selectedIcon = icon),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: selectedIcon == icon
                                    ? AppColors.primary
                                    : Colors.grey[200],
                                child: Icon(
                                  _getIconData(icon),
                                  size: 18,
                                  color: selectedIcon == icon
                                      ? Colors.white
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    amountController.text.isEmpty)
                  return;
                final newGoal = SavingGoal(
                  id: const Uuid().v4(),
                  name: nameController.text,
                  targetAmount: int.parse(amountController.text),
                  currentAmount: 0,
                  startDate: DateTime.now(),
                  targetDate: selectedDate,
                  icon: selectedIcon,
                  color: selectedColor,
                  status: 'active',
                  createdAt: DateTime.now(),
                );
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('saving_goals')
                    .doc(newGoal.id)
                    .set(newGoal.toMap());
                if (!mounted) return;
                Navigator.pop(dialogCtx);
              },
              child: const Text("Tạo ngay"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMoneyDialog(SavingGoal goal) {
    if (userId == null) return;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          int balance = 0;
          if (snapshot.hasData && snapshot.data!.exists) {
            balance =
                (snapshot.data!.data()
                    as Map<String, dynamic>)['remainingAmount'] ??
                0;
          }

          return StatefulBuilder(
            builder: (context, setState) {
              int currentInput = int.tryParse(amountController.text) ?? 0;
              bool isInsufficient = currentInput > balance;

              int neededAmount = goal.targetAmount - goal.currentAmount;
              bool isExcess = currentInput > neededAmount && neededAmount > 0;

              return AlertDialog(
                title: Text("Nạp tiền: ${goal.name}"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: "Số tiền muốn nạp (VND)",
                        hintText: "Ví dụ: 500000",
                        errorText: isInsufficient
                            ? "Số dư không đủ! (Hiện có: ${currencyFormat.format(balance)})"
                            : null,
                      ),
                    ),
                    if (isExcess && !isInsufficient)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Lưu ý: Bạn chỉ cần nạp thêm ${currencyFormat.format(neededAmount)} VND để hoàn thành mục tiêu. Hệ thống sẽ chỉ lấy đủ số tiền này.",
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (!isInsufficient && !isExcess)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Số dư hiện tại: ${currencyFormat.format(balance)} VND",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("Hủy"),
                  ),
                  ElevatedButton(
                    onPressed: isInsufficient || currentInput <= 0
                        ? null
                        : () async {
                            int inputAmount = currentInput;
                            final userRef = FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId);
                            final goalRef = userRef
                                .collection('saving_goals')
                                .doc(goal.id);

                            try {
                              int actualAmountTaken = 0;
                              bool wasExcessive = false;

                              await FirebaseFirestore.instance.runTransaction((
                                transaction,
                              ) async {
                                // ĐỌC TRƯỚC
                                final userDoc = await transaction.get(userRef);
                                final goalDoc = await transaction.get(goalRef);

                                int latestBalance =
                                    (userDoc.data()?['remainingAmount'] ?? 0);
                                int currentAmt =
                                    goalDoc.data()?['current_amount'] ?? 0;
                                int targetAmt =
                                    goalDoc.data()?['target_amount'] ?? 0;

                                int stillNeeded = targetAmt - currentAmt;
                                if (stillNeeded <= 0)
                                  throw "Mục tiêu đã hoàn thành!";

                                actualAmountTaken = inputAmount;
                                if (inputAmount > stillNeeded) {
                                  actualAmountTaken = stillNeeded;
                                  wasExcessive = true;
                                }

                                if (latestBalance < actualAmountTaken) {
                                  throw "Số dư không đủ để thực hiện giao dịch!";
                                }

                                // GHI SAU
                                // 1. Trừ tiền Balance
                                transaction.update(userRef, {
                                  'remainingAmount':
                                      latestBalance - actualAmountTaken,
                                });

                                // 2. Cộng tiền vào Goal
                                int newCurrent = currentAmt + actualAmountTaken;
                                String newStatus = newCurrent >= targetAmt
                                    ? 'completed'
                                    : 'active';

                                transaction.update(goalRef, {
                                  'current_amount': newCurrent,
                                  'status': newStatus,
                                });

                                // 3. Thêm bản ghi contribution
                                final contributionRef = goalRef
                                    .collection('contributions')
                                    .doc();
                                transaction.set(contributionRef, {
                                  'amount': actualAmountTaken,
                                  'date': Timestamp.now(),
                                  'createdAt': Timestamp.now(),
                                });
                              });

                              if (!mounted) return;
                              Navigator.pop(dialogContext);

                              String message = wasExcessive
                                  ? "Bạn đã nạp dư! Hệ thống chỉ lấy đủ ${currencyFormat.format(actualAmountTaken)} VND để hoàn thành mục tiêu."
                                  : "Đã nạp thành công ${currencyFormat.format(actualAmountTaken)} VND!";

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: wasExcessive
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: const Text("Xác nhận góp"),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showWithdrawDialog(SavingGoal goal) {
    bool isCompleted = goal.status == 'completed';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isCompleted ? "Rút tiền tiết kiệm" : "Rút tiền sớm"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bạn muốn rút toàn bộ ${currencyFormat.format(goal.currentAmount)} VND từ mục tiêu '${goal.name}' về ví chính?",
            ),
            if (!isCompleted)
              const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  "Lưu ý: Bạn chưa đạt được mục tiêu đề ra. Việc rút tiền sớm sẽ kết thúc mục tiêu này.",
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              final userRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId);

              await FirebaseFirestore.instance.runTransaction((
                transaction,
              ) async {
                final userDoc = await transaction.get(userRef);
                int balance = (userDoc.data()?['remainingAmount'] ?? 0);

                // 1. Cộng tiền về Balance
                transaction.update(userRef, {
                  'remainingAmount': balance + goal.currentAmount,
                });

                // 2. Cập nhật trạng thái Goal
                // Phân biệt rút sớm và rút hoàn thành
                String finalStatus = isCompleted
                    ? 'withdrawn'
                    : 'early_withdrawn';
                transaction.update(
                  userRef.collection('saving_goals').doc(goal.id),
                  {'current_amount': 0, 'status': finalStatus},
                );
              });

              if (!mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isCompleted
                        ? "Rút tiền hoàn thành thành công!"
                        : "Rút tiền sớm thành công!",
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? Colors.green : Colors.orange,
            ),
            child: const Text("Xác nhận rút"),
          ),
        ],
      ),
    );
  }
}
