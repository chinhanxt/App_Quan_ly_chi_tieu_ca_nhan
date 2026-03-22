import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/admin_web/admin_web_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BroadcastsPage extends StatefulWidget {
  const BroadcastsPage({super.key, required this.repository});

  final AdminWebRepository repository;

  @override
  State<BroadcastsPage> createState() => _BroadcastsPageState();
}

class _BroadcastsPageState extends State<BroadcastsPage> {
  String _statusFilter = 'all';
  String _typeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BroadcastRecord>>(
      stream: widget.repository.watchBroadcasts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Không tải được thông báo: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allItems = snapshot.data!;
        final items = allItems.where((item) {
          final statusOk =
              _statusFilter == 'all' || item.status == _statusFilter;
          final typeOk = _typeFilter == 'all' || item.type == _typeFilter;
          return statusOk && typeOk;
        }).toList(growable: false);

        final activeCount = allItems.where((item) => item.status == 'active').length;
        final inactiveCount = allItems.length - activeCount;

        return Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Quản lý thông báo hệ thống hiển thị tới người dùng trong ứng dụng.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF667085),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => _showBroadcastDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tạo thông báo'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Tổng thông báo',
                    value: '${allItems.length}',
                    tint: const Color(0xFF155EEF),
                    icon: Icons.layers_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatTile(
                    label: 'Đang hiển thị',
                    value: '$activeCount',
                    tint: const Color(0xFF039855),
                    icon: Icons.campaign_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatTile(
                    label: 'Tạm ẩn',
                    value: '$inactiveCount',
                    tint: const Color(0xFFDC6803),
                    icon: Icons.visibility_off_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(labelText: 'Trạng thái'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'active', child: Text('Đang hiển thị')),
                      DropdownMenuItem(value: 'inactive', child: Text('Tạm ẩn')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _statusFilter = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _typeFilter,
                    decoration: const InputDecoration(labelText: 'Loại'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'info', child: Text('Thông tin')),
                      DropdownMenuItem(value: 'success', child: Text('Tích cực')),
                      DropdownMenuItem(value: 'warning', child: Text('Cảnh báo')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _typeFilter = value;
                      });
                    },
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length} kết quả',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AdminPanel(
                      title: 'Danh sách thông báo',
                      child: items.isEmpty
                          ? const Center(
                              child: Text('Chưa có thông báo phù hợp với bộ lọc.'),
                            )
                          : ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 24),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return _BroadcastRow(
                                  item: item,
                                  onToggle: (value) => widget.repository
                                      .toggleBroadcastStatus(item.id, value),
                                  onEdit: () => _showBroadcastDialog(
                                    context,
                                    record: item,
                                  ),
                                  onDelete: () =>
                                      _confirmDelete(context, item),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 2,
                    child: AdminPanel(
                      title: 'Xem trước trong ứng dụng',
                      isExpanded: false,
                      child: items.isEmpty
                          ? const Text(
                              'Chọn thông báo hoặc bộ lọc để xem trước.',
                            )
                          : Column(
                              children: items.take(3).map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _BroadcastPreviewCard(item: item),
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BroadcastRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thông báo'),
        content: Text(
          'Thông báo "${record.title.trim().isNotEmpty ? record.title : record.content}" sẽ bị xóa vĩnh viễn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.repository.deleteBroadcast(record.id);
    }
  }

  Future<void> _showBroadcastDialog(
    BuildContext context, {
    BroadcastRecord? record,
  }) async {
    final titleController = TextEditingController(text: record?.title ?? '');
    final contentController = TextEditingController(text: record?.content ?? '');
    var type = record?.type ?? 'info';
    var active = record?.status == 'active';
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final previewRecord = BroadcastRecord(
              id: record?.id ?? 'preview',
              title: titleController.text.trim(),
              content: contentController.text.trim(),
              type: type,
              status: active ? 'active' : 'inactive',
              createdAt: record?.createdAt,
              updatedAt: record?.updatedAt,
              createdByEmail: record?.createdByEmail ?? '',
            );

            return AlertDialog(
              title: Text(record == null ? 'Tạo thông báo' : 'Sửa thông báo'),
              content: SizedBox(
                width: 720,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề ngắn',
                        hintText: 'Ví dụ: Bảo trì hệ thống',
                      ),
                      onChanged: (_) {
                        setDialogState(() {
                          errorText = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung',
                        hintText: 'Ví dụ: Hệ thống bảo trì vào 23h tối nay.',
                      ),
                      onChanged: (_) {
                        setDialogState(() {
                          errorText = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: type,
                            decoration: const InputDecoration(labelText: 'Loại'),
                            items: const [
                              DropdownMenuItem(
                                value: 'info',
                                child: Text('Thông tin'),
                              ),
                              DropdownMenuItem(
                                value: 'success',
                                child: Text('Tích cực'),
                              ),
                              DropdownMenuItem(
                                value: 'warning',
                                child: Text('Cảnh báo'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() {
                                type = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: active,
                            onChanged: (value) {
                              setDialogState(() {
                                active = value;
                              });
                            },
                            title: const Text('Hiển thị ngay sau khi lưu'),
                          ),
                        ),
                      ],
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: const TextStyle(
                          color: Color(0xFFD92D20),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'Xem trước',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _BroadcastPreviewCard(item: previewRecord),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () async {
                    final content = contentController.text.trim();
                    if (content.isEmpty) {
                      setDialogState(() {
                        errorText = 'Nội dung thông báo không được để trống.';
                      });
                      return;
                    }

                    await widget.repository.saveBroadcast(
                      id: record?.id,
                      title: titleController.text.trim(),
                      content: content,
                      type: type,
                      active: active,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BroadcastRow extends StatelessWidget {
  const _BroadcastRow({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final BroadcastRecord item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final headline = item.title.trim().isNotEmpty ? item.title : item.content;
    final timestamp = item.updatedAt ?? item.createdAt;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: broadcastColor(item.type).withValues(alpha: 0.12),
                child: Icon(
                  Icons.campaign_rounded,
                  color: broadcastColor(item.type),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.content,
                      style: const TextStyle(
                        color: Color(0xFF475467),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Switch(
                value: item.status == 'active',
                onChanged: onToggle,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TagPill(
                label: item.status == 'active' ? 'Đang hiển thị' : 'Tạm ẩn',
                background: item.status == 'active'
                    ? const Color(0xFFECFDF3)
                    : const Color(0xFFFFF6ED),
                foreground: item.status == 'active'
                    ? const Color(0xFF039855)
                    : const Color(0xFFDC6803),
              ),
              _TagPill(
                label: _broadcastTypeLabel(item.type),
                background: broadcastColor(item.type).withValues(alpha: 0.12),
                foreground: broadcastColor(item.type),
              ),
              if (timestamp != null)
                Text(
                  DateFormat('HH:mm - dd/MM/yyyy').format(timestamp.toDate()),
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              OutlinedButton(
                onPressed: onEdit,
                child: const Text('Sửa'),
              ),
              FilledButton.tonal(
                onPressed: onDelete,
                child: const Text('Xóa'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BroadcastPreviewCard extends StatelessWidget {
  const _BroadcastPreviewCard({required this.item});

  final BroadcastRecord item;

  @override
  Widget build(BuildContext context) {
    final title = item.title.trim();
    final color = broadcastColor(item.type);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.campaign_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Text(
                  item.content.isEmpty ? 'Nội dung sẽ hiển thị ở đây.' : item.content,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.92),
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _broadcastTypeLabel(String type) {
  switch (type) {
    case 'success':
      return 'Tích cực';
    case 'warning':
      return 'Cảnh báo';
    case 'info':
    default:
      return 'Thông tin';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.tint,
    required this.icon,
  });

  final String label;
  final String value;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
