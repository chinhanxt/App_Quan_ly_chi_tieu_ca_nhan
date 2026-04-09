import 'package:app/models/app_notification.dart';
import 'package:app/services/notification_service.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/widgets/app_chrome.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.initialNotificationId,
  });

  final String? initialNotificationId;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _expandedId = widget.initialNotificationId;
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<NotificationService>();
    final notifications = service.activeNotifications;

    return AppScaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      child: notifications.isEmpty
          ? const AppEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Chưa có thông báo',
              message: 'Thông báo mới sẽ xuất hiện tại đây để bạn xem lại.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = notifications[index];
                final isExpanded = _expandedId == item.id;

                return _NotificationExpansionCard(
                  notification: item,
                  isExpanded: isExpanded,
                  onTap: () async {
                    final nextExpanded = isExpanded ? null : item.id;
                    setState(() {
                      _expandedId = nextExpanded;
                    });
                    if (nextExpanded != null && item.isUnread) {
                      await context.read<NotificationService>().markAsRead(item.id);
                    }
                  },
                  onAction: item.hasAction
                      ? () => context
                          .read<NotificationService>()
                          .openNotificationAction(item)
                      : null,
                );
              },
            ),
    );
  }
}

class _NotificationExpansionCard extends StatelessWidget {
  const _NotificationExpansionCard({
    required this.notification,
    required this.isExpanded,
    required this.onTap,
    this.onAction,
  });

  final AppNotification notification;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: notification.isUnread
                          ? Colors.green
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: notification.isUnread
                          ? null
                          : Border.all(
                              color: AppColors.textMuted.withValues(alpha: 0.20),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.shortTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: isExpanded ? 0.5 : 0,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.detailTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      height: 1.55,
                    ),
                  ),
                  if (onAction != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(notification.actionLabel ?? 'Mở liên kết'),
                    ),
                  ],
                  if (!notification.isSystemNotification) ...[
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => context
                          .read<NotificationService>()
                          .suppressForToday(notification.id),
                      child: const Text('Không nhắc lại hôm nay'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
