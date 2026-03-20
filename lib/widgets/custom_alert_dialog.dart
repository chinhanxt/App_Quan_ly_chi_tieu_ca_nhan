import 'package:flutter/material.dart';

enum AlertType { success, error, warning, info }

class CustomAlertDialog {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required AlertType type,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    IconData icon;
    Color iconColor;

    switch (type) {
      case AlertType.success:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        confirmText ??= 'OK';
        break;
      case AlertType.error:
        icon = Icons.error;
        iconColor = Colors.red;
        confirmText ??= 'OK';
        break;
      case AlertType.warning:
        icon = Icons.warning;
        iconColor = Colors.orange;
        confirmText ??= 'Xác Nhận';
        cancelText ??= 'Hủy';
        break;
      case AlertType.info:
        icon = Icons.info;
        iconColor = Colors.blue;
        confirmText ??= 'OK';
        break;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            if (type == AlertType.warning && onCancel != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel();
                },
                child: Text(
                  cancelText!,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onConfirm != null) {
                  onConfirm();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(confirmText!),
            ),
          ],
        );
      },
    );
  }
}