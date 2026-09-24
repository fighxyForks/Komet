import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/widgets/glass/ios_palette.dart';
import 'package:komet/frontend/widgets/sender_name_color.dart';

List<Color> _incoming(Brightness brightness) => IosPalette.bubbleGradient(
  ColorScheme.fromSeed(seedColor: Colors.blue, brightness: brightness),
  isMe: false,
).colors;

void _expectReadable(Brightness brightness) {
  for (final color in SenderNameColor.paletteFor(brightness, ios: true)) {
    for (final bubble in _incoming(brightness)) {
      final ratio = SenderNameColor.contrastRatio(color, bubble);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: '$color vs $bubble');
    }
  }
}

void main() {
  test('в тёмной теме имена читаются на входящих баблах (AA)', () {
    _expectReadable(Brightness.dark);
  });

  test('в светлой теме имена читаются на входящих баблах (AA)', () {
    _expectReadable(Brightness.light);
  });

  test('цвет стабилен для отправителя и зависит от темы', () {
    final dark = SenderNameColor.of(42, Brightness.dark, ios: true);
    final light = SenderNameColor.of(42, Brightness.light, ios: true);
    expect(dark, isNot(light));
    expect(SenderNameColor.of(-42, Brightness.dark, ios: true), dark);
  });

  test('вне iOS-режима палитра прежняя', () {
    for (final brightness in Brightness.values) {
      expect(
        SenderNameColor.paletteFor(brightness, ios: false),
        SenderNameColor.legacyPalette,
      );
    }
  });

  test('светло-коричневый из старой палитры в iOS-режиме не используется', () {
    const legacyBrown = Color(0xFFA1887F);
    expect(
      SenderNameColor.contrastRatio(
        legacyBrown,
        _incoming(Brightness.dark).last,
      ),
      lessThan(4.5),
    );
    for (final brightness in Brightness.values) {
      expect(
        SenderNameColor.paletteFor(brightness, ios: true),
        isNot(contains(legacyBrown)),
      );
    }
  });
}
