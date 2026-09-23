import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/glass/glass_capsule.dart';
import 'package:komet/frontend/widgets/glass/glass_controls.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child) => MaterialApp(
  builder: (context, app) => IosGlass(child: app!),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  group('Капсулы', () {
    testWidgets('без нативного стекла рисуется Flutter-подложка', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const GlassCapsule(child: Text('chrome'))));
      expect(find.text('chrome'), findsOneWidget);
      expect(find.byType(GlassBackground), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(LiquidGlassContainer), findsNothing);
    });

    testWidgets('кнопка вызывает колбэк и отдаёт свой прямоугольник', (
      tester,
    ) async {
      var pressed = 0;
      Rect? anchor;
      await tester.pumpWidget(
        _host(
          GlassIconButton(
            icon: Symbols.more_horiz,
            tooltip: 'Ещё',
            onPressed: () => pressed++,
            onPressedAt: (rect) => anchor = rect,
          ),
        ),
      );
      await tester.tap(find.byType(GlassIconButton));
      await tester.pumpAndSettle();
      expect(pressed, 1);
      expect(anchor?.size, const Size(44, 44));
      expect(find.bySemanticsLabel('Ещё'), findsOneWidget);
    });

    testWidgets('группа кнопок — одна подложка на все элементы', (
      tester,
    ) async {
      final taps = <String>[];
      await tester.pumpWidget(
        _host(
          GlassButtonGroup(
            items: [
              GlassGroupItem(
                key: const ValueKey('a'),
                icon: Symbols.download,
                onPressed: () => taps.add('a'),
              ),
              GlassGroupItem(
                key: const ValueKey('b'),
                icon: Symbols.more_horiz,
                onPressedAt: (_) => taps.add('b'),
              ),
            ],
          ),
        ),
      );
      expect(find.byType(GlassBackground), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('b')));
      await tester.tap(find.byKey(const ValueKey('a')));
      await tester.pumpAndSettle();
      expect(taps, ['b', 'a']);
    });
  });

  group('Переключатель', () {
    testWidgets('в iOS-режиме — купертиновский, иначе Material', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(GlassSwitch(value: true, onChanged: (_) {})),
      );
      expect(find.byType(Switch), findsNothing);
      AppIosGlass.debugSetSupported(false);
      await tester.pump();
      expect(find.byType(Switch), findsOneWidget);
    });
  });

  group('Подавление стекла', () {
    test('счётчик держится до последнего release', () {
      final a = GlassSuppression.hold();
      final b = GlassSuppression.hold();
      expect(GlassSuppression.count.value, 2);
      a();
      a();
      expect(GlassSuppression.count.value, 1);
      b();
      expect(GlassSuppression.count.value, 0);
    });
  });

  group('Размер содержимого нативного стекла', () {
    test('растянутая по ширине капсула отдаёт ширину содержимому', () {
      final (w, h) = GlassCapsule.nativeExtent(
        const BoxConstraints.tightFor(width: 170),
        null,
        46,
      );
      expect(w, 170);
      expect(h, 46);
    });

    test('свободная капсула сохраняет размер по содержимому', () {
      final (w, h) = GlassCapsule.nativeExtent(
        const BoxConstraints(maxWidth: 390, maxHeight: 800),
        null,
        null,
      );
      expect(w, isNull);
      expect(h, isNull);
    });

    test('явные размеры важнее ограничений', () {
      final (w, h) = GlassCapsule.nativeExtent(
        const BoxConstraints.tightFor(width: 300, height: 60),
        46,
        46,
      );
      expect(w, 46);
      expect(h, 46);
    });
  });
}
