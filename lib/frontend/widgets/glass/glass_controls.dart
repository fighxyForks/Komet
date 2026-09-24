import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../motion/ios_haptics.dart';
import 'glass_capsule.dart';
import 'ios_palette.dart';
import 'ios_glass.dart';
import 'ios_metrics.dart';
import 'ios_symbols.dart';
import 'ios_typography.dart';

class GlassSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const GlassSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (!IosGlass.of(context)) {
      return Switch(value: value, onChanged: onChanged);
    }
    final cs = Theme.of(context).colorScheme;
    // Keep CupertinoSwitch — LiquidGlassToggle is a platform view and is not
    // safe one-per-row in settings lists (glass budget ≤1–2 views/screen).
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged == null
          ? null
          : (v) {
              IosHaptics.toggle();
              onChanged!(v);
            },
      activeTrackColor: cs.primary,
    );
  }
}

class GlassSegmentThumb extends StatelessWidget {
  final double radius;

  const GlassSegmentThumb({super.key, required this.radius});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = cs.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: GlassStyle.rim(cs), width: 0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class IosFlatSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  final double height;

  const IosFlatSearchBar({
    super.key,
    required this.hint,
    this.onTap,
    this.height = IosMetrics.searchBarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = IosPalette.secondaryLabel(cs);
    return Semantics(
      button: onTap != null,
      label: hint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: IosPalette.searchFill(cs),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IosSymbols.search(context),
                size: 18,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                hint,
                style: TextStyle(
                  color: color,
                  fontSize: IosTypography.composer,
                  letterSpacing: IosTypography.letterSpacing(
                    IosTypography.composer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SegmentFit {
  static List<double>? widths(List<double> natural, double available) {
    if (natural.isEmpty) return const [];
    final total = natural.fold<double>(0, (sum, w) => sum + w);
    if (total > available) return null;
    final extra = (available - total) / natural.length;
    return [for (final w in natural) w + extra];
  }

  static double labelWidth(
    BuildContext context,
    String text,
    TextStyle style, {
    double padding = 0,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width.ceilToDouble() + padding;
    painter.dispose();
    return width;
  }
}

class GlassTabStrip extends StatelessWidget {
  final List<String> tabs;
  final String selected;
  final ValueChanged<String> onSelected;
  final ScrollController? controller;
  final double height;

  const GlassTabStrip({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
    this.controller,
    this.height = IosMetrics.searchBarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const inset = 3.0;
    return GlassCapsule(
      traceLabel: 'вкладки вложений',
      height: height,
      padding: const EdgeInsets.all(inset),
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final tab in tabs)
              GestureDetector(
                key: ValueKey('glass-tab-$tab'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (tab == selected) return;
                  IosHaptics.selectionChange();
                  onSelected(tab);
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        opacity: tab == selected ? 1 : 0,
                        child: GlassSegmentThumb(
                          radius: (height - inset * 2) / 2,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: height - inset * 2,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 180),
                            style: TextStyle(
                              color: tab == selected
                                  ? IosPalette.label(cs)
                                  : IosPalette.secondaryLabel(cs),
                              fontSize: 15,
                              fontWeight: tab == selected
                                  ? IosType.title
                                  : IosType.name,
                            ),
                            child: Text(tab),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Adaptive segmented control: Cupertino sliding in iOS mode, Material otherwise.
class IosSegmentedControl<T extends Object> extends StatelessWidget {
  final Map<T, Widget> children;
  final T? groupValue;
  final ValueChanged<T?> onValueChanged;
  final bool proportional;

  const IosSegmentedControl({
    super.key,
    required this.children,
    required this.groupValue,
    required this.onValueChanged,
    this.proportional = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!IosGlass.of(context)) {
      return SegmentedButton<T>(
        showSelectedIcon: false,
        segments: [
          for (final e in children.entries)
            ButtonSegment<T>(value: e.key, label: e.value),
        ],
        selected: {if (groupValue != null) groupValue as T},
        onSelectionChanged: (set) {
          if (set.isNotEmpty) onValueChanged(set.first);
        },
      );
    }
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<T>(
        groupValue: groupValue,
        children: children,
        proportionalWidth: proportional,
        onValueChanged: (v) {
          if (v != null) IosHaptics.selectionChange();
          onValueChanged(v);
        },
      ),
    );
  }
}

/// Adaptive slider: Cupertino in iOS mode, Material otherwise.
class IosSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;

  const IosSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    if (!IosGlass.of(context)) {
      return Slider(
        value: value,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
        min: min,
        max: max,
        divisions: divisions,
      );
    }
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlider(
        value: value.clamp(min, max),
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
        min: min,
        max: max,
        divisions: divisions,
      ),
    );
  }
}

/// Adaptive progress indicator: Cupertino in iOS mode, Material otherwise.
class IosActivityIndicator extends StatelessWidget {
  final double? radius;
  final Color? color;
  final double strokeWidth;

  const IosActivityIndicator({
    super.key,
    this.radius,
    this.color,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (IosGlass.of(context)) {
      return CupertinoActivityIndicator(
        radius: radius ?? 10,
        color: color,
      );
    }
    final size = (radius ?? 10) * 2;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color,
      ),
    );
  }
}

/// Adaptive checkbox: Cupertino-style check in iOS mode.
class IosCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const IosCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!IosGlass.of(context)) {
      return Checkbox(value: value, onChanged: onChanged);
    }
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: IosMetrics.minHitTarget,
      height: IosMetrics.minHitTarget,
      child: Center(
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onChanged == null
              ? null
              : () {
                  IosHaptics.toggle();
                  onChanged!(!value);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? cs.primary : IosPalette.secondaryLabel(cs),
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(CupertinoIcons.check_mark, size: 14, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}
