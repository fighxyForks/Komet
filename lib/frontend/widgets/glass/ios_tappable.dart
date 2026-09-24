import 'package:flutter/material.dart';

import 'ios_glass.dart';
import 'ios_metrics.dart';

/// Tap target that uses Material ripple off iOS mode and an opacity highlight
/// on iOS (no InkWell splash).
class IosTappable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final bool enabled;
  final double pressedOpacity;
  final HitTestBehavior behavior;

  const IosTappable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.enabled = true,
    this.pressedOpacity = 0.55,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<IosTappable> createState() => _IosTappableState();
}

class _IosTappableState extends State<IosTappable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled =
        widget.enabled && (widget.onTap != null || widget.onLongPress != null);

    if (!IosGlass.of(context)) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? widget.onTap : null,
          onLongPress: enabled ? widget.onLongPress : null,
          borderRadius: widget.borderRadius,
          child: widget.child,
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: IosMetrics.minHitTarget),
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onTap : null,
        onLongPress: enabled ? widget.onLongPress : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _pressed ? widget.pressedOpacity : 1,
          child: widget.child,
        ),
      ),
    );
  }
}
