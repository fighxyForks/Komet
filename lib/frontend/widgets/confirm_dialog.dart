import 'package:flutter/material.dart';

import 'glass/ios_alert.dart';

/// Shared confirmation dialog. Returns true if confirmed, false otherwise.
Future<bool> showConfirmDialog(
  BuildContext context, {
  String? title,
  required String message,
  String confirmLabel = 'OK',
  String cancelLabel = 'Отмена',
  bool destructive = false,
}) async {
  final result = await showIosAlert<bool>(
    context: context,
    title: title,
    message: message,
    actions: [
      IosAlertAction(
        id: 'cancel',
        label: cancelLabel,
        result: false,
        isCancel: true,
      ),
      IosAlertAction(
        id: 'confirm',
        label: confirmLabel,
        result: true,
        isDestructive: destructive,
        isDefault: !destructive,
      ),
    ],
  );
  return result ?? false;
}
