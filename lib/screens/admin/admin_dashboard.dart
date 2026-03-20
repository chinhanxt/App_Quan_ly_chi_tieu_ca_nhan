import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/responsive_layout.dart';
import 'user_management_screen.dart';
import 'category_management_screen.dart';
import 'system_transaction_screen.dart';
import 'system_settings_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND', decimalDigits: 0);
  int _totalTransactions = 0;
  int _usersWithGoals = 0;
  double _totalSavings = 0;
  double _completionRate = 0;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  Future<void> _loadAllStats() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);
    
    try {
      int transCount = 0;
      int goalUserCount = 0;
      double savingSum = 0;
      int completedGoals = 0;
      int totalGoals = 0;

      var users = await FirebaseFirestore.instance.collection('users').get(const GetOptions(source: Source.server));
      
      for (var user in users.docs) {
        var trans = await user.reference.collection('transactions').count().get(source: AggregateSource.server);
        transCount += (trans.count ?? 0).toInt();

        var goals = await user.reference.collection('saving_goals').get(const GetOptions(source: Source.server));
        if (goals.docs.isNotEmpty) {
          goalUserCount++;
          for (var goalDoc in goals.docs) {
            final data = goalDoc.data();
            savingSum += (data['current_amount'] ?? 0).toDouble();
            totalGoals++;
            if (data['status'] == 'completed' || data['status'] == 'withdrawn') {
              completedGoals++;
            }
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _totalTransactions = transCount;
          _usersWithGoals = goalUserCount;
          _totalSavings = savingSum;
          _completionRate = totalGoals > 0 ? (completedGoals / totalGoals) * 100 : 0;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminWebLayout(
      child: RefreshIndicator(
        onRefresh: _loadAllStats,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !_isLoadingStats) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<DocumentSnapshot> userDocs = snapshot.data?.docs ?? [];
            final int totalUsers = userDocs.length;
            final double totalIncome = userDocs.fold(0.0, (total, doc) => total + ((doc.data() as Map<String, dynamic>)['totalCredit'] ?? 0).toDouble());
            final double totalExpense = userDocs.fold(0.0, (total, doc) => total + ((doc.data() as Map<String, dynamic>)['totalDebit'] ?? 0).toDouble());

            return SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Chào buổi sáng, Admin! 👋",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Dưới đây là những gì đang diễn ra với hệ thống của bạn hôm nay.",
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _loadAllStats,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text("Làm mới dữ liệu"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Main Stats Grid
                  LayoutBuilder(builder: (context, constraints) {
                    return GridView.count(
                      crossAxisCount: constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 1.6,
                      children: [
                        _buildModernStatCard("Người dùng", totalUsers.toString(), Icons.people_alt_rounded, const Color(0xFF6366F1)),
                        _buildModernStatCard("Giao dịch", _totalTransactions.toString(), Icons.swap_horizontal_circle_rounded, const Color(0xFFF59E0B)),
                        _buildModernStatCard("Thu nhập", _formatCurrency(totalIncome), Icons.trending_up_rounded, const Color(0xFF10B981)),
                        _buildModernStatCard("Chi tiêu", _formatCurrency(totalExpense), Icons.trending_down_rounded, const Color(0xFFEF4444)),
                      ],
                    );
                  }),
                  
                  const SizedBox(height: 32),
                  const Text("Phân tích tiết kiệm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  
                  // Savings Stats Grid
                  LayoutBuilder(builder: (context, constraints) {
                    return GridView.count(
                      crossAxisCount: constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 2,
                      children: [
                        _buildModernStatCard("User có mục tiêu", _usersWithGoals.toString(), Icons.stars_rounded, const Color(0xFF8B5CF6)),
                        _buildModernStatCard("Tổng quỹ tiết kiệm", _formatCurrency(_totalSavings), Icons.account_balance_wallet_rounded, const Color(0xFF06B6D4)),
                        _buildModernStatCard("Tỷ lệ hoàn thành", "${_completionRate.toStringAsFixed(1)}%", Icons.verified_rounded, const Color(0xFFEC4899)),
                      ],
                    );
                  }),

                  const SizedBox(height: 40),
                  const Text("Lối tắt quản lý", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  _buildQuickAccessMenu(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return currencyFormat.format(amount);
  }

  Widget _buildModernStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(icon, size: 80, color: color.withOpacity(0.03)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessMenu(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return GridView.count(
        crossAxisCount: constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 600 ? 2 : 1),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.5,
        children: [
          _buildQuickItem(context, "Người dùng", Icons.people_rounded, const Color(0xFF6366F1), const UserManagementScreen()),
          _buildQuickItem(context, "Danh mục", Icons.category_rounded, const Color(0xFF8B5CF6), const CategoryManagementScreen()),
          _buildQuickItem(context, "Giao dịch", Icons.receipt_long_rounded, const Color(0xFF10B981), const SystemTransactionScreen()),
          _buildQuickItem(context, "Cấu hình", Icons.settings_suggest_rounded, const Color(0xFF64748B), const SystemSettingsScreen()),
        ],
      );
    });
  }

  Widget _buildQuickItem(BuildContext context, String title, IconData icon, Color color, Widget screen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF334155)),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}
