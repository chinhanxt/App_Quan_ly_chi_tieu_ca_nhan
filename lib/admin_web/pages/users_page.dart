import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/admin_web/admin_web_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  static const List<({String key, String label, String description})>
  _permissionOptions = <({String key, String label, String description})>[
    (
      key: adminPermissionOverview,
      label: 'Tổng quan',
      description: 'Xem dashboard vận hành',
    ),
    (
      key: adminPermissionUsers,
      label: 'Người dùng',
      description: 'Quản lý tài khoản và phân quyền',
    ),
    (
      key: adminPermissionCategories,
      label: 'Danh mục',
      description: 'Quản lý danh mục hệ thống',
    ),
    (
      key: adminPermissionBroadcasts,
      label: 'Thông báo',
      description: 'Gửi và chỉnh sửa thông báo',
    ),
    (
      key: adminPermissionSystemConfigs,
      label: 'Cấu hình',
      description: 'Quản lý cấu hình hệ thống',
    ),
    (
      key: adminPermissionAiConfig,
      label: 'Cấu hình AI',
      description: 'Quản lý runtime AI và lexicon',
    ),
    (
      key: adminPermissionTransactions,
      label: 'Giao dịch',
      description: 'Xem giao dịch toàn hệ thống',
    ),
    (
      key: adminPermissionReports,
      label: 'Báo cáo',
      description: 'Xem báo cáo tổng hợp',
    ),
  ];

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

  Future<void> _showPermissionDialog(AdminUserRecord user) async {
    String selectedRole = user.role;
    final selectedPermissions = <String>{
      ...normalizeAdminPermissions(user.role, user.permissions),
    };
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void syncPermissionsForRole(String role) {
              selectedPermissions
                ..clear()
                ..addAll(defaultPermissionsForRole(role));
            }

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.admin_panel_settings_rounded),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Phân quyền cho ${user.name}')),
                ],
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(labelText: 'Vai trò'),
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
                            child: Text('Super admin'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDialogState(() {
                                  selectedRole = value;
                                  syncPermissionsForRole(value);
                                });
                              },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Quyền chi tiết',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Super admin luôn có toàn quyền. Với admin thường, bạn có thể chọn từng khu vực được phép truy cập.',
                        style: TextStyle(color: Color(0xFF64748B), height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      ..._permissionOptions.map((option) {
                        final forcedByRole = selectedRole == 'super_admin';
                        final enabled = selectedRole != 'user' && !forcedByRole;
                        final checked = forcedByRole
                            ? true
                            : selectedPermissions.contains(option.key);

                        return CheckboxListTile(
                          value: checked,
                          onChanged: !enabled || saving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      selectedPermissions.add(option.key);
                                    } else {
                                      selectedPermissions.remove(option.key);
                                    }
                                  });
                                },
                          title: Text(option.label),
                          subtitle: Text(option.description),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          setDialogState(() {
                            saving = true;
                          });
                          try {
                            await widget.repository.updateUserAuthorization(
                              uid: user.id,
                              role: selectedRole,
                              permissions: selectedPermissions.toList(),
                            );
                            if (!mounted) return;
                            Navigator.pop(context);
                          } on FirebaseException catch (error) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.message ??
                                      'Không thể lưu phân quyền lúc này.',
                                ),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setDialogState(() {
                                saving = false;
                              });
                            }
                          }
                        },
                  icon: saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Lưu phân quyền'),
                ),
              ],
            );
          },
        );
      },
    );
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
                child: Text('Super admin'),
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
                              const SizedBox(width: 8),
                              _buildPermissionSummaryPill(user),
                              const SizedBox(width: 12),
                              AdminStatusPill(status: user.status),
                              const SizedBox(width: 24),
                              if (widget.profile.isSuperAdmin)
                                FilledButton.tonalIcon(
                                  onPressed: () => _showPermissionDialog(user),
                                  icon: const Icon(
                                    Icons.admin_panel_settings_outlined,
                                  ),
                                  label: const Text('Phân quyền'),
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

  Widget _buildPermissionSummaryPill(AdminUserRecord user) {
    final count = user.permissions.length;
    final label = user.role == 'user'
        ? 'Không có quyền'
        : user.role == 'super_admin'
        ? 'Toàn quyền'
        : '$count quyền';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
