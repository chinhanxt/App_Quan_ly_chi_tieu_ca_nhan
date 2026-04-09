import 'package:app/models/app_notification.dart';
import 'package:app/services/notification_service.dart';
import 'package:app/utils/app_colors.dart';
import 'package:flutter/material.dart';

class GlobalNotificationOverlay extends StatefulWidget {
  const GlobalNotificationOverlay({
    super.key,
    required this.service,
  });

  final NotificationService service;

  @override
  State<GlobalNotificationOverlay> createState() =>
      _GlobalNotificationOverlayState();
}

class _GlobalNotificationOverlayState extends State<GlobalNotificationOverlay> {
  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    if (!service.isSignedIn) {
      return const SizedBox.shrink();
    }

    final mediaQuery = MediaQuery.of(context);
    return Stack(
      children: [
        _buildHeadsUpToast(service.currentHeadsUp, mediaQuery.padding),
      ],
    );
  }

  Widget _buildHeadsUpToast(AppNotification? notification, EdgeInsets padding) {
    return Positioned(
      top: padding.top + 12,
      right: 12,
      child: IgnorePointer(
        ignoring: notification == null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.2, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
          child: notification == null
              ? const SizedBox.shrink()
              : GestureDetector(
                  onTap: () => widget.service.openNotificationsScreen(
                    initialNotificationId: notification.id,
                  ),
                  child: _HeadsUpToast(
                    key: ValueKey<String>(notification.id),
                    notification: notification,
                  ),
                ),
        ),
      ),
    );
  }
}

class _HeadsUpToast extends StatelessWidget {
  const _HeadsUpToast({super.key, required this.notification});

  final AppNotification notification;

  Color get _accentColor {
    switch (notification.severity) {
      case AppNotificationSeverity.warning:
        return const Color(0xFFDC8B13);
      case AppNotificationSeverity.danger:
        return const Color(0xFFD94B4B);
      case AppNotificationSeverity.success:
        return const Color(0xFF2E9B62);
      case AppNotificationSeverity.info:
        return AppColors.accentStrong;
    }
  }

  IconData get _icon {
    switch (notification.severity) {
      case AppNotificationSeverity.warning:
        return Icons.warning_amber_rounded;
      case AppNotificationSeverity.danger:
        return Icons.error_outline_rounded;
      case AppNotificationSeverity.success:
        return Icons.check_circle_outline_rounded;
      case AppNotificationSeverity.info:
        return Icons.notifications_active_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: key,
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _accentColor.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.headsUpText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
