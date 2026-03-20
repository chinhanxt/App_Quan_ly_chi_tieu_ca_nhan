import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/responsive_layout.dart';

// Model cho thông điệp hệ thống
class SystemMessage {
  final String id;
  final String content;
  final String status; // 'active' hoặc 'inactive'
  final String type; // 'info', 'warning', 'success'
  final Timestamp createdAt;

  SystemMessage({
    required this.id,
    required this.content,
    required this.status,
    required this.type,
    required this.createdAt,
  });

  factory SystemMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SystemMessage(
      id: doc.id,
      content: data['content'] ?? '',
      status: data['status'] ?? 'inactive',
      type: data['type'] ?? 'info',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  String _selectedType = 'info'; // Mặc định là 'info'

  Future<void> _addMessage() async {
    if (_messageController.text.isEmpty) return;

    await _firestore.collection('system_broadcasts').add({
      'content': _messageController.text,
      'type': _selectedType,
      'status': 'active', // Mặc định là active khi mới tạo
      'createdAt': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildBody(context),
      desktopBody: AdminWebLayout(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text("Gửi Thông Báo Hệ Thống"),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quản lý Thông điệp & Thông báo",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Các thông điệp có trạng thái 'Active' sẽ được hiển thị trên trang chủ của tất cả người dùng.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildAddMessageCard(),
            const Divider(height: 48),
            const Text(
              "Danh sách Thông điệp đã gửi",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMessagesList(),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  _firestore.collection('system_broadcasts').add({
                    'content': 'Đây là một thông báo test từ Admin!',
                    'type': 'info',
                    'status': 'active',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                },
                child: const Text("Tạo nhanh thông báo Test"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMessageCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Nội dung thông điệp mới...",
                hintText: 'Ví dụ: Hệ thống sẽ bảo trì vào 2h sáng mai.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Loại thông điệp:"),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(value: 'info', child: Text('🔵 Tin tức')),
                    DropdownMenuItem(
                      value: 'success',
                      child: Text('🟢 Thành công'),
                    ),
                    DropdownMenuItem(
                      value: 'warning',
                      child: Text('🟠 Cảnh báo'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addMessage,
                  icon: const Icon(Icons.send),
                  label: const Text("Gửi Đi"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('system_broadcasts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Chưa có thông điệp nào.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var message = SystemMessage.fromFirestore(
              snapshot.data!.docs[index],
            );
            return _buildMessageTile(message);
          },
        );
      },
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'success':
        return Colors.green.shade50;
      case 'warning':
        return Colors.orange.shade50;
      case 'info':
      default:
        return AppColors.accentSoft;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'info':
      default:
        return Icons.info;
    }
  }

  Color _getIconColorForType(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'info':
      default:
        return AppColors.accentStrong;
    }
  }

  Widget _buildMessageTile(SystemMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _getColorForType(message.type),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getColorForType(message.type).withOpacity(0.5),
        ),
      ),
      child: ListTile(
        leading: Icon(
          _getIconForType(message.type),
          color: _getIconColorForType(message.type),
        ),
        title: Text(message.content),
        subtitle: Text(
          'Gửi lúc: ${DateFormat('HH:mm - dd/MM/yyyy').format(message.createdAt.toDate())}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: message.status == 'active',
              onChanged: (value) {
                _firestore
                    .collection('system_broadcasts')
                    .doc(message.id)
                    .update({'status': value ? 'active' : 'inactive'});
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                _firestore
                    .collection('system_broadcasts')
                    .doc(message.id)
                    .delete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
