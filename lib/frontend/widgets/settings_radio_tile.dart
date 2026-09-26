import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_metrics.dart';
import 'package:komet/frontend/widgets/glass/ios_symbols.dart';
import 'package:komet/frontend/widgets/glass/ios_tappable.dart';
import 'package:komet/frontend/widgets/glass/ios_typography.dart';

class SettingsRadioTile extends StatelessWidget {
  final Widget leading;
  final double leadingGap;
  final String label;
  final TextStyle? labelStyle;
  final String? description;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<TapDownDetails>? onTapDown;

  const SettingsRadioTile({
    super.key,
    required this.leading,
    this.leadingGap = 14,
    required this.label,
    this.labelStyle,
    this.description,
    required this.selected,
    required this.onTap,
    this.onTapDown,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ios = IosGlass.of(context);
    final resolvedLabelStyle =
        labelStyle ??
        TextStyle(
          color: cs.onSurface,
          fontSize: ios ? IosTypography.body : 15,
          fontWeight: ios ? IosTypography.regular : FontWeight.w500,
        );
    final labelChild = description == null
        ? Text(label, style: resolvedLabelStyle)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: resolvedLabelStyle),
              const SizedBox(height: 2),
              Text(
                description!,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ],
          );
    if (ios) {
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        value: selected ? 'Выбрано' : 'Не выбрано',
        child: IosTappable(
          onTap: onTap,
          onTapDown: onTapDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: IosMetrics.minHitTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  leading,
                  SizedBox(width: leadingGap),
                  Expanded(child: labelChild),
                  Icon(
                    CupertinoIcons.check_mark,
                    size: 18,
                    color: selected ? cs.primary : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTapDown: onTapDown,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              leading,
              SizedBox(width: leadingGap),
              Expanded(child: labelChild),
              if (description != null) const SizedBox(width: 8),
              Icon(
                selected
                    ? IosSymbols.radioChecked(context)
                    : IosSymbols.radioUnchecked(context),
                color: selected ? cs.primary : cs.outline,
                size: 22,
                fill: selected ? 1 : 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
