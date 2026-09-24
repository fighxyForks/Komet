import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/modules/messages.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_typography.dart';
import 'package:komet/frontend/widgets/message_bubble.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:komet/models/animoji.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int _me = 1;
const int _peer = 7;

CachedMessage _text({required Map<String, dynamic> reactions}) =>
    CachedMessage(
      id: 'r1',
      accountId: _me,
      chatId: 2,
      senderId: _peer,
      text: 'привет',
      time: DateTime(2026, 1, 1, 12, 0).millisecondsSinceEpoch,
      status: 'sent',
      payload: {'reactionInfo': reactions},
    );

Future<void> _pump(
  WidgetTester tester,
  CachedMessage message, {
  required String chatType,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    IosGlass(
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(primary: Color(0xFF4082E6)),
        ),
        home: Scaffold(
          body: MessageBubble(
            key: const ValueKey('bubble'),
            message: message,
            isMe: false,
            myId: _me,
            chatType: chatType,
            reactionAnimojiResolver: (emoji) => Animoji(
              id: 1,
              emoji: emoji,
              iconUrl: 'https://example.com/a.png',
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  testWidgets('чип реакции высотой 30 и count 15 в iOS', (tester) async {
    await _pump(
      tester,
      _text(
        reactions: {
          'totalCount': 3,
          'counters': [
            {'reaction': '👍', 'count': 3},
          ],
        },
      ),
      chatType: 'CHAT',
    );

    final chip = find.byKey(const ValueKey('reaction-chip-👍'));
    expect(chip, findsOneWidget);
    expect(tester.getSize(chip).height, 30);

    final count = tester.widget<Text>(find.text('3'));
    expect(count.style?.fontSize, IosTypography.reactionCount);
    expect(count.style?.fontSize, 15);
  });

  testWidgets('свой чип залит accent, count onPrimary', (tester) async {
    const primary = Color(0xFF4082E6);
    await _pump(
      tester,
      _text(
        reactions: {
          'totalCount': 2,
          'counters': [
            {'reaction': '🔥', 'count': 2},
          ],
          'yourReaction': '🔥',
        },
      ),
      chatType: 'CHAT',
    );

    final chip = tester.widget<Container>(
      find.byKey(const ValueKey('reaction-chip-🔥')),
    );
    final decoration = chip.decoration! as BoxDecoration;
    expect(decoration.color, primary);

    final count = tester.widget<Text>(find.text('2'));
    expect(count.style?.color, const ColorScheme.dark().onPrimary);
  });

  testWidgets('в диалоге аватар ~20pt внутри капсулы', (tester) async {
    await _pump(
      tester,
      _text(
        reactions: {
          'totalCount': 1,
          'counters': [
            {'reaction': '❤️', 'count': 1},
          ],
          'yourReaction': '❤️',
        },
      ),
      chatType: 'DIALOG',
    );

    final chip = find.byKey(const ValueKey('reaction-chip-❤️'));
    expect(chip, findsOneWidget);
    expect(tester.getSize(chip).height, 30);

    final avatar = find.descendant(
      of: chip,
      matching: find.byType(CircleAvatar),
    );
    expect(avatar, findsOneWidget);
    expect(tester.getSize(avatar), const Size(20, 20));
  });
}
