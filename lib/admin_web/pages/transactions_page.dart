import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/admin_web/admin_web_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key, required this.repository});

  final AdminWebRepository repository;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _type = 'all';
  String _selectedUserId = 'all';
  late Future<List<AdminTransactionRecord>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadTransactionsFeed();
  }

  void _reload() {
    setState(() {
      _future = widget.repository.loadTransactionsFeed();
    });
  }

  Future<void> _deleteTransaction(AdminTransactionRecord tx) async {
    setState(() {
      _busy = true;
    });
    try {
      await widget.repository.deleteTransaction(
        userId: tx.userId,
        transactionId: tx.id,
      );
      _reload();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AdminPanel(
            title: 'Giao dịch toàn hệ thống',
            isExpanded: true,
            child: FutureBuilder<List<AdminUserRecord>>(
              future: widget.repository.watchUsers().first,
              builder: (context, usersSnapshot) {
                return FutureBuilder<List<AdminTransactionRecord>>(
                  future: _future,
                  builder: (context, txSnapshot) {
                    if (txSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Không tải được giao dịch: ${txSnapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    if (!txSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = usersSnapshot.data ?? const <AdminUserRecord>[];
                    final userMap = usersById(users);
                    final filtered = txSnapshot.data!.where((tx) {
                      final matchesUser =
                          _selectedUserId == 'all' || tx.userId == _selectedUserId;
                      final matchesType = _type == 'all' || tx.type == _type;
                      return matchesUser && matchesType;
                    }).toList();

                    final totalCredit = filtered
                        .where((tx) => tx.type == 'credit')
                        .fold<int>(0, (sum, tx) => sum + tx.amount);
                    final totalDebit = filtered
                        .where((tx) => tx.type == 'debit')
                        .fold<int>(0, (sum, tx) => sum + tx.amount);

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedUserId,
                                decoration: const InputDecoration(
                                  labelText: 'Tài khoản',
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 'all',
                                    child: Text('Tất cả tài khoản'),
                                  ),
                                  ...users.map(
                                    (user) => DropdownMenuItem(
                                      value: user.id,
                                      child: Text(
                                        '${user.name} (${user.email})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedUserId = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 180,
                              child: DropdownButtonFormField<String>(
                                initialValue: _type,
                                decoration: const InputDecoration(
                                  labelText: 'Loại',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'all',
                                    child: Text('Tất cả'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'credit',
                                    child: Text('Thu'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'debit',
                                    child: Text('Chi'),
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
                            ),
                            const SizedBox(width: 12),
                            FilledButton.tonalIcon(
                              onPressed: _busy ? null : _reload,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Tải lại'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickInfo(
                                label: 'Số giao dịch',
                                value: '${filtered.length}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickInfo(
                                label: 'Tổng thu',
                                value: adminCurrency(totalCredit),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickInfo(
                                label: 'Tổng chi',
                                value: adminCurrency(totalDebit),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (filtered.isEmpty)
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Không có giao dịch phù hợp với bộ lọc hiện tại.',
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 24),
                              itemBuilder: (context, index) {
                                final tx = filtered[index];
                                final user = userMap[tx.userId];
                                return ListTile(
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
                                  subtitle: Text(
                                    '${user?.name ?? 'Không rõ người dùng'} • ${user?.email ?? ''}\n${tx.category} • ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(tx.timestamp))}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Wrap(
                                    spacing: 10,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        adminCurrency(tx.amount),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: tx.type == 'credit'
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                      FilledButton.tonal(
                                        onPressed: _busy
                                            ? null
                                            : () => _deleteTransaction(tx),
                                        child: const Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickInfo extends StatelessWidget {
  const _QuickInfo({
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
              color: Color(0xFF6B7280),
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
