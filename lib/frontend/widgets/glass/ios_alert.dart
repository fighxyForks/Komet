import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../../../core/config/app_ios_glass.dart';
import '../../../core/config/app_shape.dart';
import '../../../core/utils/haptics.dart';
import '../../motion/ios_haptics.dart';
import 'ios_glass.dart';

/// Action for [showIosAlert].
class IosAlertAction<T> {
  final String id;
  final String label;
  final T? result;
  final bool isDestructive;
  final bool isCancel;
  final bool isDefault;

  const IosAlertAction({
    required this.id,
    required this.label,
    this.result,
    this.isDestructive = false,
    this.isCancel = false,
    this.isDefault = false,
  });
}

/// Adaptive alert: native Liquid Glass / Cupertino on iOS mode, Material otherwise.
///
/// [LiquidGlassAlert] has no text-field API, so prompts and custom [content]
/// always use [CupertinoAlertDialog] (or Material when not in iOS mode).
/// Native presentation is used only when [AppIosGlass.nativeViews] is true and
/// there is no custom content — and always with a Cupertino fallback if the
/// native channel returns null (e.g. tests on Linux).
Future<T?> showIosAlert<T>({
  required BuildContext context,
  String? title,
  String? message,
  List<IosAlertAction<T>> actions = const [],
  Widget? content,
  bool barrierDismissible = true,
}) async {
  final ios = IosGlass.of(context);
  if (actions.any((a) => a.isDestructive)) {
    if (ios) {
      IosHaptics.destructiveActivate();
    } else {
      Haptics.medium();
    }
  }

  if (!ios) {
    return _showMaterialAlert<T>(
      context: context,
      title: title,
      message: message,
      actions: actions,
      content: content,
      barrierDismissible: barrierDismissible,
    );
  }

  if (content == null &&
      AppIosGlass.nativeViews) {
    final nativeActions = [
      for (final a in actions)
        LiquidGlassAlertAction(
          id: a.id,
          title: a.label,
          isDestructive: a.isDestructive,
          isCancel: a.isCancel,
        ),
    ];
    try {
      final selected = await LiquidGlassAlert.show(
        context: context,
        title: title,
        message: message,
        actions: nativeActions,
      );
      if (selected != null) {
        for (final a in actions) {
          if (a.id == selected) return a.result;
        }
        return null;
      }
    } catch (_) {
      // Fall through to Cupertino.
    }
  }

  return _showCupertinoAlert<T>(
    context: context,
    title: title,
    message: message,
    actions: actions,
    content: content,
    barrierDismissible: barrierDismissible,
  );
}

Future<T?> _showCupertinoAlert<T>({
  required BuildContext context,
  String? title,
  String? message,
  required List<IosAlertAction<T>> actions,
  Widget? content,
  required bool barrierDismissible,
}) {
  return showCupertinoDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return CupertinoAlertDialog(
        title: title == null ? null : Text(title),
        content:
            content ??
            (message == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(message),
                  )),
        actions: [
          for (final a in actions)
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(a.result),
              isDestructiveAction: a.isDestructive,
              isDefaultAction: a.isDefault,
              child: Text(a.label),
            ),
        ],
      );
    },
  );
}

Future<T?> _showMaterialAlert<T>({
  required BuildContext context,
  String? title,
  String? message,
  required List<IosAlertAction<T>> actions,
  Widget? content,
  required bool barrierDismissible,
}) {
  final cs = Theme.of(context).colorScheme;
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      Widget? body = content;
      if (body == null && message != null) {
        body = Text(
          message,
          style: TextStyle(color: cs.onSurface, fontSize: 15, height: 1.35),
        );
      }
      return AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        shape: AppShape.dialogBorder,
        title: title == null
            ? null
            : Text(title, style: TextStyle(color: cs.onSurface)),
        content: body,
        actions: [
          for (final a in actions)
            if (a.isCancel || (!a.isDefault && !a.isDestructive))
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(a.result),
                child: Text(
                  a.label,
                  style: TextStyle(
                    color: a.isDestructive ? cs.error : cs.onSurfaceVariant,
                  ),
                ),
              )
            else
              FilledButton.tonal(
                onPressed: () => Navigator.of(dialogContext).pop(a.result),
                style: a.isDestructive
                    ? FilledButton.styleFrom(
                        backgroundColor: cs.errorContainer,
                        foregroundColor: cs.onErrorContainer,
                      )
                    : null,
                child: Text(a.label),
              ),
        ],
      );
    },
  );
}
