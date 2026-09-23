import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/modules/messages.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_palette.dart';
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

BoxDecoration _bubbleDecoration(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .map((c) => c.decoration)
    .whereType<BoxDecoration>()
    .firstWhere((d) => d.gradient != null);

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
    final decoration = _bubbleDecoration(tester);
    expect(decoration.color, isNull);
    expect(decoration.border, isNotNull);
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
    final radius = _bubbleDecoration(tester).borderRadius! as BorderRadius;
    expect(radius.bottomLeft, radius.topLeft);
    expect(radius.bottomRight, radius.topRight);
    expect(find.text('3 комментария'), findsOneWidget);
  });
}
