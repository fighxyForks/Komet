import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Apple SF Pro tracking values in points, from the HIG Typography table
/// (developer.apple.com/design/human-interface-guidelines/typography).
///
/// Flutter does not apply SF optical tracking automatically — Cupertino
/// hardcodes a few sizes, and Material 3 text themes ship positive
/// letterSpacing — so we resolve from this table ourselves.
const List<(double, double)> kSfProTrackingTable = [
  (6, 0.24),
  (7, 0.23),
  (8, 0.21),
  (9, 0.17),
  (10, 0.12),
  (11, 0.06),
  (12, 0.0),
  (13, -0.08),
  (14, -0.15),
  (15, -0.23),
  (16, -0.31),
  (17, -0.43),
  (18, -0.44),
  (19, -0.45),
  (20, -0.45),
  (21, -0.36),
  (22, -0.26),
  (23, -0.10),
  (24, 0.07),
  (25, 0.15),
  (26, 0.22),
  (27, 0.29),
  (28, 0.38),
  (29, 0.40),
  (30, 0.40),
  (31, 0.39),
  (32, 0.41),
  (33, 0.40),
  (34, 0.40),
  (35, 0.38),
  (36, 0.37),
  (37, 0.36),
  (38, 0.37),
  (39, 0.38),
  (40, 0.37),
  (42, 0.37),
  (44, 0.37),
  (48, 0.35),
  (50, 0.34),
  (56, 0.30),
  (60, 0.26),
  (64, 0.22),
  (72, 0.14),
  (80, 0.0),
];

/// SF Pro tracking in points for [fontSize], linearly interpolated between
/// HIG table entries and clamped outside the table range.
double iosSfTracking(double fontSize) {
  final table = kSfProTrackingTable;
  if (fontSize <= table.first.$1) return table.first.$2;
  if (fontSize >= table.last.$1) return table.last.$2;
  for (var i = 1; i < table.length; i++) {
    final (loSize, loTrack) = table[i - 1];
    final (hiSize, hiTrack) = table[i];
    if (fontSize <= hiSize) {
      final t = (fontSize - loSize) / (hiSize - loSize);
      return loTrack + (hiTrack - loTrack) * t;
    }
  }
  return table.last.$2;
}

/// Inter Dynamic Metrics tracking in points.
///
/// Formula from https://rsms.me/inter/dynmetrics/ (and d.rsms.me/inter-website/v3/dynmetrics):
/// `tracking_em = a + b * e^(c * size)` with a=-0.0223, b=0.185, c=-0.1745;
/// convert to points via `tracking_em * fontSize`.
double iosInterTracking(double fontSize) {
  const a = -0.0223;
  const b = 0.185;
  const c = -0.1745;
  final em = a + b * math.exp(c * fontSize);
  return em * fontSize;
}

/// Letter spacing for iOS mode given [fontSize] and optional [fontFamily].
///
/// - System font (`null` / empty family): Apple SF Pro tracking table.
/// - Inter: Inter Dynamic Metrics (modest negative at body sizes).
/// - Other custom fonts (Unbounded, Google Fonts): `0` to strip Material's
///   positive letterSpacing without inventing a foreign tracking curve.
double iosLetterSpacing({required double fontSize, String? fontFamily}) {
  if (fontFamily == null || fontFamily.isEmpty) {
    return iosSfTracking(fontSize);
  }
  if (fontFamily == 'Inter') {
    return iosInterTracking(fontSize);
  }
  return 0;
}

TextStyle applyIosLetterSpacing(TextStyle style, {String? fontFamily}) {
  final size = style.fontSize;
  if (size == null) return style;
  // [fontFamily] is the app font (null = system). Do not fall back to
  // style.fontFamily — ThemeData may stamp a platform face like Roboto.
  return style.copyWith(
    letterSpacing: iosLetterSpacing(fontSize: size, fontFamily: fontFamily),
  );
}

TextTheme applyIosLetterSpacingToTheme(
  TextTheme theme, {
  String? fontFamily,
}) {
  TextStyle? map(TextStyle? style) {
    if (style == null) return null;
    return applyIosLetterSpacing(style, fontFamily: fontFamily);
  }

  return TextTheme(
    displayLarge: map(theme.displayLarge),
    displayMedium: map(theme.displayMedium),
    displaySmall: map(theme.displaySmall),
    headlineLarge: map(theme.headlineLarge),
    headlineMedium: map(theme.headlineMedium),
    headlineSmall: map(theme.headlineSmall),
    titleLarge: map(theme.titleLarge),
    titleMedium: map(theme.titleMedium),
    titleSmall: map(theme.titleSmall),
    bodyLarge: map(theme.bodyLarge),
    bodyMedium: map(theme.bodyMedium),
    bodySmall: map(theme.bodySmall),
    labelLarge: map(theme.labelLarge),
    labelMedium: map(theme.labelMedium),
    labelSmall: map(theme.labelSmall),
  );
}
