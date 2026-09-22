import 'package:flutter/material.dart';

import 'glass/glass_capsule.dart';
import 'glass/glass_controls.dart';
import 'glass/ios_glass.dart';

class SegmentedPillToggle extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final double segmentWidth;
  final double height;

  const SegmentedPillToggle({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.segmentWidth = 88,
    this.height = 34,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const pad = 3.0;
    final sel = selected.clamp(0, labels.length - 1);
    if (IosGlass.of(context)) return _buildIos(cs, pad, sel);

    return Container(
      height: height,
      padding: const EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: sel * segmentWidth,
            top: 0,
            bottom: 0,
            width: segmentWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular((height - 2 * pad) / 2),
              ),
            ),
          ),
          _segments(cs, sel, cs.onPrimary),
        ],
      ),
    );
  }

  Widget _buildIos(ColorScheme cs, double pad, int sel) {
    return GlassCapsule(
      key: const ValueKey('ios-segmented'),
      allowNative: false,
      height: height,
      padding: EdgeInsets.all(pad),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            left: sel * segmentWidth,
            top: 0,
            bottom: 0,
            width: segmentWidth,
            child: GlassSegmentThumb(radius: (height - 2 * pad) / 2),
          ),
          _segments(cs, sel, cs.onSurface),
        ],
      ),
    );
  }

  Widget _segments(ColorScheme cs, int sel, Color activeColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(labels.length, (i) {
        final active = i == sel;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(i),
          child: SizedBox(
            width: segmentWidth,
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  color: active ? activeColor : cs.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                child: Text(labels[i]),
              ),
            ),
          ),
        );
      }),
    );
  }
}
