import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/modules/messages.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_palette.dart';
import 'package:komet/frontend/widgets/glass/screen_gradient_bubble.dart';
import 'package:komet/frontend/widgets/message_bubble.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

CachedMessage _message(String id, int minute) => CachedMessage(
  id: id,
  accountId: 1,
  chatId: 2,
  senderId: 7,
  text: 'синтетический пост',
  time: DateTime(2026, 1, 1, 5, minute).millisecondsSinceEpoch,
  status: 'sent',
);

Widget _app(Widget body, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => IosGlass(child: child!),
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: body),
      ),
    );

ScreenGradientBox _bubbleBox(WidgetTester tester) =>
    tester.widget<ScreenGradientBox>(find.byType(ScreenGradientBox));

Widget _bubble() => MessageBubble(
  message: _message('1', 1),
  isMe: true,
  myId: 1,
  chatType: 'DIALOG',
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  test(
    'входящие: светлая тема от белого к серому, тёмная — от тёмно-серого к серому',
    () {
      final light = IosPalette.bubbleGradient(
        ColorScheme.fromSeed(seedColor: Colors.blue),
        isMe: false,
      );
      expect(light.colors.first, Colors.white);
      expect(
        light.colors.last.computeLuminance(),
        lessThan(light.colors.first.computeLuminance()),
      );
      final dark = IosPalette.bubbleGradient(
        ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        isMe: false,
      );
      expect(
        dark.colors.first.computeLuminance(),
        lessThan(dark.colors.last.computeLuminance()),
      );
    },
  );

  test('свои сообщения остаются в акцентном оттенке', () {
    final cs = ColorScheme.fromSeed(seedColor: Colors.blue);
    final mine = IosPalette.bubbleGradient(cs, isMe: true);
    expect(mine.colors.last, cs.primaryContainer);
  });

  testWidgets('в iOS-режиме бабл — стеклянный градиент с ободком', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MessageBubble(
          message: _message('1', 1),
          isMe: false,
          myId: 1,
          chatType: 'DIALOG',
        ),
      ),
    );
    final box = _bubbleBox(tester);
    expect(box.colors, hasLength(2));
    expect(box.rim.a, greaterThan(0));
  });

  testWidgets('низ поста с комментариями скруглён как верх', (tester) async {
    await tester.pumpWidget(
      _app(
        MessageBubble(
          message: _message('1', 1),
          nextMessage: _message('2', 1),
          isMe: false,
          myId: 1,
          chatType: 'CHANNEL',
          commentsLabel: '3 комментария',
          onCommentsTap: () {},
        ),
      ),
    );
    final radius = _bubbleBox(tester).borderRadius;
    expect(radius.bottomLeft, radius.topLeft);
    expect(radius.bottomRight, radius.topRight);
    expect(find.text('3 комментария'), findsOneWidget);
  });

  testWidgets('градиент привязан к экрану: срез зависит от положения бабла', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Column(children: [_bubble(), const SizedBox(height: 300), _bubble()]),
      ),
    );
    final boxes = tester
        .renderObjectList<RenderScreenGradientBox>(
          find.byType(ScreenGradientBox),
        )
        .toList();
    expect(boxes, hasLength(2));
    final upper = boxes[0].debugPaintedTop!;
    final lower = boxes[1].debugPaintedTop!;
    expect(lower - upper, greaterThan(300));
    expect(
      tester
          .widget<ScreenGradientBox>(find.byType(ScreenGradientBox).first)
          .viewportHeight,
      600,
    );
  });

  testWidgets('срез обновляется, когда бабл сдвигается без прокрутки', (
    tester,
  ) async {
    final gap = ValueNotifier<double>(0);
    addTearDown(gap.dispose);
    await tester.pumpWidget(
      _app(
        ValueListenableBuilder<double>(
          valueListenable: gap,
          builder: (context, value, _) => Column(
            children: [
              SizedBox(height: value),
              _bubble(),
            ],
          ),
        ),
      ),
    );
    final box = tester.renderObject<RenderScreenGradientBox>(
      find.byType(ScreenGradientBox),
    );
    final before = box.debugPaintedTop!;
    gap.value = 120;
    await tester.pump();
    await tester.pump();
    expect(box.debugPaintedTop, closeTo(before + 120, 0.01));
  });

  testWidgets('вне iOS-режима бабл остаётся сплошным', (tester) async {
    AppIosGlass.debugSetSupported(false);
    await tester.pumpWidget(_app(_bubble()));
    expect(find.byType(ScreenGradientBox), findsNothing);
  });
}
