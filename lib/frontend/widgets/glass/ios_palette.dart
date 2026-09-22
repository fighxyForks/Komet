import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IosPalette {
  static bool _dark(ColorScheme cs) => cs.brightness == Brightness.dark;

  static Color background(ColorScheme cs) =>
      _dark(cs) ? Colors.black : Colors.white;

  static Color grouped(ColorScheme cs) =>
      _dark(cs) ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);

  static Color label(ColorScheme cs) => _dark(cs) ? Colors.white : Colors.black;

  static Color secondaryLabel(ColorScheme cs) =>
      _dark(cs) ? const Color(0xFF8D8D93) : const Color(0xFF8E8E93);

  static Color separator(ColorScheme cs) =>
      _dark(cs) ? const Color(0xFF38383A) : const Color(0xFFC6C6C8);

  static Color searchFill(ColorScheme cs) =>
      _dark(cs) ? const Color(0x3D767680) : const Color(0x1F767680);

  static Color mutedBadge(ColorScheme cs) =>
      _dark(cs) ? const Color(0xFF636366) : const Color(0xFFB1B1B6);

  static Color selectedTab(ColorScheme cs) => _dark(cs)
      ? Colors.white.withValues(alpha: 0.12)
      : Colors.black.withValues(alpha: 0.06);

  static const Color badgeRed = Color(0xFFFF3B30);

  static SystemUiOverlayStyle overlayFor(Color background) {
    final style =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return style.copyWith(statusBarColor: Colors.transparent);
  }
}
