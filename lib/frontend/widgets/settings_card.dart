import 'package:flutter/material.dart';
import 'package:komet/frontend/widgets/glass/ios_symbols.dart';

import '../../core/config/app_shape.dart';
import 'glass/glass_controls.dart';
import 'glass/ios_glass.dart';
import 'glass/ios_palette.dart';
import 'glass/ios_metrics.dart';
import 'glass/ios_tappable.dart';
import 'glass/ios_typography.dart';
import 'glossy_pill.dart';

class SettingsPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const SettingsPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (IosGlass.of(context)) {
      return IosGroupedSection(
        color: color,
        child: Padding(padding: padding, child: child),
      );
    }
    return GlossyPill(
      color: color ?? cs.surfaceContainerHigh,
      borderRadius: AppShape.cardRadius,
      padding: padding,
      depth: 6,
      child: child,
    );
  }
}

class IosGroupedSection extends StatelessWidget {
  static const double defaultRadius = IosMetrics.groupedRadius;

  final Widget child;
  final Color? color;
  final double radius;

  const IosGroupedSection({
    super.key,
    required this.child,
    this.color,
    this.radius = IosGroupedSection.defaultRadius,
  });

  static Color background(ColorScheme cs) => cs.brightness == Brightness.dark
      ? cs.surfaceContainerHigh
      : cs.surfaceContainerLowest;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(color: color ?? background(cs), child: child),
    );
  }
}

class IosSettingsIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;

  const IosSettingsIcon({super.key, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Icon(
      IosSymbols.adapt(context, icon),
      size: 22,
      weight: 400,
      color: color ?? IosPalette.label(cs),
    );
  }
}

class SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (IosGlass.of(context)) {
      return IosGroupedSection(
        radius: 26,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 58),
                  child: Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ],
        ),
      );
    }
    return GlossyPill(
      color: cs.surfaceContainerHigh,
      borderRadius: AppShape.cardRadius,
      depth: 6,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 58),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: IosTappable(
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                if (IosGlass.of(context))
                  IosSettingsIcon(icon: icon)
                else
                  Icon(
                    IosSymbols.adapt(context, icon),
                    color: cs.onSurfaceVariant,
                    size: 22,
                    weight: 400,
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: IosGlass.of(context)
                              ? IosTypography.listTitle
                              : 16,
                          fontWeight: IosGlass.of(context)
                              ? IosType.body
                              : FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: IosGlass.of(context)
                                ? IosTypography.listSubtitle
                                : 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GlassSwitch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsNavTile extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final Color? tintColor;
  final VoidCallback? onTap;
  final bool isLast;

  const SettingsNavTile({
    super.key,
    this.icon,
    this.leading,
    required this.label,
    this.tintColor,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IosTappable(
      onTap: onTap ?? () {},
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(AppShape.card))
          : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              leading ??
                  (IosGlass.of(context) && icon != null
                      ? IosSettingsIcon(icon: icon!, color: tintColor)
                      : Icon(
                          icon,
                          color: tintColor ?? cs.onSurfaceVariant,
                          size: 22,
                          weight: 400,
                        )),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: tintColor ?? cs.onSurface,
                    fontSize: IosGlass.of(context)
                        ? IosTypography.listTitle
                        : 16,
                    fontWeight: IosGlass.of(context)
                        ? IosType.body
                        : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                IosSymbols.chevronRight(context),
                color: cs.outline,
                size: 20,
                weight: 400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
