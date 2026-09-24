import 'package:flutter/material.dart';

import '../../core/config/app_shape.dart';
import 'glass/ios_glass.dart';
import 'glass/ios_metrics.dart';
import 'glass/ios_typography.dart';

/// Standard rounded top shape for modal bottom sheets.
const RoundedRectangleBorder kSheetShape = AppShape.sheetBorder;

/// Pill-shaped action button for the bottom row of a modal sheet.
class SheetButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback? onTap;
  final Color? color;

  const SheetButton({
    super.key,
    required this.label,
    required this.filled,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ios = IosGlass.of(context);
    final disabled = onTap == null;
    final fill = color ?? cs.primary;
    final labelColor = filled ? cs.onPrimary : (color ?? cs.onSurface);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: IosMetrics.minHitTarget,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled
              ? (disabled ? fill.withValues(alpha: 0.4) : fill)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(IosMetrics.minHitTarget / 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: disabled
                ? labelColor.withValues(alpha: filled ? 0.85 : 0.4)
                : labelColor,
            fontSize: ios ? IosTypography.body : 14,
            fontWeight: ios ? IosTypography.semibold : FontWeight.w600,
            letterSpacing: ios
                ? IosTypography.letterSpacing(IosTypography.body)
                : null,
          ),
        ),
      ),
    );
  }
}

/// Grabber row that keeps the pill centred while an action sits at the edge.
class SheetGrabberBar extends StatelessWidget {
  static const double height = 34;
  static const double actionInset = 8;

  final Widget action;

  const SheetGrabberBar({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SheetGrabber(margin: EdgeInsets.zero),
          Positioned(right: actionInset, child: action),
        ],
      ),
    );
  }
}

/// The little drag "grabber" pill shown at the top of a bottom sheet.
class SheetGrabber extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const SheetGrabber({
    super.key,
    this.margin = const EdgeInsets.symmetric(vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ios = IosGlass.of(context);
    return Container(
      width: ios ? IosMetrics.grabberWidth : 40,
      height: ios ? IosMetrics.grabberHeight : 4,
      margin: margin,
      decoration: BoxDecoration(
        color: cs.onSurfaceVariant.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
