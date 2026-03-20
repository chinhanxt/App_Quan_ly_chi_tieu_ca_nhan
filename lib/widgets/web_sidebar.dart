import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/screens/login_screen.dart';
import 'package:app/screens/admin/admin_dashboard.dart';
import 'package:app/screens/admin/user_management_screen.dart';
import 'package:app/screens/admin/category_management_screen.dart';
import 'package:app/screens/admin/system_transaction_screen.dart';
import 'package:app/screens/admin/system_settings_screen.dart';

class WebSidebar extends StatelessWidget {
  const WebSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Deep Navy / Slate 900
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(4, 0))
        ],
      ),
      child: Column(
        children: [
          // Logo Area
          Container(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1), // Indigo 500
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  "FINANCE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSectionLabel("CHÍNH"),
                _buildSidebarItem(context, "Tổng quan", Icons.grid_view_rounded, const AdminDashboard(), true),
                _buildSidebarItem(context, "Người dùng", Icons.group_outlined, const UserManagementScreen(), false),
                
                const SizedBox(height: 24),
                _buildSectionLabel("QUẢN LÝ"),
                _buildSidebarItem(context, "Danh mục", Icons.category_outlined, const CategoryManagementScreen(), false),
                _buildSidebarItem(context, "Giao dịch", Icons.receipt_long_outlined, const SystemTransactionScreen(), false),
                
                const SizedBox(height: 24),
                _buildSectionLabel("HỆ THỐNG"),
                _buildSidebarItem(context, "Cấu hình", Icons.tune_rounded, const SystemSettingsScreen(), false),
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8)),
                title: const Text(
                  "Đăng xuất",
                  style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginView()));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12, top: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, String title, IconData icon, Widget screen, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        selected: isActive,
        selectedTileColor: const Color(0xFF6366F1).withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: isActive ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () {
          if (MediaQuery.of(context).size.width < 1100) {
            Navigator.pop(context);
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
      ),
    );
  }
}
