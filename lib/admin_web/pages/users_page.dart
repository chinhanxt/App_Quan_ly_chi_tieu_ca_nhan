import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/admin_web/admin_web_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key, required this.repository, required this.profile});

  final AdminWebRepository repository;
  final AdminProfile profile;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _searchController = TextEditingController();
  String _roleFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserDetails(AdminUserRecord user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF6366F1)),
            SizedBox(width: 12),
            Text('Chi tiết người dùng'),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Tên:', user.name),
              _buildDetailRow('Email:', user.email),
              _buildDetailRow('ID:', user.id),
              _buildDetailRow('Vai trò:', user.role.toUpperCase()),
              _buildDetailRow(
                'Trạng thái:',
                user.status == 'locked' ? 'Bị khóa' : 'Hoạt động',
              ),
              _buildDetailRow(
                'Ngày tham gia:',
                user.createdAt != null
                    ? DateFormat(
                        'HH:mm - dd/MM/yyyy',
                      ).format(user.createdAt!.toDate())
                    : 'Không rõ',
              ),
              const Divider(height: 32),
              const Text(
                'THỐNG KÊ TÀI CHÍNH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox(
                      'Tổng Thu',
                      adminCurrency(user.totalCredit),
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBox(
                      'Tổng Chi',
                      adminCurrency(user.totalDebit),
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatBox(
                'Số dư hiện tại',
                adminCurrency(user.remainingAmount),
                const Color(0xFF6366F1),
                isFullWidth: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: isFullWidth
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(AdminUserRecord user) async {
    final isLocking = user.status != 'locked';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isLocking ? 'Xác nhận Khóa' : 'Xác nhận Mở khóa'),
        content: Text(
          isLocking
              ? 'Bạn có chắc chắn muốn khóa tài khoản của ${user.name}? Người dùng này sẽ không thể đăng nhập.'
              : 'Mở khóa tài khoản cho ${user.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: isLocking ? Colors.red : Colors.green,
            ),
            child: Text(isLocking ? 'Khóa tài khoản' : 'Mở khóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.repository.updateUserStatus(
        user.id,
        isLocking ? 'locked' : 'active',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminToolbar(
          searchController: _searchController,
          searchHint: 'Tìm theo email, tên hoặc vai trò...',
          onSearchChanged: (_) => setState(() {}),
          trailing: DropdownButton<String>(
            value: _roleFilter,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả vai trò')),
              DropdownMenuItem(value: 'user', child: Text('Người dùng')),
              DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
              DropdownMenuItem(
                value: 'super_admin',
                child: Text('Quản trị viên cấp cao'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _roleFilter = value;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: AdminPanel(
            title: 'Danh sách người dùng hệ thống',
            isExpanded: true,
            child: StreamBuilder<List<AdminUserRecord>>(
              stream: widget.repository.watchUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final query = _searchController.text.trim().toLowerCase();
                final filtered = snapshot.data!.where((user) {
                  final matchesQuery =
                      query.isEmpty ||
                      user.email.toLowerCase().contains(query) ||
                      user.name.toLowerCase().contains(query) ||
                      user.role.toLowerCase().contains(query);
                  final matchesRole =
                      _roleFilter == 'all' || user.role == _roleFilter;
                  return matchesQuery && matchesRole;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy người dùng phù hợp.'),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showUserDetails(user),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: user.role == 'user'
                                    ? const Color(0xFFDDEEE6)
                                    : const Color(0xFFEDE9FE),
                                child: Text(
                                  (user.name.isNotEmpty
                                          ? user.name.characters.first
                                          : user.email.characters.first)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: user.role == 'user'
                                        ? const Color(0xFF1E3A37)
                                        : const Color(0xFF7A5AF8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.email,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    adminCurrency(user.remainingAmount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Text(
                                    'Số dư hiện tại',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),
                              AdminRolePill(label: user.role),
                              const SizedBox(width: 12),
                              AdminStatusPill(status: user.status),
                              const SizedBox(width: 24),
                              if (widget.profile.isSuperAdmin)
                                SizedBox(
                                  width: 130,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: user.role,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'user',
                                        child: Text('Người dùng'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'admin',
                                        child: Text('Quản trị viên'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'super_admin',
                                        child: Text('Cấp cao'),
                                      ),
                                    ],
                                    onChanged: (value) async {
                                      if (value == null || value == user.role) {
                                        return;
                                      }
                                      await widget.repository.updateUserRole(
                                        user.id,
                                        value,
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(width: 16),
                              IconButton(
                                tooltip: user.status == 'locked'
                                    ? 'Mở khóa'
                                    : 'Khóa tài khoản',
                                icon: Icon(
                                  user.status == 'locked'
                                      ? Icons.lock_open_rounded
                                      : Icons.lock_outline_rounded,
                                  color: user.status == 'locked'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                onPressed: () => _toggleUserStatus(user),
                              ),
                            ],
                          ),
                        ),
                      ),
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
