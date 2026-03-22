import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminSidebarTile extends StatelessWidget {
  const AdminSidebarTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? const Color(0xFFD6B872) : Colors.white70,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.child,
    this.title,
    this.isExpanded = true, // Thêm flag để kiểm soát Expanded
  });

  final String? title;
  final Widget child;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (isExpanded)
            Expanded(child: child)
          else
            child,
        ],
      ),
    );
  }
}

class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.note,
    required this.tint,
    required this.icon,
  });

  final String label;
  final String value;
  final String note;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: const TextStyle(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminToolbar extends StatelessWidget {
  const AdminToolbar({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.onSearchChanged,
    required this.trailing,
  });

  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          trailing,
        ],
      ),
    );
  }
}

class AdminCrudFrame extends StatelessWidget {
  const AdminCrudFrame({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: AdminPanel(
            isExpanded: true,
            child: child,
          ),
        ),
      ],
    );
  }
}

class AdminRolePill extends StatelessWidget {
  const AdminRolePill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4338CA),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final active = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFECFDF3) : const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Hoạt động' : 'Bị khóa',
        style: TextStyle(
          color: active ? const Color(0xFF039855) : const Color(0xFFD92D20),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

String adminCurrency(num value) {
  final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  return formatter.format(value);
}

Color broadcastColor(String type) {
  switch (type) {
    case 'success':
      return const Color(0xFF039855);
    case 'warning':
      return const Color(0xFFDC6803);
    case 'info':
    default:
      return const Color(0xFF155EEF);
  }
}

Map<String, AdminUserRecord> usersById(List<AdminUserRecord> users) {
  return <String, AdminUserRecord>{for (final user in users) user.id: user};
}
