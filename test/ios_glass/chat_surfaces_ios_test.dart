import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/modules/messages.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/screens/chats/chat/chat_controller.dart';
import 'package:komet/frontend/screens/chats/chat/view/message_list_decorations.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_palette.dart';
import 'package:komet/frontend/widgets/mesh_gradient_background.dart';
import 'package:komet/frontend/widgets/theme_reveal.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget body, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      builder: (context, child) => IosGlass(child: child!),
      home: Scaffold(body: body),
    );

const List<Color> _colors = [
  Color(0xFF3366FF),
  Color(0xFF33CC99),
  Color(0xFFFFCC33),
  Color(0xFFFF6699),
];

BoxDecoration _datePill(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .ancestor(
                    of: find.byType(Text),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  group('Затухание у краёв ленты', () {
    testWidgets('плотное под шапкой и прозрачное к ленте', (tester) async {
      await tester.pumpWidget(
        _app(
          const Align(
            alignment: Alignment.topCenter,
            child: IosScrollEdgeFade(
              top: true,
              height: 100,
              overWallpaper: false,
            ),
          ),
        ),
      );
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(IosScrollEdgeFade),
          matching: find.byType(DecoratedBox),
        ),
      );
      final gradient =
          (box.decoration as BoxDecoration).gradient! as LinearGradient;
      expect(gradient.begin, Alignment.topCenter);
      expect(
        gradient.colors.first.a,
        closeTo(IosScrollEdgeFade.plainOpacity, 0.01),
      );
      expect(gradient.colors.last.a, 0);
      expect(
        tester.getSize(find.byType(IosScrollEdgeFade)).height,
        100 + IosScrollEdgeFade.extent,
      );
    });

    testWidgets('над обоями слабее, чтобы обои оставались видны', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Align(
            alignment: Alignment.bottomCenter,
            child: IosScrollEdgeFade(
              top: false,
              height: 60,
              overWallpaper: true,
            ),
          ),
        ),
      );
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(IosScrollEdgeFade),
          matching: find.byType(DecoratedBox),
        ),
      );
      final gradient =
          (box.decoration as BoxDecoration).gradient! as LinearGradient;
      expect(gradient.begin, Alignment.bottomCenter);
      expect(
        gradient.colors.first.a,
        closeTo(IosScrollEdgeFade.wallpaperOpacity, 0.01),
      );
    });
  });

  group('Служебные плашки', () {
    testWidgets('дата в iOS-режиме — полупрозрачная плашка с ободком', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(Center(child: DateSeparatorLabel(date: DateTime(2020, 5, 17)))),
      );
      final decoration = _datePill(tester);
      expect(decoration.color!.a, lessThan(1));
      expect(decoration.border, isNotNull);
    });

    testWidgets('в тёмной теме плашка затемняет фон', (tester) async {
      await tester.pumpWidget(
        _app(
          Center(child: DateSeparatorLabel(date: DateTime(2020, 5, 17))),
          brightness: Brightness.dark,
        ),
      );
      final color = _datePill(tester).color!;
      expect(color.computeLuminance(), lessThan(0.05));
      expect(color.a, lessThan(1));
    });

    testWidgets('вне iOS-режима дата остаётся на сплошной подложке', (
      tester,
    ) async {
      AppIosGlass.debugSetSupported(false);
      await tester.pumpWidget(
        _app(Center(child: DateSeparatorLabel(date: DateTime(2020, 5, 17)))),
      );
      final decoration = _datePill(tester);
      expect(decoration.color!.a, 1);
      expect(decoration.border, isNull);
    });

    test('текст на плашке контрастный', () {
      final cs = ColorScheme.fromSeed(seedColor: Colors.blue);
      expect(IosPalette.serviceText(cs), cs.onSurface);
    });
  });

  group('Градиентные обои по событиям', () {
    setUp(() async {
      await MeshGradient.load();
    });

    testWidgets('в iOS-режиме обои в покое не перерисовываются', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const MeshGradientBackground(colors: _colors, stepOnPulse: true)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('новое сообщение сдвигает градиент на один шаг', (
      tester,
    ) async {
      if (!MeshGradient.isSupported) return;
      await tester.pumpWidget(
        _app(const MeshGradientBackground(colors: _colors, stepOnPulse: true)),
      );
      MeshGradientPulse.pulse();
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isTrue);
      var frames = 0;
      while (tester.binding.hasScheduledFrame && frames < 200) {
        await tester.pump(const Duration(milliseconds: 16));
        frames++;
      }
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(
        frames * 16,
        lessThanOrEqualTo(
          MeshGradientBackground.pulseStepDuration.inMilliseconds + 32,
        ),
      );
    });

    testWidgets('без событийного режима анимация идёт непрерывно', (
      tester,
    ) async {
      if (!MeshGradient.isSupported) return;
      await tester.pumpWidget(
        _app(const MeshGradientBackground(colors: _colors)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    test('добавление сообщения в ленту даёт событие', () {
      final controller = ChatController();
      addTearDown(controller.dispose);
      var events = 0;
      controller.appendedCount.addListener(() => events++);
      controller.addMessage(
        CachedMessage(
          id: 'synthetic-1',
          accountId: 1,
          chatId: 2,
          senderId: 3,
          text: 'синтетика',
          time: DateTime(2026, 1, 1).millisecondsSinceEpoch,
          status: 'sent',
        ),
      );
      expect(events, 1);
    });
  });

  testWidgets('смена темы в iOS-режиме — плавное растворение снимка', (
    tester,
  ) async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.black, BlendMode.src);
    final snapshot = recorder.endRecording().toImageSync(4, 4);
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 300),
    );
    addTearDown(controller.dispose);
    final entry = ThemeRevealOverlay.crossfade(
      snapshot: snapshot,
      animation: controller,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Overlay(
          initialEntries: [
            OverlayEntry(builder: (_) => const SizedBox()),
            entry,
          ],
        ),
      ),
    );
    FadeTransition fade() => tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(RawImage),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade().opacity.value, 1);
    controller.value = 0.5;
    expect(fade().opacity.value, 0.5);
    controller.value = 1;
    expect(fade().opacity.value, 0);
    expect(find.byType(IgnorePointer), findsWidgets);
    entry.remove();
    snapshot.dispose();
  });
}
