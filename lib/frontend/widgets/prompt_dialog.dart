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
  if (IosGlass.of(context)) {
    return showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) => _IosTextPrompt(
        title: title,
        description: description,
        hint: hint,
        initialValue: initialValue,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        obscureText: obscureText,
        maxLines: maxLines,
        keyboardType: keyboardType,
      ),
    );
  }

  final tec = TextEditingController(text: initialValue);
  try {
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

class _IosTextPrompt extends StatefulWidget {
  final String? title;
  final String? description;
  final String? hint;
  final String? initialValue;
  final String confirmLabel;
  final String cancelLabel;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;

  const _IosTextPrompt({
    required this.title,
    required this.description,
    required this.hint,
    required this.initialValue,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.obscureText,
    required this.maxLines,
    required this.keyboardType,
  });

  @override
  State<_IosTextPrompt> createState() => _IosTextPromptState();
}

class _IosTextPromptState extends State<_IosTextPrompt> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    Navigator.pop(context, text.isEmpty ? null : text);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: widget.title == null ? null : Text(widget.title!),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.description != null) ...[
            Text(widget.description!),
            const SizedBox(height: 12),
          ],
          CupertinoTextField(
            controller: _controller,
            autofocus: true,
            obscureText: widget.obscureText,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            keyboardType: widget.keyboardType,
            placeholder: widget.hint,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
