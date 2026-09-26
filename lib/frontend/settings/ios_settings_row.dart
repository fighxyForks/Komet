import 'package:flutter/material.dart';

import '../widgets/glass/ios_palette.dart';
import '../widgets/glass/ios_symbols.dart';
import '../widgets/glass/ios_tappable.dart';
import '../widgets/glass/ios_typography.dart';

class IosSettingsSection extends StatelessWidget {
  final String header;
  final List<Widget> children;

  const IosSettingsSection({
    super.key,
    this.header = '',
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 8, 20, 6),
            child: Text(
              header,
              style: TextStyle(
                color: IosPalette.secondaryLabel(cs),
                fontSize: 15,
                fontWeight: IosTypography.regular,
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: IosPalette.settingsCard(cs),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class IosSettingsRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final String trailing;
  final String section;
  final bool destructive;
  final bool isLast;
  final VoidCallback? onTap;

  const IosSettingsRow({
    super.key,
    required this.title,
    required this.icon,
    this.trailing = '',
    this.section = '',
    this.destructive = false,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = destructive ? cs.error : IosPalette.label(cs);
    return IosTappable(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: IosTypography.body,
                        fontWeight: IosTypography.regular,
                      ),
                    ),
                    if (section.isNotEmpty)
                      Text(
                        section,
                        style: TextStyle(
                          color: IosPalette.secondaryLabel(cs),
                          fontSize: IosTypography.listSubtitle,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing.isNotEmpty)
                Text(
                  trailing,
                  style: TextStyle(
                    color: IosPalette.secondaryLabel(cs),
                    fontSize: IosTypography.body,
                  ),
                ),
              if (!destructive) ...[
                const SizedBox(width: 8),
                Icon(
                  IosSymbols.chevronRight(context),
                  size: 14,
                  color: IosPalette.secondaryLabel(cs),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
