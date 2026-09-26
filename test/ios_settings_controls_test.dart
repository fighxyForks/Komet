import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/widgets/glass/ios_settings_controls.dart';

void main() {
  test('stepped slider snaps to the nearest step', () {
    expect(IosSteppedSlider.snap(1.02, const [0.9, 1.0, 1.1]), 1.0);
    expect(IosSteppedSlider.snap(1.08, const [0.9, 1.0, 1.1]), 1.1);
  });

  testWidgets('tile picker reports the tapped option', (tester) async {
    var selected = 'system';
    await tester.pumpWidget(
      MaterialApp(
        home: IosTilePicker<String>(
          value: selected,
          options: const [
            IosTileOption(
              value: 'system',
              icon: Icons.circle,
              label: 'Система',
            ),
            IosTileOption(value: 'day', icon: Icons.sunny, label: 'День'),
            IosTileOption(
              value: 'night',
              icon: Icons.nightlight,
              label: 'Ночь',
            ),
          ],
          onChanged: (value) => selected = value,
        ),
      ),
    );
    await tester.tap(find.text('Ночь'));
    await tester.pump();
    expect(selected, 'night');
  });

  testWidgets('toggle card reports the new switch value', (tester) async {
    var on = false;
    await tester.pumpWidget(
      MaterialApp(
        home: IosToggleCard(
          label: 'Тактильный отклик',
          value: on,
          onChanged: (value) => on = value,
        ),
      ),
    );
    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pump();
    expect(on, isTrue);
  });

  testWidgets('check list reports the tapped row', (tester) async {
    var selected = 'a';
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => IosCheckList<String>(
            value: selected,
            options: const [
              IosCheckOption(value: 'a', label: 'Первый'),
              IosCheckOption(value: 'b', label: 'Второй'),
            ],
            onChanged: (value) => setState(() => selected = value),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Второй'));
    await tester.pump();
    expect(selected, 'b');
  });

  testWidgets('stepped slider snaps a tap to the nearest step', (tester) async {
    double? got;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: IosSteppedSlider(
                value: 0,
                steps: const [0, 0.5, 1],
                semanticLabel: 'Размер текста',
                onChanged: (value) => got = value,
              ),
            ),
          ),
        ),
      ),
    );
    final box = tester.getRect(
      find.descendant(
        of: find.byType(IosTrackSlider),
        matching: find.byType(CustomPaint),
      ),
    );
    await tester.tapAt(box.center);
    await tester.pump();
    expect(got, 0.5);
    await tester.tapAt(Offset(box.right - 2, box.center.dy));
    await tester.pump();
    expect(got, 1.0);
  });

  testWidgets('controls expose selected tile, slider value and switch state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              IosTilePicker<String>(
                value: 'night',
                options: const [
                  IosTileOption(
                    value: 'system',
                    icon: Icons.circle,
                    label: 'Система',
                  ),
                  IosTileOption(
                    value: 'night',
                    icon: Icons.nightlight,
                    label: 'Ночь',
                  ),
                ],
                onChanged: (_) {},
              ),
              const IosToggleCard(
                label: 'Тактильный отклик',
                value: true,
                onChanged: _ignoreToggle,
              ),
              IosSteppedSlider(
                value: 1,
                steps: const [0.5, 1, 1.5],
                semanticLabel: 'Размер текста',
                semanticValue: '100%',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    final night = tester.getSemantics(find.bySemanticsLabel('Ночь'));
    expect(night.label, 'Ночь');
    expect(night.value, 'Выбрано');
    expect(night.flagsCollection.isSelected, Tristate.isTrue);
    expect(night.flagsCollection.isButton, isTrue);
    final toggle = tester.getSemantics(
      find.bySemanticsLabel('Тактильный отклик'),
    );
    expect(toggle.label, 'Тактильный отклик');
    expect(toggle.value, 'Включено');
    expect(toggle.flagsCollection.isToggled, Tristate.isTrue);
    final slider = tester.getSemantics(find.bySemanticsLabel('Размер текста'));
    expect(slider.label, 'Размер текста');
    expect(slider.value, '100%');
    expect(slider.flagsCollection.isSlider, isTrue);
    handle.dispose();
  });

  testWidgets('toggle label wraps at a large text scale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: IosToggleCard(
              label:
                  'Очень длинная подпись переключателя без обрезки строки в настройках',
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Очень длинная'), findsOneWidget);
  });
}

void _ignoreToggle(bool value) {}
