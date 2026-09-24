import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_fonts.dart';
import '../../core/config/app_shape.dart';
import 'glass/ios_glass.dart';

Future<String?> showTextInputDialog(
  BuildContext context, {
  String? title,
  String? description,
  String? hint,
  String? initialValue,
  String confirmLabel = 'Подтвердить',
  String cancelLabel = 'Отмена',
  bool obscureText = false,
  int maxLines = 1,
  TextInputType? keyboardType,
}) async {
  final tec = TextEditingController(text: initialValue);
  try {
    if (IosGlass.of(context)) {
      final submitted = await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return CupertinoAlertDialog(
            title: title == null ? null : Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (description != null) ...[
                  Text(description),
                  const SizedBox(height: 12),
                ],
                CupertinoTextField(
                  controller: tec,
                  autofocus: true,
                  obscureText: obscureText,
                  maxLines: obscureText ? 1 : maxLines,
                  keyboardType: keyboardType,
                  placeholder: hint,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  onSubmitted: (_) {
                    final t = tec.text.trim();
                    Navigator.pop(dialogContext, t.isNotEmpty);
                  },
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(dialogContext, false),
                isDefaultAction: false,
                child: Text(cancelLabel),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  final t = tec.text.trim();
                  Navigator.pop(dialogContext, t.isNotEmpty);
                },
                isDefaultAction: true,
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      );
      if (submitted != true) return null;
      final t = tec.text.trim();
      return t.isEmpty ? null : t;
    }

    return await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerHigh,
          shape: AppShape.dialogBorder,
          title: title == null
              ? null
              : Text(
                  title,
                  style: TextStyle(
                    fontFamily: displayFontOf(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: cs.onSurface,
                  ),
                ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description != null) ...[
                Text(
                  description,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
              ],
              TextField(
                controller: tec,
                autofocus: true,
                obscureText: obscureText,
                maxLines: obscureText ? 1 : maxLines,
                keyboardType: keyboardType,
                decoration: InputDecoration(hintText: hint),
                onSubmitted: (v) {
                  final t = v.trim();
                  Navigator.pop(dialogContext, t.isEmpty ? null : t);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                cancelLabel,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () {
                final t = tec.text.trim();
                Navigator.pop(dialogContext, t.isEmpty ? null : t);
              },
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  } finally {
    tec.dispose();
  }
}
