import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/utils/app_colors.dart';
import 'package:flutter/material.dart';

// Model SystemMessage đã được định nghĩa trong system_settings_screen.dart
import '../screens/admin/system_settings_screen.dart';

class SystemBroadcastWidget extends StatefulWidget {
  const SystemBroadcastWidget({super.key});

  @override
  State<SystemBroadcastWidget> createState() => _SystemBroadcastWidgetState();
}

class _SystemBroadcastWidgetState extends State<SystemBroadcastWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('system_broadcasts')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          // Xóa limit(1) để lấy tất cả thông báo active
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final messages = snapshot.data!.docs
            .map((doc) => SystemMessage.fromFirestore(doc))
            .toList();

        return Column(
          children: [
            SizedBox(
              height: 80, // Chiều cao cho vùng trượt thông báo
              child: PageView.builder(
                controller: _pageController,
                itemCount: messages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildMessageBanner(messages[index]);
                },
              ),
            ),
            // Dấu chấm chỉ báo trang
            if (messages.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(messages.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    height: 8.0,
                    width: _currentPage == index ? 24.0 : 8.0,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.accentStrong
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }),
              ),
            const SizedBox(height: 12), // Khoảng cách với widget bên dưới
          ],
        );
      },
    );
  }

  Color _getBannerColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green.withOpacity(0.1);
      case 'warning':
        return Colors.orange.withOpacity(0.1);
      case 'info':
      default:
        return AppColors.accentSoft;
    }
  }

  Color _getBorderColor(String type) {
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

  IconData _getIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'info':
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildMessageBanner(SystemMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _getBannerColor(message.type),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _getBorderColor(message.type).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _getBorderColor(message.type).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getIcon(message.type),
              color: _getBorderColor(message.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.content,
              style: TextStyle(
                color: _getBorderColor(message.type).withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
