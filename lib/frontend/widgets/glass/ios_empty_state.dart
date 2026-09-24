import 'package:flutter/material.dart';

import 'ios_glass.dart';
import 'ios_palette.dart';
import 'ios_typography.dart';

/// System-style empty content: large symbol + secondary label.
class IosEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final double iconSize;

  const IosEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.iconSize = 56,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ios = IosGlass.of(context);
    final color = ios ? IosPalette.secondaryLabel(cs) : cs.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: color.withValues(alpha: 0.55)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: ios ? IosTypography.listSubtitle : 16,
                fontWeight: ios ? IosTypography.regular : FontWeight.w400,
                letterSpacing: ios
                    ? IosTypography.letterSpacing(IosTypography.listSubtitle)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
