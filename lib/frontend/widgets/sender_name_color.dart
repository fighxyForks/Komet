import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class SenderNameColor {
  static const List<Color> legacyPalette = [
    Color(0xFFE57373),
    Color(0xFF64B5F6),
    Color(0xFF81C784),
    Color(0xFFFFB74D),
    Color(0xFFBA68C8),
    Color(0xFF4DD0E1),
    Color(0xFFF06292),
    Color(0xFFA1887F),
  ];

  static const List<Color> darkPalette = [
    Color(0xFFEF9A9A),
    Color(0xFF90CAF9),
    Color(0xFFA5D6A7),
    Color(0xFFFFCC80),
    Color(0xFFCE93D8),
    Color(0xFF80DEEA),
    Color(0xFFF48FB1),
    Color(0xFFD2B48C),
  ];

  static const List<Color> lightPalette = [
    Color(0xFFC62828),
    Color(0xFF1565C0),
    Color(0xFF1B5E20),
    Color(0xFFBF360C),
    Color(0xFF6A1B9A),
    Color(0xFF006064),
    Color(0xFFAD1457),
    Color(0xFF5D4037),
  ];

  static List<Color> paletteFor(Brightness brightness, {required bool ios}) {
    if (!ios) return legacyPalette;
    return brightness == Brightness.dark ? darkPalette : lightPalette;
  }

  static Color of(int id, Brightness brightness, {required bool ios}) {
    final palette = paletteFor(brightness, ios: ios);
    return palette[id.abs() % palette.length];
  }

  static double contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
  }
}
