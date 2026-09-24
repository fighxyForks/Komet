import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/widgets/sender_name_color.dart';

void main() {
  test('dark palette clears WCAG AA against dark incoming bubbles', () {
    for (final color in SenderNameColor.darkPalette) {
      final top = SenderNameColor.contrastRatio(
        color,
        SenderNameColor.darkBubbleTop,
      );
      final bottom = SenderNameColor.contrastRatio(
        color,
        SenderNameColor.darkBubbleBottom,
      );
      expect(
        top,
        greaterThanOrEqualTo(4.5),
        reason: '$color vs top ($top)',
      );
      expect(
        bottom,
        greaterThanOrEqualTo(4.5),
        reason: '$color vs bottom ($bottom)',
      );
    }
  });

  test('light palette clears WCAG AA against light incoming bubbles', () {
    for (final color in SenderNameColor.lightPalette) {
      final top = SenderNameColor.contrastRatio(
        color,
        SenderNameColor.lightBubbleTop,
      );
      final bottom = SenderNameColor.contrastRatio(
        color,
        SenderNameColor.lightBubbleBottom,
      );
      expect(
        top,
        greaterThanOrEqualTo(4.5),
        reason: '$color vs top ($top)',
      );
      expect(
        bottom,
        greaterThanOrEqualTo(4.5),
        reason: '$color vs bottom ($bottom)',
      );
    }
  });

  test('of() is stable and brightness-aware', () {
    final dark = SenderNameColor.of(42, Brightness.dark);
    final light = SenderNameColor.of(42, Brightness.light);
    expect(dark, isNot(light));
    expect(SenderNameColor.of(42, Brightness.dark), dark);
    expect(
      SenderNameColor.of(-42, Brightness.dark),
      SenderNameColor.of(42, Brightness.dark),
    );
  });

  test('legacy brown swatch failed dark AA and is no longer used', () {
    const legacyBrown = Color(0xFFA1887F);
    expect(
      SenderNameColor.contrastRatio(
        legacyBrown,
        SenderNameColor.darkBubbleBottom,
      ),
      lessThan(4.5),
    );
    expect(SenderNameColor.darkPalette, isNot(contains(legacyBrown)));
  });
}
