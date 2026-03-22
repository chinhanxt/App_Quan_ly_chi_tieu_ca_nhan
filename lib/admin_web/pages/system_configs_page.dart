import 'package:app/admin_web/admin_web_repository.dart';
import 'package:app/admin_web/admin_web_widgets.dart';
import 'package:flutter/material.dart';

class SystemConfigsPage extends StatefulWidget {
  const SystemConfigsPage({super.key, required this.repository});

  final AdminWebRepository repository;

  @override
  State<SystemConfigsPage> createState() => _SystemConfigsPageState();
}

class _SystemConfigsPageState extends State<SystemConfigsPage> {
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
                final maintenanceMode = controlsData['maintenanceMode'] == true;
                final allowRegistration =
                    controlsData['allowNewRegistration'] != false;

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
