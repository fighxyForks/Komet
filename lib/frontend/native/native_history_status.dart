import 'package:flutter/material.dart';

import '../widgets/glass/ios_symbols.dart';

class NativeHistoryRetry extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onRetry;
  final bool inline;

  const NativeHistoryRetry({
    super.key,
    required this.onRetry,
    this.title = 'Не удалось загрузить историю',
    this.action = 'Повторить',
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = IosSymbols.error(context);
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!inline) Icon(icon, size: 28),
        if (!inline) const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: inline ? 15 : 17,
            color: const Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: TextButton(onPressed: onRetry, child: Text(action)),
        ),
      ],
    );
    if (inline) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: column,
      );
    }
    return Center(child: column);
  }
}
