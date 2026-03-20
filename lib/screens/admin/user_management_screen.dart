import 'package:flutter/material.dart';
import '../../../widgets/responsive_layout.dart';
import './web/user_management_web.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildMobileBody(context),
      desktopBody: const AdminWebLayout(child: UserManagementWebScreen()),
    );
  }

  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý người dùng"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Tìm kiếm theo email hoặc tên...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Không có người dùng nào."));
                }

                var docs = snapshot.data!.docs.where((doc) {
                  var email = (doc.data() as Map<String, dynamic>)['email'] ?? "";
                  return email.toString().toLowerCase().contains(_searchQuery);
                }).toList();

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    var userData = docs[index].data() as Map<String, dynamic>;
                    String userId = docs[index].id;
                    String email = userData['email'] ?? "N/A";
                    String name = userData['name'] ?? userData['username'] ?? "User";
                    String role = userData['role'] ?? 'user';
                    String status = userData['status'] ?? 'active';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: role == 'admin' ? Colors.red[100] : Colors.blue[100],
                        child: Icon(
                          role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                          color: role == 'admin' ? Colors.red : Colors.blue,
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildBadge(role.toUpperCase(), role == 'admin' ? Colors.red : Colors.blue),
                              const SizedBox(width: 8),
                              _buildBadge(status.toUpperCase(), status == 'active' ? Colors.green : Colors.grey),
                            ],
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditUserDialog(context, userId, userData),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, String userId, Map<String, dynamic> userData) {
    String currentRole = userData['role'] ?? 'user';
    String currentStatus = userData['status'] ?? 'active';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Chỉnh sửa: ${userData['email']}"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: currentRole,
                    decoration: const InputDecoration(labelText: "Vai trò"),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text("User")),
                      DropdownMenuItem(value: 'admin', child: Text("Admin")),
                    ],
                    onChanged: (value) => setDialogState(() => currentRole = value!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: currentStatus,
                    decoration: const InputDecoration(labelText: "Trạng thái"),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text("Hoạt động")),
                      DropdownMenuItem(value: 'locked', child: Text("Khóa")),
                    ],
                    onChanged: (value) => setDialogState(() => currentStatus = value!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('users').doc(userId).update({
                      'role': currentRole,
                      'status': currentStatus,
                    });
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text("Lưu thay đổi"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
