import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IosPalette {
  static bool _dark(ColorScheme cs) => cs.brightness == Brightness.dark;

  static Color background(ColorScheme cs) =>
      _dark(cs) ? Colors.black : Colors.white;

  static Color grouped(ColorScheme cs) =>
      _dark(cs) ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);

  static Color pinnedRow(ColorScheme cs) =>
      _dark(cs) ? const Color(0xFF111113) : const Color(0xFFF7F7F9);

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

  static const List<Color> _incomingLight = [
    Color(0xFFFFFFFF),
    Color(0xFFE8E8ED),
  ];
  static const List<Color> _incomingDark = [
    Color(0xFF2C2C2E),
    Color(0xFF3A3A3C),
  ];

  static LinearGradient bubbleGradient(ColorScheme cs, {required bool isMe}) {
    final colors = isMe
        ? [
            Color.lerp(
              cs.primaryContainer,
              Colors.white,
              _dark(cs) ? 0.1 : 0.4,
            )!,
            cs.primaryContainer,
          ]
        : (_dark(cs) ? _incomingDark : _incomingLight);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  static BoxDecoration servicePill(
    ColorScheme cs, {
    double radius = 12,
    bool opaque = false,
  }) => BoxDecoration(
    color: opaque
        ? (_dark(cs) ? const Color(0xF21C1C1E) : const Color(0xF5F2F2F7))
        : (_dark(cs)
              ? Colors.black.withValues(alpha: 0.32)
              : Colors.white.withValues(alpha: 0.55)),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: _dark(cs)
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.6),
      width: 0.5,
    ),
  );

  static Color serviceText(ColorScheme cs) => cs.onSurface;

  static Color bubbleRim(ColorScheme cs) => _dark(cs)
      ? Colors.white.withValues(alpha: 0.1)
      : Colors.black.withValues(alpha: 0.06);

  static SystemUiOverlayStyle overlayFor(Color background) {
    final style =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return style.copyWith(statusBarColor: Colors.transparent);
  }
}
