import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../../../core/utils/haptics.dart';
import '../springy_tap.dart';
import 'ios_glass.dart';

Rect globalRectOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return Rect.zero;
  return box.localToGlobal(Offset.zero) & box.size;
}

class GlassStyle {
  static const double sigma = 24;
  static const double buttonSize = 44;
  static const BorderRadius capsule = BorderRadius.all(Radius.circular(999));

  static const List<double> vibrancy = [
    1.62992,
    -0.57216,
    -0.05776,
    0,
    0,
    -0.17008,
    1.22784,
    -0.05776,
    0,
    0,
    -0.17008,
    -0.57216,
    1.74224,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static Color tint(ColorScheme cs) => cs.brightness == Brightness.dark
      ? cs.surfaceContainerHigh.withValues(alpha: 0.55)
      : cs.surfaceContainerLowest.withValues(alpha: 0.68);

  static Color rim(ColorScheme cs) => cs.brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.14)
      : Colors.white.withValues(alpha: 0.75);

  static Color highlight(ColorScheme cs) => cs.brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.07)
      : Colors.white.withValues(alpha: 0.35);

  static Color scrim(ColorScheme cs) => cs.brightness == Brightness.dark
      ? Colors.black.withValues(alpha: 0.28)
      : Colors.black.withValues(alpha: 0.12);

  static BoxShadow shadow(ColorScheme cs) => BoxShadow(
    color: Colors.black.withValues(
      alpha: cs.brightness == Brightness.dark ? 0.32 : 0.1,
    ),
    blurRadius: 18,
    offset: const Offset(0, 6),
  );
}

class GlassBackground extends StatelessWidget {
  final BorderRadius borderRadius;
  final Color? tint;
  final bool shadow;
  final double sigma;
  final bool forceOpaque;
  final Widget child;

  const GlassBackground({
    super.key,
    this.borderRadius = GlassStyle.capsule,
    this.tint,
    this.shadow = true,
    this.sigma = GlassStyle.sigma,
    this.forceOpaque = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = tint ?? GlassStyle.tint(cs);
    final fill = forceOpaque
        ? base.withValues(alpha: 1)
        : base;
    final painted = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: GlassStyle.rim(cs), width: 0.6),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(GlassStyle.highlight(cs), fill),
            fill,
          ],
          stops: const [0, 0.6],
        ),
      ),
      child: child,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow ? [GlassStyle.shadow(cs)] : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: forceOpaque
            ? painted
            : BackdropFilter(
                filter: ui.ImageFilter.compose(
                  outer: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  inner: const ColorFilter.matrix(GlassStyle.vibrancy),
                ),
                child: painted,
              ),
      ),
    );
  }
}

class GlassCapsule extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final double? width;
  final double? height;
  final bool allowNative;
  final bool shadow;
  final Color? fallbackTint;
  final double fallbackSigma;
  final bool forceOpaque;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? traceLabel;

  const GlassCapsule({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.tint,
    this.width,
    this.height,
    this.allowNative = true,
    this.shadow = true,
    this.fallbackTint,
    this.fallbackSigma = GlassStyle.sigma,
    this.forceOpaque = false,
    this.onTap,
    this.onLongPress,
    this.traceLabel,
  });

  static (double?, double?) nativeExtent(
    BoxConstraints constraints,
    double? width,
    double? height,
  ) => (
    width ?? (constraints.hasTightWidth ? constraints.maxWidth : null),
    height ?? (constraints.hasTightHeight ? constraints.maxHeight : null),
  );

  void _handleTap() {
    Haptics.tap();
    onTap?.call();
  }

  String? _traceLabel() => traceLabelOf(key) ?? traceLabel;

  static String? traceLabelOf(Key? key) =>
      key is ValueKey<String> ? key.value : null;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return NativeGlassGate(
      label: _traceLabel(),
      builder: (context, useNative) {
        if (forceOpaque) {
          return GlassBackground(
            borderRadius: borderRadius ?? GlassStyle.capsule,
            tint: fallbackTint ?? tint ?? Theme.of(context).colorScheme.surfaceContainerHigh,
            sigma: 0,
            shadow: shadow,
            forceOpaque: true,
            child: SizedBox(width: width, height: height, child: content),
          );
        }
        if (useNative && allowNative) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final (w, h) = nativeExtent(constraints, width, height);
              final native = LiquidGlassContainer(
                width: w,
                height: h,
                config: LiquidGlassConfig(
                  shape: borderRadius == null
                      ? LiquidGlassEffectShape.capsule
                      : LiquidGlassEffectShape.rect,
                  cornerRadius: borderRadius?.topLeft.x,
                  tint: tint,
                  interactive: onTap != null,
                ),
                onTap: onTap == null ? null : _handleTap,
                child: SizedBox(width: w, height: h, child: content),
              );
              if (onLongPress == null) return native;
              return GestureDetector(onLongPress: onLongPress, child: native);
            },
          );
        }
        final surface = GlassBackground(
          borderRadius: borderRadius ?? GlassStyle.capsule,
          tint: fallbackTint ?? tint,
          sigma: fallbackSigma,
          shadow: shadow,
          forceOpaque: forceOpaque,
          child: SizedBox(width: width, height: height, child: content),
        );
        if (onTap == null && onLongPress == null) return surface;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap == null ? null : _handleTap,
          onLongPress: onLongPress,
          child: SpringyTap(pressedScale: 0.94, child: surface),
        );
      },
    );
  }
}

class GlassIconButton extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final VoidCallback? onPressed;
  final ValueChanged<Rect>? onPressedAt;
  final VoidCallback? onLongPress;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? tint;

  const GlassIconButton({
    super.key,
    this.icon,
    this.child,
    this.onPressed,
    this.onPressedAt,
    this.onLongPress,
    this.tooltip,
    this.size = GlassStyle.buttonSize,
    this.iconSize = 22,
    this.color,
    this.tint,
  }) : assert(icon != null || child != null);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onPressed != null || onPressedAt != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: GlassCapsule(
        traceLabel: GlassCapsule.traceLabelOf(key) ?? tooltip ?? 'кнопка',
        width: size,
        height: size,
        tint: tint,
        onTap: enabled
            ? () {
                onPressed?.call();
                onPressedAt?.call(globalRectOf(context));
              }
            : null,
        onLongPress: onLongPress,
        child: Center(
          child:
              child ??
              Icon(
                icon,
                size: iconSize,
                weight: 500,
                color: color ?? cs.onSurface,
              ),
        ),
      ),
    );
  }
}

class GlassGroupItem {
  final IconData? icon;
  final Widget? child;
  final VoidCallback? onPressed;
  final ValueChanged<Rect>? onPressedAt;
  final String? tooltip;
  final Key? key;

  const GlassGroupItem({
    this.icon,
    this.child,
    this.onPressed,
    this.onPressedAt,
    this.tooltip,
    this.key,
  }) : assert(icon != null || child != null);

  bool get enabled => onPressed != null || onPressedAt != null;
}

class GlassButtonGroup extends StatelessWidget {
  final List<GlassGroupItem> items;
  final double height;
  final double itemWidth;
  final double iconSize;

  const GlassButtonGroup({
    super.key,
    required this.items,
    this.height = GlassStyle.buttonSize,
    this.itemWidth = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassCapsule(
      traceLabel: GlassCapsule.traceLabelOf(key) ?? 'группа кнопок',
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items)
            Builder(
              key: item.key,
              builder: (itemContext) => Semantics(
                button: true,
                enabled: item.enabled,
                label: item.tooltip,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: item.enabled
                      ? () {
                          Haptics.tap();
                          item.onPressed?.call();
                          item.onPressedAt?.call(globalRectOf(itemContext));
                        }
                      : null,
                  child: SpringyTap(
                    pressedScale: 0.86,
                    child: SizedBox(
                      width: itemWidth,
                      height: height,
                      child: Center(
                        child:
                            item.child ??
                            Icon(
                              item.icon,
                              size: iconSize,
                              weight: 500,
                              color: cs.onSurface,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
