import 'package:app/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';

class LanguageDialog extends StatelessWidget {
  final String currentLanguage;
  final Function(String) onLanguageChanged;

  const LanguageDialog({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Chọn Ngôn Ngữ'),
      children: [
        SimpleDialogOption(
          onPressed: () {
            onLanguageChanged('vi');
            Navigator.pop(context);
          },
          child: Row(
            children: [
              Text('Tiếng Việt'),
              if (currentLanguage == 'vi') const Icon(Icons.check, color: Colors.green),
            ],
          ),
        ),
        SimpleDialogOption(
          onPressed: () {
            onLanguageChanged('en');
            Navigator.pop(context);
          },
          child: Row(
            children: [
              Text('English'),
              if (currentLanguage == 'en') const Icon(Icons.check, color: Colors.green),
            ],
          ),
        ),
      ],
    );
  }
}

class ExportDialog extends StatelessWidget {
  const ExportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Xuất Dữ Liệu'),
      children: [
        SimpleDialogOption(
          onPressed: () {
            // TODO: Implement CSV export
            CustomAlertDialog.show(
              context: context,
              title: 'Tính Năng Đang Phát Triển',
              message: 'Tính năng xuất CSV đang được phát triển',
              type: AlertType.info,
            );
          },
          child: const Text('Xuất ra CSV'),
        ),
        SimpleDialogOption(
          onPressed: () {
            // TODO: Implement PDF export
            CustomAlertDialog.show(
              context: context,
              title: 'Tính Năng Đang Phát Triển',
              message: 'Tính năng xuất PDF đang được phát triển',
              type: AlertType.info,
            );
          },
          child: const Text('Xuất ra PDF'),
        ),
      ],
    );
  }
}

class BackupDialog extends StatelessWidget {
  const BackupDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Sao Lưu Dữ Liệu'),
      children: [
        SimpleDialogOption(
          onPressed: () {
            // TODO: Implement backup
            CustomAlertDialog.show(
              context: context,
              title: 'Tính Năng Đang Phát Triển',
              message: 'Tính năng sao lưu đang được phát triển',
              type: AlertType.info,
            );
          },
          child: const Text('Sao lưu lên Cloud'),
        ),
        SimpleDialogOption(
          onPressed: () {
            // TODO: Implement restore
            CustomAlertDialog.show(
              context: context,
              title: 'Tính Năng Đang Phát Triển',
              message: 'Tính năng khôi phục đang được phát triển',
              type: AlertType.info,
            );
          },
          child: const Text('Khôi phục từ Cloud'),
        ),
      ],
    );
  }
}

class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  State<NotificationSettingsDialog> createState() => _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState extends State<NotificationSettingsDialog> {
  bool dailyReminder = false;
  bool weeklyReport = false;
  bool budgetAlert = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cài Đặt Thông Báo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Nhắc nhở hàng ngày'),
                subtitle: const Text('Nhận thông báo về chi tiêu hàng ngày'),
                value: dailyReminder,
                onChanged: (value) {
                  setState(() {
                    dailyReminder = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Báo cáo tuần'),
                subtitle: const Text('Nhận báo cáo chi tiêu hàng tuần'),
                value: weeklyReport,
                onChanged: (value) {
                  setState(() {
                    weeklyReport = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Cảnh báo ngân sách'),
                subtitle: const Text('Nhận cảnh báo khi vượt ngân sách'),
                value: budgetAlert,
                onChanged: (value) {
                  setState(() {
                    budgetAlert = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Save notification settings
                      CustomAlertDialog.show(
                        context: context,
                        title: 'Đã Lưu',
                        message: 'Cài đặt thông báo đã được lưu',
                        type: AlertType.success,
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Lưu'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}