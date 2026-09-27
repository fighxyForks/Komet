import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/native/native_chat_bridge.dart';
import 'package:komet/core/native/native_transcript_insets.dart';
import 'package:komet/frontend/native/native_history_status.dart';
import 'package:komet/frontend/native/native_settings_view.dart';
import 'package:komet/frontend/screens/profile/settings_tab.dart';
import 'package:komet/frontend/widgets/glass/ios_native_tab_bar.dart';
import 'package:komet/frontend/widgets/glass/ios_palette.dart';

import 'fixtures/native_chat_fixtures.dart';

NativeChatCallbacks _callbacks() => NativeChatCallbacks(
  onOpen: (_) {},
  onLongPress: (_, _) {},
  onReply: (_) {},
  onReaction: (_, _) {},
  onSelect: (_) {},
  onReplyJump: (_) {},
  onMedia: (_, _) {},
  onLink: (_) {},
  onMention: (_) {},
  onPoll: (_, _) {},
  onKeyboard: (_, _) {},
  onTranscribe: (_) {},
  onVoice: (_) {},
  onVoiceSeek: (_, _) {},
  onComments: (_) {},
  onSticker: (_) {},
  onAvatar: (_) {},
  onLoadOlder: () {},
  onLoadNewer: () {},
  onNearBottom: (_) {},
  onVisible: (_) {},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('фикстуры покрывают виды сообщений и не содержат личных данных', () {
    final items = nativeChatFixtures();
    final kinds = items.map((item) => item.kind).toSet();
    expect(kinds, containsAll([
      NativeChatKind.text,
      NativeChatKind.photo,
      NativeChatKind.album,
      NativeChatKind.voice,
      NativeChatKind.videoNote,
      NativeChatKind.sticker,
      NativeChatKind.poll,
      NativeChatKind.control,
    ]));
    final blob = items.map((item) => item.toMap().toString()).join();
    expect(blob.contains('+7'), isFalse);
    expect(blob.contains('example.test'), isTrue);
  });

  test('вставки под шапку и композер считаются отдельно', () {
    final under = NativeTranscriptInsets.compute(
      underlap: true,
      statusBar: 47,
      header: 56,
      pinned: 40,
      callBanner: 64,
      composer: 96,
      panels: 20,
    );
    expect(under.top, 47 + 56 + 40 + 64);
    expect(under.bottom, 96 + 20 + NativeTranscriptInsets.composerGap);
    final flat = NativeTranscriptInsets.compute(
      underlap: false,
      statusBar: 47,
      header: 56,
      pinned: 40,
      callBanner: 64,
      composer: 80,
      panels: 0,
    );
    expect(flat.top, 0);
    expect(flat.bottom, 80 + NativeTranscriptInsets.composerGap);
  });

  test('строки настроек идут в порядке профиля', () {
    expect(nativeSettingsIdentityIds(showExtra: false), [
      'digital-id',
      'sferum',
      'security',
      'devices',
    ]);
    expect(nativeSettingsIdentityIds(showExtra: true).last, 'info');
  });

  test('полезная нагрузка настроек не содержит keywords', () {
    const row = NativeSettingsRow(id: 'theme', title: 'Тема', symbol: 'moon');
    expect(row.toMap().containsKey('keywords'), isFalse);
  });

  test('фон настроек один и тот же для каркаса и списка', () {
    const dark = ColorScheme.dark();
    const light = ColorScheme.light();
    expect(IosPalette.systemGrouped(dark), const Color(0xFF000000));
    expect(IosPalette.systemGrouped(light), const Color(0xFFF2F2F7));
    expect(
      IosPalette.systemGrouped(dark).toARGB32(),
      const Color(0xFF000000).toARGB32(),
    );
    expect(IosNativeTabBar.height, greaterThan(0));
  });

  testWidgets('равная нагрузка настроек не шлёт повторный apply', (tester) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('ru.komet.app/native_settings/test');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return null;
    });
    NativeSettingsView.debugChannel = channel;
    addTearDown(() {
      NativeSettingsView.debugResetChannel();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });

    Widget page(String title) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: NativeSettingsView(
          name: 'Имя',
          status: '',
          online: false,
          phone: '••••',
          bio: '',
          avatarUrl: '',
          canEditAvatar: false,
          version: '1',
          topInset: 0,
          sections: [
            NativeSettingsSection(
              rows: [
                NativeSettingsRow(id: 'saved', title: title, symbol: 'bookmark'),
              ],
            ),
          ],
          onTap: (_) {},
          onHeader: (_, _) {},
        ),
      );
    }

    await tester.pumpWidget(page('Избранное'));
    await tester.pump();
    calls.clear();
    await tester.pumpWidget(page('Избранное'));
    await tester.pump();
    expect(calls.where((call) => call.method == 'apply'), isEmpty);
    await tester.pumpWidget(page('Папки'));
    await tester.pump();
    expect(calls.where((call) => call.method == 'apply'), hasLength(1));
  });

  testWidgets('повтор загрузки истории вызывает загрузчик', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NativeHistoryRetry(onRetry: () => taps++),
      ),
    );
    expect(find.text('Не удалось загрузить историю'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    expect(taps, 1);
  });

  group('мост переписки', () {
    const channelName = '${NativeChatBridge.viewType}/9';

    NativeChatItem item(String id) => NativeChatItem(
      id: id,
      role: NativeChatRole.message,
      text: id,
    );

    test('три быстрых обновления схлопываются в последнее', () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <MethodCall>[];
      final gate = Completer<void>();
      messenger.setMockMethodCallHandler(const MethodChannel(channelName), (
        call,
      ) async {
        calls.add(call);
        if (calls.length == 1) await gate.future;
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          const MethodChannel(channelName),
          null,
        ),
      );
      final controller = NativeChatController(9, _callbacks());
      addTearDown(controller.dispose);
      final first = controller.update([item('a')]);
      await Future<void>.delayed(Duration.zero);
      final second = controller.update([item('b')]);
      final third = controller.update([item('c')]);
      gate.complete();
      await Future.wait([first, second, third]);
      expect(calls.length, lessThanOrEqualTo(2));
      final last = calls.last.arguments as Map;
      expect(last['order'], ['c']);
      expect(controller.debugSent.single.id, 'c');
    });

    test('ошибка второго обновления приводит к полной пересылке', () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(const MethodChannel(channelName), (
        call,
      ) async {
        calls.add(call);
        if (calls.length == 2) {
          throw PlatformException(code: 'fail');
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          const MethodChannel(channelName),
          null,
        ),
      );
      final controller = NativeChatController(9, _callbacks());
      addTearDown(controller.dispose);
      await controller.update([item('a')]);
      await controller.update([item('a'), item('b')]);
      expect(controller.debugSent.map((row) => row.id), ['a']);
      await controller.update([item('a'), item('b'), item('c')]);
      final last = calls.last.arguments as Map;
      expect(last['order'], ['a', 'b', 'c']);
      expect((last['items'] as List).length, 3);
      expect(controller.debugSent.map((row) => row.id), ['a', 'b', 'c']);
    });
  });
}
