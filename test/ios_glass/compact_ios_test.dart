import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/modules/messages.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/screens/chats/chat/view/chat_app_bar.dart';
import 'package:komet/frontend/screens/chats/chat/view/chat_header.dart';
import 'package:komet/frontend/screens/chats/chat/view/message_row_widgets.dart';
import 'package:komet/frontend/screens/chats/chat/view/scroll_down_button.dart';
import 'package:komet/frontend/widgets/glass/glass_capsule.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_palette.dart';
import 'package:komet/frontend/widgets/media_playback_pill.dart';
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

Widget _header(BuildContext context, String name) {
  return ChatHeaderRow(
    glossy: false,
    frosted: false,
    cs: Theme.of(context).colorScheme,
    embedded: false,
    chatId: 0,
    heroTag: 'header-$name',
    name: name,
    imageUrl: '',
    chatType: 'CHAT',
    isOfficial: false,
    myId: 1,
    headerStatus: ValueNotifier<String>('в сети'),
    scheduledCount: ValueNotifier<int>(0),
    otherUnread: ValueNotifier<int>(0),
    showCall: true,
    onClose: null,
    onOpenInfo: () {},
    onOpenScheduled: () {},
    onCall: () {},
    onMenu: (_) {},
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  test('высоты шапки и панели задаются только в iOS-режиме', () {
    expect(ChatAppBar.headerHeight(glossy: true, ios: true), 56);
    expect(ChatAppBar.headerHeight(glossy: true, ios: false), 76);
    expect(ChatAppBar.headerHeight(glossy: false, ios: false), kToolbarHeight);
    expect(SlidingPillNav.heightFor(ios: true), 62);
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

  testWidgets('капсула с названием подстраивается под длину', (tester) async {
    Future<double> widthFor(String name) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Align(
              alignment: Alignment.topCenter,
              child: SizedBox(height: 56, child: _header(context, name)),
            ),
          ),
        ),
      );
      return tester
          .getSize(find.byKey(const ValueKey('chat-header-title')))
          .width;
    }

    final short = await widthFor('Аня');
    final long = await widthFor(
      'Очень длинное синтетическое название группы для проверки',
    );
    expect(short, lessThan(long));
    final back = tester.getRect(find.byKey(const ValueKey('chat-header-back')));
    final actions = tester.getRect(
      find.byKey(const ValueKey('chat-header-actions')),
    );
    final title = tester.getRect(
      find.byKey(const ValueKey('chat-header-title')),
    );
    expect(title.left, greaterThan(back.right));
    expect(title.right, lessThanOrEqualTo(actions.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('кнопка «вниз» на одной линии с микрофоном', (tester) async {
    final controller = AnimationController(vsync: const TestVSync(), value: 1);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Stack(
          children: [
            ScrollDownButton(
              composerHeight: ValueNotifier<double>(70),
              materialComposer: false,
              composerUnderlap: true,
              frosted: true,
              liquidChrome: false,
              pillBackdrop: null,
              scrollDownCurved: controller,
              newMessageCount: ValueNotifier<int>(0),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
    final screen = tester.getSize(find.byType(Stack).first).width;
    final button = tester.getCenter(
      find.byKey(const ValueKey('ios-scroll-down')),
    );
    const micCenterFromRight =
        ScrollDownButton.iosActionInset + ScrollDownButton.iosActionSize / 2;
    expect(screen - button.dx, closeTo(micCenterFromRight, 0.01));
  });

  test('цвет значков статус-бара следует фону', () {
    expect(
      IosPalette.overlayFor(Colors.white).statusBarBrightness,
      SystemUiOverlayStyle.dark.statusBarBrightness,
    );
    expect(
      IosPalette.overlayFor(Colors.black).statusBarBrightness,
      SystemUiOverlayStyle.light.statusBarBrightness,
    );
  });

  testWidgets('закреп — компактная стеклянная капсула как в шапке', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Align(
          alignment: Alignment.topCenter,
          child: PinnedMessageBanner(
            text: 'Синтетическое закреплённое сообщение',
            isPreview: false,
            floating: true,
            onTap: () {},
          ),
        ),
      ),
    );
    final banner = find.byKey(const ValueKey('ios-pinned-banner'));
    expect(tester.widget(banner), isA<GlassCapsule>());
    expect(tester.widget<GlassCapsule>(banner).allowNative, isTrue);
    expect(tester.getSize(banner).height, lessThanOrEqualTo(50));
  });

  testWidgets('кнопка «вниз» — нативное стекло', (tester) async {
    final controller = AnimationController(vsync: const TestVSync(), value: 1);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Stack(
          children: [
            ScrollDownButton(
              composerHeight: ValueNotifier<double>(70),
              materialComposer: false,
              composerUnderlap: true,
              frosted: true,
              liquidChrome: false,
              pillBackdrop: null,
              scrollDownCurved: controller,
              newMessageCount: ValueNotifier<int>(0),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
    final button = tester.widget<GlassCapsule>(
      find.byKey(const ValueKey('ios-scroll-down')),
    );
    expect(button.allowNative, isTrue);
  });

  test('плашка голосового в iOS выше и заметнее', () {
    expect(MediaPlaybackPill.iosHeight, greaterThan(MediaPlaybackPill.height));
  });
}
