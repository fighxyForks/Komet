import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/modules/messages.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/screens/chats/chat/view/chat_app_bar.dart';
import 'package:komet/frontend/screens/chats/chat/view/chat_header.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/message_bubble.dart';
import 'package:komet/frontend/widgets/settings_card.dart';
import 'package:komet/frontend/widgets/sliding_pill_nav.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _pixel =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
    'AAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

CachedMessage _replyToPhoto() => CachedMessage(
  id: '1',
  accountId: 1,
  chatId: 2,
  senderId: 7,
  text: 'ответ',
  time: DateTime(2026, 1, 1, 5, 46).millisecondsSinceEpoch,
  status: 'sent',
  payload: {
    'link': {
      'type': 'REPLY',
      'message': {
        'id': '9',
        'sender': 7,
        'text': null,
        'time': 0,
        'attaches': [
          {
            '_type': 'PHOTO',
            'previewData': _pixel,
            'width': 800,
            'height': 600,
          },
        ],
      },
    },
  },
);

Widget _app(Widget body) => MaterialApp(
  locale: const Locale('ru'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => IosGlass(child: child!),
  home: Scaffold(body: body),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  test('высоты шапки и панели уменьшаются только в iOS-режиме', () {
    expect(ChatAppBar.headerHeight(glossy: true, ios: true), 56);
    expect(ChatAppBar.headerHeight(glossy: true, ios: false), 76);
    expect(ChatAppBar.headerHeight(glossy: false, ios: false), kToolbarHeight);
    expect(SlidingPillNav.heightFor(ios: true), 58);
    expect(SlidingPillNav.heightFor(ios: false), 68);
  });

  testWidgets('капсулы шапки 46 точек и помещаются в 56', (tester) async {
    final status = ValueNotifier<String>('в сети');
    final scheduled = ValueNotifier<int>(0);
    final unread = ValueNotifier<int>(0);
    addTearDown(status.dispose);
    addTearDown(scheduled.dispose);
    addTearDown(unread.dispose);
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 56,
              child: ChatHeaderRow(
                glossy: false,
                frosted: false,
                cs: Theme.of(context).colorScheme,
                embedded: false,
                chatId: 0,
                heroTag: 'header',
                name: 'Синтетический чат',
                imageUrl: '',
                chatType: 'CHAT',
                isOfficial: false,
                myId: 1,
                headerStatus: status,
                scheduledCount: scheduled,
                otherUnread: unread,
                showCall: true,
                onClose: null,
                onOpenInfo: () {},
                onOpenScheduled: () {},
                onCall: () {},
                onMenu: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('chat-header-back'))),
      const Size(46, 46),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('chat-header-title'))).height,
      46,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('chat-header-menu'))),
      const Size(42, 46),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('медиа в цитате ответа — миниатюра 32×32', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        Align(
          alignment: Alignment.topLeft,
          child: MessageBubble(
            message: _replyToPhoto(),
            isMe: false,
            myId: 1,
            chatType: 'DIALOG',
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const ValueKey('ios-reply-thumb'))),
      const Size(32, 32),
    );
  });

  testWidgets('в iOS-режиме подписи настроек обычного начертания', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const SettingsCard(
          children: [SettingsNavTile(icon: Symbols.lock, label: 'Защита')],
        ),
      ),
    );
    final label = tester.widget<Text>(find.text('Защита'));
    expect(label.style?.fontWeight, IosType.body);
  });
}
