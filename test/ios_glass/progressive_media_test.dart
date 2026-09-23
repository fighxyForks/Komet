import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/modules/messages.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/core/media/preview_image.dart';
import 'package:komet/frontend/widgets/attachment/bubbles/bubble_context.dart';
import 'package:komet/frontend/widgets/attachment/bubbles/progressive_media_image.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/message_bubble.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:komet/models/attachment.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _pixel =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

const _photo = PhotoAttachment(
  baseUrl: 'https://example.com/synthetic-photo.jpg',
  previewData: _pixel,
  width: 800,
  height: 600,
);

const _video = VideoAttachment(
  baseUrl: 'https://example.com/synthetic-clip.mp4',
  thumbnail: 'https://example.com/synthetic-clip.jpg',
  previewData: _pixel,
  videoId: 42,
  videoToken: 'synthetic-token',
  width: 1920,
  height: 1080,
  duration: 5000,
);

CachedMessage _message(MessageAttachment attachment) => CachedMessage(
  id: '1',
  accountId: 1,
  chatId: 2,
  senderId: 7,
  time: DateTime(2026, 1, 1, 12).millisecondsSinceEpoch,
  status: 'sent',
  attachments: [attachment],
);

Future<void> _pump(WidgetTester tester, MessageAttachment attachment) async {
  await tester.pumpWidget(
    IosGlass(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: MessageBubble(
              message: _message(attachment),
              isMe: false,
              myId: 1,
              chatType: 'DIALOG',
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
  });

  tearDown(AppIosGlass.debugReset);

  testWidgets('в iOS-режиме фото грузится поверх размытого превью', (
    tester,
  ) async {
    AppIosGlass.debugSetSupported(true);
    await _pump(tester, _photo);

    final image = tester.widget<ProgressiveMediaImage>(
      find.byType(ProgressiveMediaImage),
    );
    expect(image.preview, isNotNull);
    final network = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(network.placeholder, isNotNull);
    expect(network.fadeInDuration, ProgressiveMediaImage.fadeDuration);
  });

  testWidgets('вне iOS-режима фото отрисовывается по-старому', (tester) async {
    AppIosGlass.debugSetSupported(false);
    await _pump(tester, _photo);

    expect(find.byType(ProgressiveMediaImage), findsNothing);
    final network = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(network.placeholder, isNull);
    expect(network.fadeInDuration, Duration.zero);
  });

  testWidgets('в iOS-режиме видео сохраняет соотношение сторон', (
    tester,
  ) async {
    AppIosGlass.debugSetSupported(true);
    await _pump(tester, _video);

    final image = tester.widget<ProgressiveMediaImage>(
      find.byType(ProgressiveMediaImage),
    );
    expect(image.width / image.height, closeTo(1920 / 1080, 0.01));
  });

  testWidgets('вне iOS-режима размер видео не меняется', (tester) async {
    AppIosGlass.debugSetSupported(false);
    await _pump(tester, _video);

    final network = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(network.width, BubbleContext.photoMaxSize);
    expect(network.height, BubbleContext.photoMaxSize);
  });

  test('размер медиа вписывается в бабл без искажения', () {
    final size = BubbleContext.mediaDisplaySize(1920, 1080);
    expect(size.width, BubbleContext.photoMaxSize);
    expect(size.width / size.height, closeTo(1920 / 1080, 0.01));
  });

  test('в iOS-режиме превью кэшируется по содержимому', () {
    AppIosGlass.debugSetSupported(true);
    expect(
      dataUriImage(Object(), _pixel),
      same(dataUriImage(Object(), _pixel)),
    );
  });

  test('вне iOS-режима превью привязано к владельцу', () {
    AppIosGlass.debugSetSupported(false);
    final owner = Object();
    expect(dataUriImage(owner, _pixel), same(dataUriImage(owner, _pixel)));
    expect(
      dataUriImage(Object(), _pixel),
      isNot(same(dataUriImage(Object(), _pixel))),
    );
  });
}
