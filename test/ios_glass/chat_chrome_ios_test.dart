import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/modules/messages.dart';
import 'package:komet/core/config/app_bubble_behavior.dart';
import 'package:komet/core/config/app_bubble_shape.dart';
import 'package:komet/core/config/app_chat_chrome.dart';
import 'package:komet/core/config/app_composer_background.dart';
import 'package:komet/core/config/app_composer_style.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/core/utils/bubble_radius.dart';
import 'package:komet/frontend/screens/chats/chat/upload_status.dart';
import 'package:komet/frontend/screens/chats/chat/video_note_controller.dart';
import 'package:komet/frontend/screens/chats/chat/view/composer_input.dart';
import 'package:komet/frontend/screens/chats/chat/voice_record_controller.dart';
import 'package:komet/frontend/widgets/glass/glass_capsule.dart';
import 'package:komet/frontend/widgets/glass/glass_controls.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/lottie_slash_icon.dart';
import 'package:komet/frontend/widgets/rich_message_controller.dart';
import 'package:komet/frontend/widgets/segmented_pill_toggle.dart';
import 'package:komet/frontend/widgets/settings_card.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget body) => MaterialApp(
  locale: const Locale('ru'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => IosGlass(child: child!),
  home: Scaffold(body: body),
);

class _ComposerHarness {
  final forwards = ValueNotifier<List<CachedMessage>>(const []);
  final reply = ValueNotifier<CachedMessage?>(null);
  final hasText = ValueNotifier(false);
  final uploadStatus = ValueNotifier(const UploadStatus());
  final messageController = RichMessageController();
  final focusNode = FocusNode();
  late final AnimationController attachAnimation;
  late BuildContext composerContext;
  late final VoiceRecordController voice;
  late final VideoNoteController note;

  _ComposerHarness() {
    attachAnimation = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 1),
    );
    voice = VoiceRecordController(
      contextOf: () => composerContext,
      isMounted: () => true,
      myId: () => 7,
      onRecorded: (File file, int durationMs, List<double> amplitudes) async {},
    );
    note = VideoNoteController(
      contextOf: () => composerContext,
      isMounted: () => true,
      onRecorded: (File file, int durationMs) async {},
      formatElapsed: (milliseconds) => '$milliseconds',
      bottomInset: () => 0,
    );
  }

  Widget build({
    required String chatType,
    bool subscribed = true,
    bool canPost = false,
    bool muted = false,
    VoidCallback? onToggleMute,
    VoidCallback? onSubscribe,
    VoidCallback? onOpenSearch,
    bool iosGlass = true,
  }) {
    return Builder(
      builder: (context) {
        composerContext = context;
        return Align(
          alignment: Alignment.bottomCenter,
          child: ComposerInputBar(
            chatType: chatType,
            chrome: ChatChromeStyle.transparent,
            style: ComposerStyle.glossy,
            background: ComposerBackground.frostBlur,
            iosGlass: iosGlass,
            attachAnim: attachAnimation,
            replyTo: reply,
            forwardMessages: forwards,
            myId: 7,
            hasText: hasText,
            uploadStatus: uploadStatus,
            messageController: messageController,
            messageFocusNode: focusNode,
            voiceRec: voice,
            note: note,
            onToggleStickerPanel: () {},
            onSendText: () {},
            onScheduleMessage: () {},
            onOpenAttach: () {},
            onOpenAttachScheduled: () {},
            onSendHistory: (_) async {},
            onCancelReply: () {},
            onCancelForward: () {},
            formatElapsed: (milliseconds) => '$milliseconds',
            contextMenuBuilder: (context, state) => const SizedBox.shrink(),
            isMuted: muted,
            onToggleMute: onToggleMute ?? () {},
            channelSubscribed: subscribed,
            canPostToChannel: canPost,
            onSubscribe: onSubscribe,
            onOpenSearch: onOpenSearch,
          ),
        );
      },
    );
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  group('Нижняя панель канала', () {
    testWidgets('подписка и поиск — отдельные стеклянные капсулы', (
      tester,
    ) async {
      final harness = _ComposerHarness();
      var subscribed = 0;
      var searched = 0;
      await tester.pumpWidget(
        _app(
          harness.build(
            chatType: 'CHANNEL',
            subscribed: false,
            onSubscribe: () => subscribed++,
            onOpenSearch: () => searched++,
          ),
        ),
      );
      expect(find.text('Подписаться'), findsOneWidget);
      final search = find.byKey(const ValueKey('ios-channel-search'));
      expect(search, findsOneWidget);
      final subscribeRect = tester.getRect(
        find.byKey(const ValueKey('ios-subscribe')),
      );
      expect(tester.getRect(search).left, greaterThan(subscribeRect.right));

      await tester.tap(find.text('Подписаться'));
      await tester.tap(search);
      await tester.pumpAndSettle();
      expect(subscribed, 1);
      expect(searched, 1);
    });

    testWidgets('звук переключается капсулой с анимированным колокольчиком', (
      tester,
    ) async {
      final harness = _ComposerHarness();
      var toggles = 0;
      await tester.pumpWidget(
        _app(
          harness.build(
            chatType: 'CHANNEL',
            muted: true,
            onToggleMute: () => toggles++,
            onOpenSearch: () {},
          ),
        ),
      );
      expect(find.text('Включить звук'), findsOneWidget);
      expect(
        tester.widget<LottieSlashIcon>(find.byType(LottieSlashIcon)).slashed,
        isTrue,
      );
      await tester.tap(find.byKey(const ValueKey('ios-mute')));
      await tester.pumpAndSettle();
      expect(toggles, 1);
    });

    testWidgets('админ канала получает обычное поле ввода в капсуле', (
      tester,
    ) async {
      final harness = _ComposerHarness();
      await tester.pumpWidget(
        _app(harness.build(chatType: 'CHANNEL', canPost: true)),
      );
      expect(find.byKey(const ValueKey('ios-mute')), findsNothing);
      expect(find.byKey(const ValueKey('ios-composer-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('ios-composer-action')), findsOneWidget);
    });

    testWidgets('без iOS панель канала остаётся прежней', (tester) async {
      final harness = _ComposerHarness();
      AppIosGlass.debugSetSupported(false);
      await tester.pumpWidget(
        _app(
          harness.build(
            chatType: 'CHANNEL',
            onOpenSearch: () {},
            iosGlass: false,
          ),
        ),
      );
      expect(find.text('Отключить уведомления'), findsOneWidget);
      expect(find.byKey(const ValueKey('ios-channel-search')), findsNothing);
    });
  });

  group('Стиль поля ввода', () {
    test('в iOS-режиме поле всегда глянцевое и матовое', () {
      expect(ComposerChrome.effective, ComposerStyle.glossy);
      expect(ComposerMaterial.effective, ComposerBackground.frostBlur);
      AppIosGlass.debugSetSupported(false);
      expect(ComposerChrome.effective, AppComposerStyle.current.value);
      expect(ComposerMaterial.effective, AppComposerBackground.current.value);
    });
  });

  group('Пузыри', () {
    test('iOS-скругления крупнее, стыки в группе мягче', () {
      final ios = computeBubbleRadius(
        isMe: true,
        isTop: true,
        isBottom: false,
        style: BubbleStyle.desktop,
        behavior: BubbleBehavior.values.first,
        ios: true,
      );
      expect(ios.topLeft.x, kIosBubbleRadius);
      final material = computeBubbleRadius(
        isMe: true,
        isTop: true,
        isBottom: true,
        style: BubbleStyle.mobile,
        behavior: BubbleBehavior.values.first,
        ios: false,
      );
      expect(material.topLeft.x, kBubbleBigRadius);
    });
  });

  group('Настройки', () {
    testWidgets('в iOS-режиме — сгруппированная секция и иконки-плашки', (
      tester,
    ) async {
      var value = false;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => SettingsCard(
              children: [
                SettingsToggleTile(
                  icon: Symbols.notifications,
                  label: 'Уведомления',
                  value: value,
                  onChanged: (v) => setState(() => value = v),
                ),
                const SettingsNavTile(icon: Symbols.lock, label: 'Защита'),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(IosGroupedSection), findsOneWidget);
      expect(find.byType(IosSettingsIcon), findsNWidgets(2));
      expect(find.byType(Switch), findsNothing);
      await tester.tap(find.text('Уведомления'));
      await tester.pump();
      expect(value, isTrue);
    });
  });

  group('Переключатель эмодзи/стикеры', () {
    testWidgets('рисуется на стеклянной капсуле с бегунком', (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => Center(
              child: SegmentedPillToggle(
                labels: const ['Эмодзи', 'Стикеры'],
                selected: selected,
                onChanged: (i) => setState(() => selected = i),
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('ios-segmented')), findsOneWidget);
      expect(find.byType(GlassSegmentThumb), findsOneWidget);
      expect(find.byType(GlassCapsule), findsOneWidget);
      await tester.tap(find.text('Стикеры'));
      await tester.pumpAndSettle();
      expect(selected, 1);
    });
  });
}
