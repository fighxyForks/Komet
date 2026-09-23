import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../sliding_pill_nav.dart';

class IosNativeTabBar extends StatelessWidget {
  final List<PillNavItem> items;
  final int currentIndex;
  final List<String?> badges;
  final ValueChanged<int> onTap;
  final void Function(int index, Offset globalPosition)? onItemLongPress;

  const IosNativeTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.badges = const [],
    this.onItemLongPress,
  });

  static List<LiquidGlassTabItem> tabItems(
    List<PillNavItem> items,
    List<String?> badges,
  ) => [
    for (var i = 0; i < items.length; i++)
      LiquidGlassTabItem(
        label: items[i].label,
        icon: items[i].sfSymbol == null
            ? NativeLiquidGlassIcon.iconData(items[i].icon)
            : NativeLiquidGlassIcon.sfSymbol(items[i].sfSymbol!),
        iosBadgeValue: i < badges.length ? badges[i] : null,
      ),
  ];

  static int indexAt(double dx, double width, int count) {
    if (count <= 0 || width <= 0) return 0;
    return (dx / width * count).floor().clamp(0, count - 1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = LiquidGlassTabBar(
      items: tabItems(items, badges),
      currentIndex: currentIndex.clamp(0, items.length - 1),
      onTabSelected: onTap,
      selectedItemColor: cs.primary,
      iosItemPositioning: LiquidGlassTabBarItemPositioning.fill,
    );
    final longPress = onItemLongPress;
    if (longPress == null) return bar;
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPressStart: (details) {
          final index = indexAt(
            details.localPosition.dx,
            constraints.maxWidth,
            items.length,
          );
          if (items[index].longPressable) {
            longPress(index, details.globalPosition);
          }
        },
        child: bar,
      ),
    );
  }
}
