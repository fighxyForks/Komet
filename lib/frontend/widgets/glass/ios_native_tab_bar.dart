import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../sliding_pill_nav.dart';

class IosNativeTabBar extends StatelessWidget {
  /// Height of the floating tab capsule, shared with screens that pad for it.
  static const double height = SlidingPillNav.iosHeight;

  final List<PillNavItem> items;
  final int currentIndex;
  final List<String?> badges;
  final ValueChanged<int> onTap;

  const IosNativeTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.badges = const [],
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

  @override
  Widget build(BuildContext context) {
    // A custom selected color makes the glass package paint a second plate
    // behind the system capsule.
    return LiquidGlassTabBar(
      items: tabItems(items, badges),
      currentIndex: currentIndex.clamp(0, items.length - 1),
      onTabSelected: onTap,
      iosItemPositioning: LiquidGlassTabBarItemPositioning.fill,
    );
  }
}
