import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/modules/messages.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/attachment/bubbles/ios_bubble_metrics.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/message_bubble.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int _peer = 7;

CachedMessage _text(String id, DateTime time) => CachedMessage(
  id: id,
  accountId: 1,
  chatId: 2,
  senderId: _peer,
  text: 'Синтетический текст',
  time: time.millisecondsSinceEpoch,
  status: 'sent',
);

Future<void> _pump(
  WidgetTester tester, {
  required CachedMessage message,
  CachedMessage? prev,
}) async {
  await tester.pumpWidget(
    IosGlass(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MessageBubble(
            message: message,
            prevMessage: prev,
            isMe: false,
            myId: 1,
            chatType: 'DIALOG',
            listWidth: 390,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

double _topMargin(WidgetTester tester) {
  final paddings = tester.widgetList<Padding>(
    find.descendant(
      of: find.byType(MessageBubble),
      matching: find.byType(Padding),
    ),
  );
  return (paddings.first.padding as EdgeInsets).top;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
  });

  tearDown(AppIosGlass.debugReset);

  test('ширина бабла на телефоне и планшете', () {
    expect(IosBubbleMetrics.maxBubbleWidth(390, avatarSlot: false), 339);
    expect(IosBubbleMetrics.maxBubbleWidth(390, avatarSlot: true), 301);
    expect(IosBubbleMetrics.maxBubbleWidth(820, avatarSlot: false), 682);
  });

  final first = DateTime(2026, 1, 1, 12);
  final sevenMinutesLater = first.add(const Duration(minutes: 7));

  testWidgets('в iOS-режиме сообщения через 7 минут сливаются в группу', (
    tester,
  ) async {
    AppIosGlass.debugSetSupported(true);
    await _pump(
      tester,
      message: _text('2', sevenMinutesLater),
      prev: _text('1', first),
    );
    expect(_topMargin(tester), IosBubbleMetrics.mergedSpacing);
  });

  testWidgets('вне iOS-режима окно группировки прежнее, 5 минут', (
    tester,
  ) async {
    AppIosGlass.debugSetSupported(false);
    await _pump(
      tester,
      message: _text('2', sevenMinutesLater),
      prev: _text('1', first),
    );
    expect(_topMargin(tester), 4);
  });

  testWidgets('в iOS-режиме группа не переходит через полночь', (tester) async {
    AppIosGlass.debugSetSupported(true);
    await _pump(
      tester,
      message: _text('2', DateTime(2026, 1, 2, 0, 2)),
      prev: _text('1', DateTime(2026, 1, 1, 23, 58)),
    );
    expect(_topMargin(tester), IosBubbleMetrics.groupSpacing);
  });
}
