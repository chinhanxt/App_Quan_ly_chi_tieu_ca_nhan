import 'dart:async';

import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/admin_web/admin_web_widgets.dart';
import 'package:app/utils/runtime_schedule.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SystemConfigsPage extends StatefulWidget {
  const SystemConfigsPage({super.key, required this.repository});

  final AdminWebRepository repository;

  @override
  State<SystemConfigsPage> createState() => _SystemConfigsPageState();
}

class _SystemConfigsPageState extends State<SystemConfigsPage> {
  Timer? _refreshTimer;
  DateTime? _scheduledTick;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleRealtimeRefresh(Map<String, dynamic> controlsData) {
    final nextTick = nextMaintenanceTransitionAt(controlsData);
    if (_scheduledTick == nextTick) {
      return;
    }

    _refreshTimer?.cancel();
    _scheduledTick = nextTick;
    if (nextTick == null) {
      return;
    }

    final delay = nextTick.difference(DateTime.now()) + const Duration(seconds: 1);
    _refreshTimer = Timer(
      delay.isNegative ? const Duration(seconds: 1) : delay,
      () {
        if (!mounted) {
          return;
        }
        setState(() {
          _scheduledTick = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Mục này hiện tập trung cho thông tin liên hệ và các tham số vận hành cơ bản.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _showContactConfigDialog(context),
              icon: const Icon(Icons.contact_support_rounded, size: 18),
              label: const Text('Cài đặt liên hệ'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Có thể làm tiếp ở mục cấu hình',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 8),
              Text('• Bật hoặc tắt chế độ bảo trì'),
              Text('• Cấu hình giờ làm việc và khung hỗ trợ'),
              Text('• Bật hoặc tắt đăng ký tài khoản mới'),
              Text('• Nội dung hướng dẫn, chính sách và trợ giúp'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: AdminPanel(
            child: StreamBuilder<List<SystemConfigRecord>>(
              stream: widget.repository.watchSystemConfigs(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final contactMatches = snapshot.data!
                    .where((item) => item.id == 'contact_info')
                    .toList(growable: false);
                final controlMatches = snapshot.data!
                    .where((item) => item.id == 'app_controls')
                    .toList(growable: false);
                final SystemConfigRecord? contactInfo =
                    contactMatches.isEmpty ? null : contactMatches.first;
                final SystemConfigRecord? appControls =
                    controlMatches.isEmpty ? null : controlMatches.first;
                final controlsData = appControls?.data ?? const <String, dynamic>{};
                _scheduleRealtimeRefresh(controlsData);
                final maintenanceMode =
                    controlsData['maintenanceModeManual'] == true ||
                    controlsData['maintenanceMode'] == true;
                final allowRegistration =
                    controlsData['allowNewRegistration'] != false;
                final maintenanceScheduleEnabled =
                    controlsData['maintenanceScheduleEnabled'] == true;
                final maintenanceStartAt =
                    readRuntimeDateTime(controlsData['maintenanceStartAt']);
                final maintenanceEndAt =
                    readRuntimeDateTime(controlsData['maintenanceEndAt']);
                final scheduledMaintenanceActive = isSingleWindowActive(
                  enabled: maintenanceScheduleEnabled,
                  now: DateTime.now(),
                  startAt: maintenanceStartAt,
                  endAt: maintenanceEndAt,
                );

                return ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: maintenanceMode,
                            onChanged: (value) {
                              widget.repository.saveSystemConfig(
                                'app_controls',
                                <String, dynamic>{
                                  ...controlsData,
                                  'maintenanceMode': value,
                                  'maintenanceModeManual': value,
                                  'allowNewRegistration': allowRegistration,
                                },
                              );
                            },
                            title: const Text(
                              'Bật chế độ bảo trì',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: const Text(
                              'Khi bật, toàn bộ người dùng sẽ bị chặn vào ứng dụng cho tới khi tắt lại.',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 12),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    maintenanceScheduleEnabled &&
                                            maintenanceStartAt != null &&
                                            maintenanceEndAt != null
                                        ? 'Lịch bảo trì: ${_formatWindow(maintenanceStartAt, maintenanceEndAt)}'
                                        : 'Chưa đặt lịch bảo trì tự động',
                                    style: const TextStyle(
                                      color: Color(0xFF475467),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (scheduledMaintenanceActive)
                                    const AdminRolePill(label: 'ĐANG HIỆU LỰC'),
                                  OutlinedButton.icon(
                                    onPressed: () => _showMaintenanceScheduleDialog(
                                      context,
                                      controlsData: controlsData,
                                      allowRegistration: allowRegistration,
                                    ),
                                    icon: const Icon(Icons.schedule_rounded, size: 18),
                                    label: const Text('Thiết lập giờ bật/tắt'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 28),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: allowRegistration,
                            onChanged: (value) {
                              widget.repository.saveSystemConfig(
                                'app_controls',
                                <String, dynamic>{
                                  ...controlsData,
                                  'maintenanceMode': maintenanceMode,
                                  'maintenanceModeManual': maintenanceMode,
                                  'allowNewRegistration': value,
                                },
                              );
                            },
                            title: const Text(
                              'Cho phép đăng ký tài khoản mới',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: const Text(
                              'Khi tắt, người dùng mới sẽ không thể tạo tài khoản từ màn đăng ký.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (contactInfo == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text('Chưa có thông tin liên hệ nào được thiết lập.'),
                        ),
                      )
                    else
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Row(
                          children: [
                            Icon(
                              Icons.contact_mail_rounded,
                              size: 20,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Thông tin liên hệ',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: AdminRolePill(label: 'HIỂN THỊ CHO NGƯỜI DÙNG'),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: SelectableText(
                              widget.repository.prettyJson(contactInfo.data),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12.5,
                                height: 1.5,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.edit_note_rounded,
                            color: Colors.blue,
                          ),
                          onPressed: () => _showContactConfigDialog(
                            context,
                            record: contactInfo,
                          ),
                          tooltip: 'Chỉnh sửa',
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatWindow(DateTime startAt, DateTime endAt) {
    return '${DateFormat('HH:mm dd/MM/yyyy').format(startAt)} -> ${DateFormat('HH:mm dd/MM/yyyy').format(endAt)}';
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context, {
    required DateTime initialValue,
    required String helpText,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialValue,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      locale: const Locale('vi', 'VN'),
      helpText: helpText,
    );
    if (pickedDate == null || !context.mounted) {
      return null;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialValue),
      helpText: helpText,
    );
    if (pickedTime == null) {
      return null;
    }

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _showMaintenanceScheduleDialog(
    BuildContext context, {
    required Map<String, dynamic> controlsData,
    required bool allowRegistration,
  }) async {
    var scheduleEnabled = controlsData['maintenanceScheduleEnabled'] == true;
    DateTime? startAt = readRuntimeDateTime(controlsData['maintenanceStartAt']);
    DateTime? endAt = readRuntimeDateTime(controlsData['maintenanceEndAt']);
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.schedule_rounded, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Thiết lập lịch bảo trì'),
                ],
              ),
              content: SizedBox(
                width: 560,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: scheduleEnabled,
                      onChanged: (value) {
                        setDialogState(() {
                          scheduleEnabled = value;
                          errorText = null;
                        });
                      },
                      title: const Text('Bật lịch bảo trì tự động'),
                      subtitle: const Text(
                        'Trong khoảng đã cài, người dùng sẽ tự động bị chặn truy cập.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await _pickDateTime(
                                dialogContext,
                                initialValue: startAt ?? DateTime.now(),
                                helpText: 'Chọn thời điểm bắt đầu',
                              );
                              if (picked == null) return;
                              setDialogState(() {
                                startAt = picked;
                                errorText = null;
                              });
                            },
                            icon: const Icon(Icons.play_circle_outline_rounded),
                            label: Text(
                              startAt == null
                                  ? 'Chọn giờ bắt đầu'
                                  : DateFormat('HH:mm dd/MM/yyyy').format(startAt!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await _pickDateTime(
                                dialogContext,
                                initialValue:
                                    endAt ??
                                    (startAt ?? DateTime.now()).add(
                                      const Duration(hours: 1),
                                    ),
                                helpText: 'Chọn thời điểm kết thúc',
                              );
                              if (picked == null) return;
                              setDialogState(() {
                                endAt = picked;
                                errorText = null;
                              });
                            },
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: Text(
                              endAt == null
                                  ? 'Chọn giờ kết thúc'
                                  : DateFormat('HH:mm dd/MM/yyyy').format(endAt!),
                            ),
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (scheduleEnabled) {
                      if (startAt == null || endAt == null) {
                        setDialogState(() {
                          errorText = 'Cần chọn đủ giờ bắt đầu và kết thúc.';
                        });
                        return;
                      }
                      if (!endAt!.isAfter(startAt!)) {
                        setDialogState(() {
                          errorText = 'Giờ kết thúc phải sau giờ bắt đầu.';
                        });
                        return;
                      }
                    }

                    await widget.repository.saveSystemConfig(
                      'app_controls',
                      <String, dynamic>{
                        ...controlsData,
                        'maintenanceMode':
                            controlsData['maintenanceModeManual'] == true ||
                                controlsData['maintenanceMode'] == true,
                        'maintenanceModeManual':
                            controlsData['maintenanceModeManual'] == true ||
                                controlsData['maintenanceMode'] == true,
                        'allowNewRegistration': allowRegistration,
                        'maintenanceScheduleEnabled': scheduleEnabled,
                        'maintenanceStartAt': scheduleEnabled ? startAt : null,
                        'maintenanceEndAt': scheduleEnabled ? endAt : null,
                      },
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Lưu lịch'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showContactConfigDialog(
    BuildContext context, {
    SystemConfigRecord? record,
  }) async {
    final emailController = TextEditingController(
      text: record?.data['email']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: record?.data['phone']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: record?.data['address']?.toString() ?? '',
    );
    final facebookController = TextEditingController(
      text: record?.data['facebook']?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.contact_support_rounded, color: Colors.blue),
            SizedBox(width: 12),
            Text('Cấu hình thông tin liên hệ'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Thông tin này sẽ hiển thị trực tiếp trong mục thông tin liên hệ của ứng dụng người dùng.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email hỗ trợ',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại hỗ trợ',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ văn phòng',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: facebookController,
                  decoration: const InputDecoration(
                    labelText: 'Liên kết Facebook hoặc fanpage',
                    prefixIcon: Icon(Icons.link_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final data = <String, dynamic>{
                'email': emailController.text.trim(),
                'phone': phoneController.text.trim(),
                'address': addressController.text.trim(),
                'facebook': facebookController.text.trim(),
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              };
              await widget.repository.saveSystemConfig('contact_info', data);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cập nhật ngay'),
          ),
        ],
      ),
    );
  }
}
