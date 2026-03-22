import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/admin_web/admin_web_widgets.dart';
import 'package:flutter/material.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key, required this.repository});

  final AdminWebRepository repository;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late Future<AdminOverviewSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadOverviewSnapshot();
  }

  void _reload() {
    setState(() {
      _future = widget.repository.loadOverviewSnapshot();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminOverviewSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFD92D20),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không tải được trang tổng quan: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final stats = data.stats;
        final monthlySummary = _MonthlySummary.fromTransactions(
          data.monthTransactions,
        );

        return ListView(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _HeroPanel(onAction: _reload)),
                const SizedBox(width: 20),
                SizedBox(width: 320, child: _SummaryPanel(stats: stats)),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                AdminMetricCard(
                  label: 'Người dùng',
                  value: '${stats.totalUsers}',
                  note: '${stats.adminUsers} quản trị viên, ${stats.lockedUsers} bị khóa',
                  tint: const Color(0xFF155EEF),
                  icon: Icons.people_alt_rounded,
                ),
                AdminMetricCard(
                  label: 'Danh mục hệ thống',
                  value: '${stats.systemCategories}',
                  note: 'Dùng chung cho giao dịch và AI',
                  tint: const Color(0xFF7A5AF8),
                  icon: Icons.category_rounded,
                ),
                AdminMetricCard(
                  label: 'Thông báo đang hiển thị',
                  value: '${stats.activeBroadcasts}',
                  note: 'Thông báo đang hiển thị cho người dùng',
                  tint: const Color(0xFFDC6803),
                  icon: Icons.campaign_rounded,
                ),
                AdminMetricCard(
                  label: 'Giao dịch tháng này',
                  value: '${stats.transactionsThisMonth}',
                  note: 'Tính từ dữ liệu giao dịch hiện có',
                  tint: const Color(0xFF0E9384),
                  icon: Icons.receipt_long_rounded,
                ),
                AdminMetricCard(
                  label: 'Tổng thu',
                  value: adminCurrency(stats.totalCredit),
                  note: 'Tổng hợp từ hồ sơ người dùng',
                  tint: const Color(0xFF039855),
                  icon: Icons.trending_up_rounded,
                ),
                AdminMetricCard(
                  label: 'Tổng chi',
                  value: adminCurrency(stats.totalDebit),
                  note: 'Tổng hợp từ hồ sơ người dùng',
                  tint: const Color(0xFFD92D20),
                  icon: Icons.trending_down_rounded,
                ),
                AdminMetricCard(
                  label: 'Số dư toàn hệ thống',
                  value: adminCurrency(stats.netAmount),
                  note: 'Tổng số dư hiện tại của tất cả người dùng',
                  tint: const Color(0xFF1E3A37),
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AdminPanel(
                    title: 'Người dùng mới nhất',
                    isExpanded: false,
                    child: data.recentUsers.isEmpty
                        ? const _EmptyPanel(message: 'Chưa có người dùng nào.')
                        : Column(
                            children: data.recentUsers
                                .map(
                                  (user) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: user.role == 'user'
                                          ? const Color(0xFFDDEEE6)
                                          : const Color(0xFFEDE9FE),
                                      child: Icon(
                                        user.role == 'user'
                                            ? Icons.person_rounded
                                            : Icons.shield_rounded,
                                        color: user.role == 'user'
                                            ? const Color(0xFF1E3A37)
                                            : const Color(0xFF7A5AF8),
                                      ),
                                    ),
                                    title: Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(user.email),
                                    trailing: AdminRolePill(label: user.role),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: AdminPanel(
                    title: 'Thông báo gần đây',
                    isExpanded: false,
                    child: data.recentBroadcasts.isEmpty
                        ? const _EmptyPanel(message: 'Không có thông báo nào.')
                        : Column(
                            children: data.recentBroadcasts
                                .map(
                                  (item) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: broadcastColor(
                                        item.type,
                                      ).withValues(alpha: 0.12),
                                      child: Icon(
                                        Icons.campaign_rounded,
                                        color: broadcastColor(item.type),
                                      ),
                                    ),
                                    title: Text(
                                      item.title.trim().isNotEmpty
                                          ? item.title
                                          : item.content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      item.status == 'active'
                                          ? 'Đang hiển thị'
                                          : 'Đang tạm ẩn',
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AdminPanel(
                    title: 'Tổng hợp tháng hiện tại',
                    isExpanded: false,
                    child: monthlySummary.totalTransactions == 0
                        ? const _EmptyPanel(
                            message: 'Chưa có giao dịch trong tháng này.',
                          )
                        : Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Tổng giao dịch',
                                      value: '${monthlySummary.totalTransactions}',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Tổng thu',
                                      value: adminCurrency(
                                        monthlySummary.totalCredit,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Tổng chi',
                                      value: adminCurrency(
                                        monthlySummary.totalDebit,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              ...monthlySummary.topCategories.take(5).map(
                                (entry) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: entry.type == 'credit'
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    child: Icon(
                                      entry.type == 'credit'
                                          ? Icons.south_west_rounded
                                          : Icons.north_east_rounded,
                                      color: entry.type == 'credit'
                                          ? Colors.green.shade700
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                  title: Text(
                                    entry.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text('${entry.count} giao dịch'),
                                  trailing: Text(
                                    adminCurrency(entry.amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: AdminPanel(
                    title: 'Giao dịch gần đây',
                    isExpanded: false,
                    child: data.recentTransactions.isEmpty
                        ? const _EmptyPanel(
                            message: 'Không có giao dịch gần đây.',
                          )
                        : Column(
                            children: data.recentTransactions
                                .map(
                                  (tx) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: tx.type == 'credit'
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      child: Icon(
                                        tx.type == 'credit'
                                            ? Icons.south_west_rounded
                                            : Icons.north_east_rounded,
                                        color: tx.type == 'credit'
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                    title: Text(
                                      tx.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(tx.category),
                                    trailing: Text(
                                      adminCurrency(tx.amount),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: tx.type == 'credit'
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF18312E),
            Color(0xFF224440),
            Color(0xFFD6B872),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_mosaic_rounded,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 18),
          const Text(
            'Điều hành hệ thống tài chính',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Theo dõi người dùng, giao dịch, cấu hình AI và vận hành hệ thống trong một nơi duy nhất.',
            style: TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.tonal(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF18312E),
            ),
            child: const Text('Tải lại số liệu'),
          ),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.stats});

  final AdminOverviewStats stats;

  @override
  Widget build(BuildContext context) {
    final activeRatio = stats.totalUsers == 0
        ? 0.0
        : stats.activeUsers / stats.totalUsers;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tỷ lệ tài khoản hoạt động',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: activeRatio,
            minHeight: 12,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: const Color(0xFFF1F5F9),
            color: const Color(0xFF039855),
          ),
          const SizedBox(height: 12),
          Text(
            '${stats.activeUsers}/${stats.totalUsers} tài khoản đang hoạt động (${(activeRatio * 100).toStringAsFixed(1)}%)',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(child: Text(message)),
    );
  }
}

class _MonthlyCategoryRow {
  const _MonthlyCategoryRow({
    required this.name,
    required this.amount,
    required this.count,
    required this.type,
  });

  final String name;
  final int amount;
  final int count;
  final String type;
}

class _MonthlySummary {
  const _MonthlySummary({
    required this.totalTransactions,
    required this.totalCredit,
    required this.totalDebit,
    required this.topCategories,
  });

  final int totalTransactions;
  final int totalCredit;
  final int totalDebit;
  final List<_MonthlyCategoryRow> topCategories;

  factory _MonthlySummary.fromTransactions(
    List<AdminTransactionRecord> transactions,
  ) {
    var totalCredit = 0;
    var totalDebit = 0;
    final categoryTotals = <String, ({int amount, int count, String type})>{};

    for (final tx in transactions) {
      if (tx.type == 'credit') {
        totalCredit += tx.amount;
      } else {
        totalDebit += tx.amount;
      }

      final key = '${tx.type}:${tx.category}';
      final existing = categoryTotals[key];
      categoryTotals[key] = (
        amount: (existing?.amount ?? 0) + tx.amount,
        count: (existing?.count ?? 0) + 1,
        type: tx.type,
      );
    }

    final rows = categoryTotals.entries
        .map(
          (entry) => _MonthlyCategoryRow(
            name: entry.key.split(':').last,
            amount: entry.value.amount,
            count: entry.value.count,
            type: entry.value.type,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return _MonthlySummary(
      totalTransactions: transactions.length,
      totalCredit: totalCredit,
      totalDebit: totalDebit,
      topCategories: rows,
    );
  }
}
