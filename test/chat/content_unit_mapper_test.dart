import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/modules/messages.dart';
import 'package:komet/core/chat/chat_content_unit.dart';
import 'package:komet/core/chat/content_unit_mapper.dart';
import 'package:komet/models/attachment.dart';

CachedMessage _message({
  String id = 'm',
  String? text,
  List<MessageAttachment>? attachments,
  Map<String, dynamic>? payload,
  bool control = false,
}) => CachedMessage(
  id: id,
  accountId: 1,
  chatId: 1,
  senderId: 2,
  time: 0,
  text: text,
  attachments: attachments,
  payload: payload,
  isControl: control,
);

void main() {
  const context = UnitMapContext(names: _name);

  test('альбом обрезается на десяти плитках', () {
    for (final count in [2, 3, 4, 7, 10, 11]) {
      final message = _message(
        attachments: [
          for (var i = 0; i < count; i++)
            PhotoAttachment(baseUrl: 'https://example.test/$i.jpg', width: 100, height: 80),
        ],
      );
      final album = unitsFor(message, context).whereType<AlbumUnit>().single;
      expect(album.tiles.length, count > 10 ? 10 : count);
      expect(album.extra, count > 10 ? count - 10 : 0);
    }
  });

  test('смешанный альбом, контакт без телефона, гео и превью ссылки', () {
    final mixed = unitsFor(
      _message(
        attachments: [
          PhotoAttachment(baseUrl: 'https://example.test/a.jpg'),
          VideoAttachment(thumbnail: 'https://example.test/b.jpg'),
        ],
      ),
      context,
    ).whereType<AlbumUnit>().single;
    expect(mixed.tiles.map((tile) => tile.tileKind), ['photo', 'video']);

    final contact = unitsFor(
      _message(
        attachments: [ContactAttachment(name: 'Аня', contactId: 4)],
      ),
      context,
    ).whereType<ContactUnit>().single;
    expect(contact.hasPhone, isFalse);
    expect(contact.name, 'Аня');

    final place = unitsFor(
      _message(
        attachments: [LocationAttachment(latitude: 1, longitude: 2)],
      ),
      context,
    ).whereType<LocationUnit>().single;
    expect(place.latitude, 1);

    final link = unitsFor(
      _message(
        attachments: [
          ShareAttachment(title: 'Заголовок', url: 'https://example.test'),
        ],
      ),
      context,
    ).whereType<LinkPreviewUnit>().single;
    expect(link.title, 'Заголовок');
  });

  test('стикер с подписью, голос и клавиатура по строкам', () {
    final sticker = unitsFor(
      _message(
        text: 'подпись',
        attachments: [StickerAttachment(baseUrl: 'https://example.test/s.png')],
      ),
      context,
    );
    expect(sticker.whereType<StickerUnit>(), isNotEmpty);
    expect(sticker.whereType<TextUnit>(), isEmpty);

    final voice = unitsFor(
      _message(
        attachments: [AudioAttachment(duration: 12000, audioId: 9, waveform: 'abc')],
      ),
      const UnitMapContext(names: _name, transcript: 'текст', transcriptOpen: true),
    ).whereType<VoiceUnit>().single;
    expect(voice.audioId, 9);
    expect(voice.duration, '0:12');

    final keys = unitsFor(
      _message(
        attachments: [
          InlineKeyboardAttachment(
            rows: [
              [InlineKeyboardButton(text: 'Один', type: 'callback')],
              [
                InlineKeyboardButton(text: 'Два', type: 'callback'),
                InlineKeyboardButton(text: 'Три', type: 'callback'),
              ],
              [InlineKeyboardButton(text: 'Четыре', type: 'callback')],
            ],
          ),
        ],
      ),
      context,
    ).whereType<BotKeyboardUnit>().single;
    expect(keys.rows.map((row) => row.length), [1, 2, 1]);
  });
}

String _name(int id) => 'Имя $id';
