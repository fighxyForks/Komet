import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Per-sender name colors for group chats.
///
/// Palettes are brightness-aware so every swatch stays near WCAG AA (4.5:1)
/// against the incoming bubble fill used in light and dark themes.
abstract final class SenderNameColor {
  /// Incoming iOS bubble gradient ends (dark theme).
  static const Color darkBubbleTop = Color(0xFF2C2C2E);
  static const Color darkBubbleBottom = Color(0xFF3A3A3C);

  /// Incoming iOS bubble gradient ends (light theme).
  static const Color lightBubbleTop = Color(0xFFFFFFFF);
  static const Color lightBubbleBottom = Color(0xFFE8E8ED);

  /// Brighter swatches for dark incoming bubbles.
  static const List<Color> darkPalette = [
    Color(0xFFEF9A9A), // red
    Color(0xFF90CAF9), // blue
    Color(0xFFA5D6A7), // green
    Color(0xFFFFCC80), // orange
    Color(0xFFCE93D8), // purple
    Color(0xFF80DEEA), // cyan
    Color(0xFFF48FB1), // pink
    Color(0xFFD2B48C), // tan / brown
  ];

  /// Darker swatches for light incoming bubbles.
  static const List<Color> lightPalette = [
    Color(0xFFC62828), // red
    Color(0xFF1565C0), // blue
    Color(0xFF1B5E20), // green
    Color(0xFFBF360C), // deep orange
    Color(0xFF6A1B9A), // purple
    Color(0xFF006064), // cyan
    Color(0xFFAD1457), // pink
    Color(0xFF5D4037), // brown
  ];

  static List<Color> paletteFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkPalette : lightPalette;

  static Color of(int id, Brightness brightness) {
    final palette = paletteFor(brightness);
    return palette[id.abs() % palette.length];
  }

  /// Relative-luminance contrast ratio (WCAG 2.1).
  static double contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }
}
