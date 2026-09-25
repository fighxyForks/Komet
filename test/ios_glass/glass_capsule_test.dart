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
      // Style tier without nativeViews prefers opaque fills (no live blur).
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(LiquidGlassContainer), findsNothing);
    });

    testWidgets('iOS 26 без нативного вида не размывает фон', (tester) async {
      AppIosGlass.debugIosMajorVersion = 26;
      AppIosGlass.debugNativeGlassSupported = true;
      await tester.pumpWidget(
        _host(
          const GlassCapsule(
            allowNative: false,
            width: 120,
            height: 44,
            child: Text('field'),
          ),
        ),
      );
      expect(AppIosGlass.nativeViews, isTrue);
      expect(find.byType(LiquidGlassContainer), findsNothing);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('field'), findsOneWidget);
    });

    testWidgets('нативное стекло не сменяется заливкой при прокрутке', (
      tester,
    ) async {
      AppIosGlass.debugIosMajorVersion = 26;
      AppIosGlass.debugNativeGlassSupported = true;
      await tester.pumpWidget(
        _host(
          const GlassCapsule(
            forceOpaque: true,
            width: 120,
            height: 44,
            child: Text('field'),
          ),
        ),
      );
      expect(find.byType(LiquidGlassContainer), findsOneWidget);
      expect(find.byType(GlassBackground), findsNothing);
    });

    testWidgets('непрозрачная капсула всё ещё принимает нажатие', (
      tester,
    ) async {
      var taps = 0;
      var longPresses = 0;
      await tester.pumpWidget(
        _host(
          GlassCapsule(
            forceOpaque: true,
            onTap: () => taps++,
            onLongPress: () => longPresses++,
            child: const Text('send'),
          ),
        ),
      );
      await tester.tap(find.text('send'));
      await tester.pump();
      expect(taps, 1);
      await tester.longPress(find.text('send'));
      await tester.pump();
      expect(longPresses, 1);
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

  testWidgets('NativeGlassScope выключает нативное стекло только внутри себя', (
    tester,
  ) async {
    final seen = <String, bool>{};
    await tester.pumpWidget(
      Column(
        textDirection: TextDirection.ltr,
        children: [
          Builder(
            builder: (context) {
              seen['outside'] = NativeGlassScope.of(context);
              return const SizedBox();
            },
          ),
          NativeGlassScope(
            enabled: false,
            child: Builder(
              builder: (context) {
                seen['inside'] = NativeGlassScope.of(context);
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
    expect(seen, {'outside': true, 'inside': false});
  });

  testWidgets('высокий контраст делает GlassBackground непрозрачным', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(highContrast: true),
            child: IosGlass(child: app!),
          );
        },
        home: const Scaffold(
          body: Center(child: GlassBackground(child: Text('opaque'))),
        ),
      ),
    );
    expect(find.text('opaque'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
