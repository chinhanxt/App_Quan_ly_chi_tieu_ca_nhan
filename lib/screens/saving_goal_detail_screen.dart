import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/saving_goal_model.dart';

class SavingGoalDetailScreen extends StatefulWidget {
  final SavingGoal goal;
  const SavingGoalDetailScreen({super.key, required this.goal});

  @override
  State<SavingGoalDetailScreen> createState() => _SavingGoalDetailScreenState();
}

class _SavingGoalDetailScreenState extends State<SavingGoalDetailScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final currencyFormat = NumberFormat.decimalPattern('vi_VN');

  // Lưu trữ các đóng góp theo ngày (đã chuẩn hóa về 0h 0p 0s)
  Map<DateTime, int> _contributions = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Chuẩn hóa DateTime về đầu ngày để so sánh
  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'car': return Icons.directions_car;
      case 'home': return Icons.home;
      case 'flight': return Icons.flight;
      case 'phone': return Icons.smartphone;
      case 'laptop': return Icons.laptop;
      case 'gift': return Icons.card_giftcard;
      case 'shopping': return Icons.shopping_bag;
      default: return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalColor = Color(int.parse(widget.goal.color.replaceFirst('#', '0xFF')));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.goal.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: (widget.goal.status != 'withdrawn' && widget.goal.status != 'early_withdrawn')
          ? StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('saving_goals')
                  .doc(widget.goal.id)
                  .snapshots(),
              builder: (context, snapshot) {
                int currentSaved = widget.goal.currentAmount;
                if (snapshot.hasData && snapshot.data!.exists) {
                  currentSaved = (snapshot.data!.data() as Map<String, dynamic>)['current_amount'] ?? 0;
                }
                
                return FloatingActionButton.extended(
                  onPressed: () => _showAddMoneyDialog(currentSaved),
                  backgroundColor: goalColor,
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  label: Text(
                    "Nạp cho ${_selectedDay != null ? DateFormat('dd/MM').format(_selectedDay!) : 'hôm nay'}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                );
              }
            )
          : null,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('saving_goals')
            .doc(widget.goal.id)
            .snapshots(),
        builder: (context, goalSnapshot) {
          if (!goalSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final goalData = goalSnapshot.data!.data() as Map<String, dynamic>;
          final currentAmount = goalData['current_amount'] ?? 0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('saving_goals')
                .doc(widget.goal.id)
                .collection('contributions')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _contributions = {};
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp).toDate();
                  final normalizedDate = _normalizeDate(date);
                  final amount = data['amount'] as int;
                  
                  _contributions[normalizedDate] = (_contributions[normalizedDate] ?? 0) + amount;
                }
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(goalColor, currentAmount),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TableCalendar(
                            locale: 'vi_VN',
                            firstDay: widget.goal.startDate.isBefore(DateTime.now().subtract(const Duration(days: 365))) 
                                ? widget.goal.startDate 
                                : DateTime.now().subtract(const Duration(days: 365)),
                            lastDay: widget.goal.targetDate.isAfter(DateTime.now().add(const Duration(days: 365)))
                                ? widget.goal.targetDate
                                : DateTime.now().add(const Duration(days: 365)),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                              _showContributionInfo(selectedDay);
                            },
                            onFormatChanged: (format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            },
                            onPageChanged: (focusedDay) {
                              _focusedDay = focusedDay;
                            },
                            eventLoader: (day) {
                              final normalized = _normalizeDate(day);
                              if (_contributions.containsKey(normalized)) {
                                return [true];
                              }
                              return [];
                            },
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: goalColor.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: goalColor,
                                shape: BoxShape.circle,
                              ),
                              markerDecoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildLegend(),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        }
      ),
    );
  }

  Widget _buildHeader(Color goalColor, int currentAmount) {
    double progress = (currentAmount / widget.goal.targetAmount).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: goalColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconData(widget.goal.icon),
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.goal.name,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Mục tiêu: ${currencyFormat.format(widget.goal.targetAmount)} VND",
            style: TextStyle(color: Colors.blue[100], fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem("Đã tiết kiệm", currencyFormat.format(currentAmount)),
              _buildStatItem("Tiến độ", "${(progress * 100).toStringAsFixed(1)}%"),
              _buildStatItem("Còn lại", "${widget.goal.daysLeft} ngày"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.blue[100], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          _buildLegendItem(Colors.green, "Ngày đã nạp tiền"),
          const SizedBox(width: 20),
          _buildLegendItem(Colors.blue[900]!.withOpacity(0.3), "Hôm nay"),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  void _showAddMoneyDialog(int currentSaved) {
    if (_selectedDay == null || userId == null) return;
    
    DateTime selected = _normalizeDate(_selectedDay!);
    DateTime start = _normalizeDate(widget.goal.startDate);
    DateTime target = _normalizeDate(widget.goal.targetDate);
    DateTime now = _normalizeDate(DateTime.now());

    // 1. Kiểm tra ngày tương lai
    if (selected.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể nạp tiền cho ngày ở tương lai!"), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. Kiểm tra ngày trước timeline (startDate)
    if (selected.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ngày chọn (${DateFormat('dd/MM').format(selected)}) trước ngày bắt đầu mục tiêu (${DateFormat('dd/MM').format(start)})!"), 
          backgroundColor: Colors.orange
        ),
      );
      return;
    }

    // 3. Kiểm tra ngày sau timeline (targetDate)
    if (selected.isAfter(target)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ngày chọn (${DateFormat('dd/MM').format(selected)}) đã vượt quá thời hạn mục tiêu (${DateFormat('dd/MM').format(target)})!"), 
          backgroundColor: Colors.orange
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          int balance = 0;
          if (snapshot.hasData && snapshot.data!.exists) {
            balance = (snapshot.data!.data() as Map<String, dynamic>)['remainingAmount'] ?? 0;
          }

          return StatefulBuilder(
            builder: (context, setState) {
              int currentInput = int.tryParse(amountController.text) ?? 0;
              bool isInsufficient = currentInput > balance;
              
              int neededAmount = widget.goal.targetAmount - currentSaved;
              bool isExcess = currentInput > neededAmount && neededAmount > 0;

              return AlertDialog(
                title: Text("Nạp cho ngày ${DateFormat('dd/MM').format(_selectedDay!)}"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: "Số tiền muốn nạp (VND)",
                        hintText: "Ví dụ: 500000",
                        errorText: isInsufficient ? "Số dư không đủ! (Hiện có: ${currencyFormat.format(balance)})" : null,
                      ),
                    ),
                    if (isExcess && !isInsufficient)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Lưu ý: Bạn chỉ cần nạp thêm ${currencyFormat.format(neededAmount)} VND để hoàn thành mục tiêu. Hệ thống sẽ chỉ lấy đủ số tiền này.",
                          style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (!isInsufficient && !isExcess)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Số dư hiện tại: ${currencyFormat.format(balance)} VND",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("Hủy")),
                  ElevatedButton(
                    onPressed: isInsufficient || currentInput <= 0 ? null : () async {
                      int inputAmount = currentInput;
                      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
                      final goalRef = userRef.collection('saving_goals').doc(widget.goal.id);
                      
                      try {
                        int actualAmountTaken = 0;
                        bool wasExcessive = false;

                        await FirebaseFirestore.instance.runTransaction((transaction) async {
                          final userDoc = await transaction.get(userRef);
                          final goalDoc = await transaction.get(goalRef);

                          int latestBalance = (userDoc.data()?['remainingAmount'] ?? 0);
                          int currentAmt = goalDoc.data()?['current_amount'] ?? 0;
                          int targetAmt = goalDoc.data()?['target_amount'] ?? 0;
                          
                          int stillNeeded = targetAmt - currentAmt;
                          if (stillNeeded <= 0) throw "Mục tiêu đã hoàn thành!";

                          actualAmountTaken = inputAmount;
                          if (inputAmount > stillNeeded) {
                            actualAmountTaken = stillNeeded;
                            wasExcessive = true;
                          }

                          if (latestBalance < actualAmountTaken) {
                            throw "Số dư không đủ để thực hiện giao dịch!";
                          }

                          // 1. Trừ tiền Balance
                          transaction.update(userRef, {'remainingAmount': latestBalance - actualAmountTaken});

                          // 2. Cộng tiền vào Goal
                          int newCurrent = currentAmt + actualAmountTaken;
                          String newStatus = newCurrent >= targetAmt ? 'completed' : 'active';
                          
                          transaction.update(
                            goalRef, 
                            {'current_amount': newCurrent, 'status': newStatus}
                          );

                          // 3. Thêm bản ghi contribution
                          final contributionRef = goalRef.collection('contributions').doc();
                          transaction.set(contributionRef, {
                            'amount': actualAmountTaken,
                            'date': Timestamp.fromDate(_selectedDay!),
                            'createdAt': Timestamp.now(),
                          });
                        });

                        if (!mounted) return;
                        Navigator.pop(dialogCtx);
                        
                        String message = wasExcessive 
                          ? "Bạn đã nạp dư! Hệ thống chỉ lấy đủ ${currencyFormat.format(actualAmountTaken)} VND để hoàn thành mục tiêu."
                          : "Đã nạp thành công ${currencyFormat.format(actualAmountTaken)} VND!";
                          
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: wasExcessive ? Colors.orange : Colors.green,
                          )
                        );
                      } catch (e) {
                        if (!mounted) return;
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                      }
                    },
                    child: const Text("Xác nhận"),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showContributionInfo(DateTime day) {
    final normalized = _normalizeDate(day);
    final amount = _contributions[normalized];
    
    if (amount != null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ngày ${DateFormat('dd/MM/yyyy').format(day)} bạn đã nạp: ${currencyFormat.format(amount)} VND"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ngày ${DateFormat('dd/MM/yyyy').format(day)} không có khoản nạp nào."),
          backgroundColor: Colors.grey[700],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
