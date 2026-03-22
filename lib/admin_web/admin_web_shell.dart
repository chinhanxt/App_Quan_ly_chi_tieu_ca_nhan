import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/admin_web/admin_web_widgets.dart';
import 'package:app/admin_web/pages/ai_config_page.dart';
import 'package:app/admin_web/pages/broadcasts_page.dart';
import 'package:app/admin_web/pages/categories_page.dart';
import 'package:app/admin_web/pages/overview_page.dart';
import 'package:app/admin_web/pages/reports_page.dart';
import 'package:app/admin_web/pages/system_configs_page.dart';
import 'package:app/admin_web/pages/transactions_page.dart';
import 'package:app/admin_web/pages/users_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum AdminSection {
  overview,
  users,
  categories,
  broadcasts,
  systemConfigs,
  aiConfig,
  transactions,
  reports,
}

class AdminWebShell extends StatefulWidget {
  const AdminWebShell({
    super.key,
    required this.profile,
    required this.repository,
  });

  final AdminProfile profile;
  final AdminWebRepository repository;

  @override
  State<AdminWebShell> createState() => _AdminWebShellState();
}

class _AdminWebShellState extends State<AdminWebShell> {
  AdminSection _current = AdminSection.overview;

  @override
  Widget build(BuildContext context) {
    final items = <({AdminSection section, String label, IconData icon})>[
      (
        section: AdminSection.overview,
        label: 'Tổng quan',
        icon: Icons.dashboard_customize_rounded,
      ),
      (
        section: AdminSection.users,
        label: 'Người dùng',
        icon: Icons.people_alt_rounded,
      ),
      (
        section: AdminSection.categories,
        label: 'Danh mục',
        icon: Icons.category_rounded,
      ),
      (
        section: AdminSection.broadcasts,
        label: 'Thông báo',
        icon: Icons.campaign_rounded,
      ),
      (
        section: AdminSection.systemConfigs,
        label: 'Cấu hình',
        icon: Icons.settings_suggest_rounded,
      ),
      (
        section: AdminSection.aiConfig,
        label: 'Cấu hình AI',
        icon: Icons.psychology_alt_rounded,
      ),
      (
        section: AdminSection.transactions,
        label: 'Giao dịch',
        icon: Icons.receipt_long_rounded,
      ),
      (
        section: AdminSection.reports,
        label: 'Báo cáo',
        icon: Icons.assessment_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E7),
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 286,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFF112321),
                  Color(0xFF18312E),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            color: Color(0xFFD6B872),
                            size: 30,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Quản trị tài chính',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.profile.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.profile.email,
                            style: const TextStyle(
                              color: Color(0xFFD1D5DB),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AdminRolePill(label: widget.profile.role),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return AdminSidebarTile(
                            key: ValueKey('sidebar_${item.section.name}'),
                            label: item.label,
                            icon: item.icon,
                            selected: _current == item.section,
                            onTap: () {
                              if (_current == item.section) return;
                              setState(() {
                                _current = item.section;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 32),
                    Material(
                      color: Colors.transparent,
                      child: OutlinedButton.icon(
                        onPressed: widget.repository.signOut,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Đăng xuất'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 76,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        _sectionTitle(_current),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF172221),
                          letterSpacing: -1,
                        ),
                      ),
                      const Spacer(),
                      // Fix potential null locale error by using default format
                      Text(
                        DateFormat('EEEE, dd/MM/yyyy').format(DateTime.now()),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Material(
                      color: Colors.transparent,
                      child: IndexedStack(
                        index: _current.index,
                        children: [
                          OverviewPage(repository: widget.repository),
                          UsersPage(
                            repository: widget.repository,
                            profile: widget.profile,
                          ),
                          CategoriesPage(repository: widget.repository),
                          BroadcastsPage(repository: widget.repository),
                          SystemConfigsPage(repository: widget.repository),
                          AiConfigPage(
                            repository: widget.repository,
                            profile: widget.profile,
                          ),
                          TransactionsPage(repository: widget.repository),
                          ReportsPage(repository: widget.repository),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _sectionTitle(AdminSection section) {
    switch (section) {
      case AdminSection.overview: return 'Tổng quan hệ thống';
      case AdminSection.users: return 'Quản lý người dùng';
      case AdminSection.categories: return 'Danh mục hệ thống';
      case AdminSection.broadcasts: return 'Thông báo hệ thống';
      case AdminSection.systemConfigs: return 'Cấu hình hệ thống';
      case AdminSection.aiConfig: return 'Cấu hình AI';
      case AdminSection.transactions: return 'Giao dịch toàn hệ thống';
      case AdminSection.reports: return 'Báo cáo tổng hợp';
    }
  }
}
