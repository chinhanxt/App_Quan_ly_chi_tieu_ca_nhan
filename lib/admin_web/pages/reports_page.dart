import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/admin_web/admin_web_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, required this.repository});

  final AdminWebRepository repository;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late DateTime _selectedMonth;
  late Future<AdminMonthlyReport> _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _future = widget.repository.loadMonthlyReport(_selectedMonth);
  }

  void _reload() {
    setState(() {
      _future = widget.repository.loadMonthlyReport(_selectedMonth);
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
      _future = widget.repository.loadMonthlyReport(_selectedMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // FILTER TOOLBAR
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Tháng trước',
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  DateFormat('MM / yyyy').format(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Tháng sau',
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tải lại báo cáo'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        
        // MAIN CONTENT
        Expanded(
          child: FutureBuilder<AdminMonthlyReport>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final report = snapshot.data!;
              final transactions = report.transactions;
              final topUsers = report.topUsers;
              final categories = report.categories;

              if (report.totalTransactions == 0) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assessment_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'Không có dữ liệu báo cáo cho tháng này.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                children: [
                  // METRICS
                  Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    children: [
                      AdminMetricCard(
                        label: 'Tổng giao dịch',
                        value: '${report.totalTransactions}',
                        note: 'Số lượng GD trong tháng',
                        tint: const Color(0xFF155EEF),
                        icon: Icons.receipt_long_rounded,
                      ),
                      AdminMetricCard(
                        label: 'Tổng thu',
                        value: adminCurrency(report.totalCredit),
                        note: 'Tiền nạp/thu vào hệ thống',
                        tint: const Color(0xFF039855),
                        icon: Icons.trending_up_rounded,
                      ),
                      AdminMetricCard(
                        label: 'Tổng chi',
                        value: adminCurrency(report.totalDebit),
                        note: 'Tiền chi tiêu/thanh toán',
                        tint: const Color(0xFFD92D20),
                        icon: Icons.trending_down_rounded,
                      ),
                      AdminMetricCard(
                        label: 'Dòng tiền thuần',
                        value: adminCurrency(report.totalCredit - report.totalDebit),
                        note: 'Chênh lệch Thu - Chi',
                        tint: const Color(0xFF7A5AF8),
                        icon: Icons.account_balance_wallet_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // TOP LISTS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TOP USERS
                      Expanded(
                        child: AdminPanel(
                          title: 'Người dùng giao dịch nhiều nhất',
                          isExpanded: false,
                          child: Column(
                            children: topUsers.isEmpty 
                              ? [const Center(child: Text('Không có dữ liệu'))]
                              : topUsers.map((user) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    child: Text(user.name[0].toUpperCase()),
                                  ),
                                  title: Text(
                                    user.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text('${user.transactionCount} giao dịch'),
                                  trailing: Text(
                                    adminCurrency(user.totalAmount),
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                )).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // TOP CATEGORIES
                      Expanded(
                        child: AdminPanel(
                          title: 'Phân tích theo danh mục',
                          isExpanded: false,
                          child: Column(
                            children: categories.isEmpty
                              ? [const Center(child: Text('Không có dữ liệu'))]
                              : categories.take(8).map((item) {
                                  final double percentage = report.totalDebit == 0 
                                      ? 0 
                                      : (item.totalAmount / (item.type == 'credit' ? report.totalCredit : report.totalDebit));
                                  return Column(
                                    children: [
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          item.name,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        subtitle: Text(
                                          '${item.type == 'credit' ? 'Thu nhập' : 'Chi tiêu'} • ${item.transactionCount} GD',
                                        ),
                                        trailing: Text(
                                          adminCurrency(item.totalAmount),
                                          style: const TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      LinearProgressIndicator(
                                        value: percentage,
                                        backgroundColor: const Color(0xFFF1F5F9),
                                        color: item.type == 'credit' ? Colors.green : Colors.orange,
                                        minHeight: 4,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // RECENT TRANSACTIONS IN MONTH
                  AdminPanel(
                    title: 'Chi tiết giao dịch trong tháng',
                    isExpanded: false,
                    child: Column(
                      children: transactions.isEmpty
                        ? [const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Không có giao dịch')))]
                        : transactions.map((tx) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: tx.type == 'credit' ? Colors.green.shade50 : Colors.red.shade50,
                              child: Icon(
                                tx.type == 'credit' ? Icons.south_west_rounded : Icons.north_east_rounded,
                                color: tx.type == 'credit' ? Colors.green.shade700 : Colors.red.shade700,
                                size: 16,
                              ),
                            ),
                            title: Text(
                              tx.title,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${tx.category} • ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(tx.timestamp))}',
                            ),
                            trailing: Text(
                              adminCurrency(tx.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: tx.type == 'credit' ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          )).toList(),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
