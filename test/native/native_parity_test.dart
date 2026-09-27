import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/modules/messages.dart';
import 'package:komet/core/chat/native_parity.dart';
import 'package:komet/core/crypto/message_decryption_cache.dart';
import 'package:komet/models/attachment.dart';

CachedMessage _message({
  required String id,
  String? text,
  List<MessageAttachment>? attachments,
}) => CachedMessage(
  id: id,
  accountId: 1,
  chatId: 7,
  senderId: 2,
  time: 0,
  text: text,
  attachments: attachments,
);

void main() {
  tearDown(MessageDecryptionCache.instance.clear);

  test('открытый текст остаётся как есть', () {
    final visible = nativeVisibleText(
      accountId: 1,
      chatId: 7,
      messageId: 'm',
      stored: 'Обычное сообщение',
    );
    expect(visible.text, 'Обычное сообщение');
    expect(visible.hideFormats, isFalse);
  });

  test('готовая расшифровка заменяет сохранённый текст', () {
    MessageDecryptionCache.instance.seed('m', 'Секрет');
    final visible = nativeVisibleText(
      accountId: 1,
      chatId: 7,
      messageId: 'm',
      stored: 'cipher-blob',
    );
    expect(visible.text, 'Секрет');
    expect(visible.hideFormats, isTrue);
  });

  test('видео в альбоме берётся по индексу плитки, а не последнее', () {
    final first = VideoAttachment(videoId: 1, videoToken: 'a');
    final photo = PhotoAttachment();
    final second = VideoAttachment(videoId: 2, videoToken: 'b');
    final message = _message(
      id: 'album',
      attachments: [first, photo, second],
    );
    expect(nativeSelectedVideo(message, 0)?.videoId, 1);
    expect(nativeSelectedVideo(message, 2)?.videoId, 2);
    expect(nativeSelectedVideo(message, 1)?.videoId, 1);
  });

  test('пересланный опрос голосует в исходном чате', () {
    final message = _message(
      id: 'local',
      attachments: [
        ForwardedMessageAttachment(
          originalSenderId: 9,
          originalMessageId: 'source',
          originalChatId: 44,
          originalAttachments: [PollAttachment(pollId: 5, title: 'Вопрос')],
        ),
      ],
    );
    final target = nativePollTarget(message);
    expect(target.chatId, 44);
    expect(target.messageId, 'source');
  });

  test('свой опрос остаётся в текущем сообщении', () {
    final message = _message(
      id: 'local',
      attachments: [PollAttachment(pollId: 5)],
    );
    final target = nativePollTarget(message);
    expect(target.chatId, 7);
    expect(target.messageId, 'local');
  });
}
