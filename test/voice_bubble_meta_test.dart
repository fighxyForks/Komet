import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/utils/format.dart';
import 'package:komet/frontend/widgets/attachment/bubbles/voice_bubble.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _time = DateTime(2026, 9, 24, 18, 15).millisecondsSinceEpoch;

Widget _bubble({required bool showMeta}) => MaterialApp(
  home: Scaffold(
    body: VoiceMessageBubble(
      duration: 27,
      url: '',
      textColor: Colors.white,
      isMe: false,
      showMeta: showMeta,
      time: _time,
      cs: const ColorScheme.dark(),
      chatId: 1,
      messageId: '1',
      senderId: 2,
    ),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('время голосового рисуется в самом бабле без реакций', (
    tester,
  ) async {
    await tester.pumpWidget(_bubble(showMeta: true));
    expect(
      find.text(formatClock(DateTime.fromMillisecondsSinceEpoch(_time))),
      findsOneWidget,
    );
  });

  testWidgets('с реакциями время уходит в футер и не дублируется', (
    tester,
  ) async {
    await tester.pumpWidget(_bubble(showMeta: false));
    expect(
      find.text(formatClock(DateTime.fromMillisecondsSinceEpoch(_time))),
      findsNothing,
    );
  });
}
