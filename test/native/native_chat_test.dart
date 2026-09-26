import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/modules/messages.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/core/native/native_chat_bridge.dart';
import 'package:komet/core/native/native_chat_snapshot.dart';
import 'package:komet/models/attachment.dart';
import 'package:komet/models/poll.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 9, 26, 15);

CachedMessage _message({
  required String id,
  required int senderId,
  required DateTime time,
  String? text,
  String? status,
  List<MessageAttachment>? attachments,
  bool isControl = false,
  Map<String, dynamic>? payload,
}) => CachedMessage(
  id: id,
  accountId: 1,
  chatId: 7,
  senderId: senderId,
  time: time.millisecondsSinceEpoch,
  text: text,
  status: status,
  attachments: attachments,
  isControl: isControl,
  payload: payload,
);

NativeChatCallbacks _callbacks(List<Object> log) => NativeChatCallbacks(
  onOpen: (id) => log.add('open $id'),
  onLongPress: (id, rect) => log.add('long $id $rect'),
  onReply: (id) => log.add('reply $id'),
  onReaction: (id, emoji) => log.add('react $id $emoji'),
  onSelect: (id) => log.add('select $id'),
  onReplyJump: (id) => log.add('jump $id'),
  onMedia: (id, index) => log.add('media $id $index'),
  onLink: (url) => log.add('link $url'),
  onMention: (id) => log.add('mention $id'),
  onPoll: (id, answers) => log.add('poll $id $answers'),
  onKeyboard: (id, index) => log.add('key $id $index'),
  onTranscribe: (id) => log.add('transcribe $id'),
  onVoice: (id) => log.add('voice $id'),
  onVoiceSeek: (id, fraction) => log.add('seek $id $fraction'),
  onComments: (id) => log.add('comments $id'),
  onSticker: (id) => log.add('sticker $id'),
  onAvatar: (id) => log.add('avatar $id'),
  onLoadOlder: () => log.add('older'),
  onLoadNewer: () => log.add('newer'),
  onNearBottom: (on) => log.add('bottom $on'),
  onVisible: (ids) => log.add('visible $ids'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    NativeChatBridge.debugReset();
  });

  tearDown(() {
    AppIosGlass.debugReset();
    NativeChatBridge.debugReset();
  });

  group('снимок переписки', () {
    test('дата, непрочитанные и группировка соседних сообщений', () {
      final items = buildNativeChatItems(
        now: _now,
        myId: 10,
        unreadAnchorMillis: DateTime(2026, 9, 26, 11).millisecondsSinceEpoch,
        showSenders: true,
        nameOf: (id) => id == 4 ? 'Анна' : 'Я',
        messages: [
          _message(
            id: '1',
            senderId: 4,
            time: DateTime(2026, 9, 25, 9),
            text: 'вчера',
          ),
          _message(
            id: '2',
            senderId: 4,
            time: DateTime(2026, 9, 26, 12),
            text: 'первое',
          ),
          _message(
            id: '3',
            senderId: 4,
            time: DateTime(2026, 9, 26, 12, 5),
            text: 'второе',
          ),
        ],
      );

      String day(DateTime time) {
        final date = DateTime(time.year, time.month, time.day);
        return 'date:${date.millisecondsSinceEpoch}';
      }

      expect(items.map((item) => item.id), [
        day(DateTime(2026, 9, 25)),
        '1',
        day(DateTime(2026, 9, 26)),
        'unread',
        '2',
        '3',
      ]);
      expect(items[1].cluster, NativeChatCluster.single);
      expect(items[1].showAvatar, isTrue);
      expect(items[4].text, 'первое');
      expect(items[4].cluster, NativeChatCluster.top);
      expect(items[4].showSender, isTrue);
      expect(items[4].showAvatar, isFalse);
      expect(items[5].cluster, NativeChatCluster.bottom);
      expect(items[5].showAvatar, isTrue);
      expect(items[5].showSender, isFalse);
      expect(items[2].text, 'Сегодня');
      expect(items[0].text, 'Вчера');
    });

    test('фото без текста, цитата и пропуск тихого запуска бота', () {
      final items = buildNativeChatItems(
        now: _now,
        myId: 10,
        messages: [
          _message(
            id: 'silent',
            senderId: 2,
            time: DateTime(2026, 9, 26, 11),
            isControl: true,
            attachments: const [
              ControlAttachment(event: ControlAttachment.botStartedEvent),
            ],
          ),
          _message(
            id: 'photo',
            senderId: 10,
            time: DateTime(2026, 9, 26, 12),
            status: 'sent',
            attachments: const [PhotoAttachment(baseUrl: 'https://cdn/a.jpg')],
            payload: {
              'link': {
                'type': 'REPLY',
                'message': {'id': '9', 'sender': 4, 'text': 'цитата'},
              },
              'reactionInfo': {
                'counters': [
                  {'reaction': '👍', 'count': 2},
                ],
                'yourReaction': '👍',
                'totalCount': 2,
              },
            },
          ),
        ],
        nameOf: (id) => id == 4 ? 'Анна' : 'Я',
      );

      final today = DateTime(2026, 9, 26);
      expect(items.map((item) => item.id), [
        'date:${DateTime(today.year, today.month, today.day).millisecondsSinceEpoch}',
        'photo',
      ]);
      final photo = items.last;
      expect(photo.kind, NativeChatKind.photo);
      expect(photo.text, 'Фото');
      expect(photo.mediaUrl, 'https://cdn/a.jpg');
      expect(photo.replyText, 'цитата');
      expect(photo.replyAuthor, 'Анна');
      expect(photo.delivery, NativeChatDelivery.sent);
      expect(photo.reactions.single.mine, isTrue);
      expect(photo.toMap()['kind'], 'photo');
    });

    test('голосовое показывает длительность в секундах', () {
      final items = buildNativeChatItems(
        now: _now,
        myId: 1,
        playingId: 'v',
        progressId: 'v',
        voiceProgress: 0.4,
        messages: [
          _message(
            id: 'v',
            senderId: 2,
            time: DateTime(2026, 9, 26, 13),
            attachments: [
              AudioAttachment(
                duration: 5000,
                audioId: 9,
                waveform: String.fromCharCodes(const [1, 4, 9]),
              ),
            ],
          ),
        ],
      );
      final voice = items.last;
      expect(voice.kind, NativeChatKind.voice);
      expect(voice.duration, '0:05');
      expect(voice.audioId, 9);
      expect(voice.playing, isTrue);
      expect(voice.wave, [1, 4, 9]);
      expect(voice.progress, 0.4);
    });

    test('длинная волна сжимается до 48 столбиков', () {
      final items = buildNativeChatItems(
        now: _now,
        myId: 1,
        messages: [
          _message(
            id: 'long',
            senderId: 2,
            time: DateTime(2026, 9, 26, 13, 1),
            attachments: [
              AudioAttachment(duration: 1000, waveform: String.fromCharCodes(List.filled(96, 3))),
            ],
          ),
        ],
      );
      expect(items.last.wave, hasLength(48));
      expect(items.last.wave.every((bar) => bar == 3), isTrue);
    });

    test('кружок получает локальный файл для проигрывания', () {
      final items = buildNativeChatItems(
        now: _now,
        myId: 1,
        messages: [
          _message(
            id: 'note',
            senderId: 2,
            time: _now,
            attachments: [
              const VideoAttachment(
                videoType: 1,
                videoId: 4,
                thumbnail: 'https://cdn.example/thumb.jpg',
              ),
            ],
          ),
        ],
        notePathOf: (message) => '/tmp/${message.id}.mp4',
      );
      final note = items.last;
      expect(note.kind, NativeChatKind.videoNote);
      expect(note.playUrl, '/tmp/note.mp4');
      expect(note.toMap()['playUrl'], '/tmp/note.mp4');
      expect(note.mediaUrl, 'https://cdn.example/thumb.jpg');
    });

    test('жирный отрезок, альбом и результаты опроса', () {
      final items = buildNativeChatItems(
        now: _now,
        myId: 1,
        pollOf: (id) => id == 3
            ? const Poll(
                pollId: 3,
                title: 'Вопрос',
                total: 2,
                answers: [
                  PollAnswer(answerId: 1, text: 'Да', voteCount: 2, mine: true),
                ],
              )
            : null,
        messages: [
          _message(
            id: 'fmt',
            senderId: 2,
            time: DateTime(2026, 9, 26, 14),
            text: 'привет мир',
            payload: {
              'elements': [
                {'type': 'STRONG', 'from': 0, 'length': 6},
              ],
            },
          ),
          _message(
            id: 'album',
            senderId: 2,
            time: DateTime(2026, 9, 26, 14, 1),
            attachments: const [
              PhotoAttachment(baseUrl: 'https://cdn/a.jpg'),
              PhotoAttachment(baseUrl: 'https://cdn/b.jpg'),
            ],
          ),
          _message(
            id: 'poll',
            senderId: 2,
            time: DateTime(2026, 9, 26, 14, 2),
            attachments: const [PollAttachment(pollId: 3, title: 'Вопрос')],
          ),
        ],
      );
      final formatted = items.firstWhere((item) => item.id == 'fmt');
      expect(formatted.spans.single.styles, ['strong']);
      expect(formatted.spans.single.length, 6);
      final album = items.firstWhere((item) => item.id == 'album');
      expect(album.kind, NativeChatKind.album);
      expect(album.media.map((tile) => tile.url), [
        'https://cdn/a.jpg',
        'https://cdn/b.jpg',
      ]);
      final poll = items.firstWhere((item) => item.id == 'poll');
      expect(poll.kind, NativeChatKind.poll);
      expect(poll.pollVoted, isTrue);
      expect(poll.pollChoices.single.text, 'Да');
    });

    test('служебная строка собирается из события', () {
      final items = buildNativeChatItems(
        now: _now,
        myId: 1,
        nameOf: (id) => 'Ира',
        messages: [
          _message(
            id: 'c',
            senderId: 3,
            time: DateTime(2026, 9, 26, 8),
            isControl: true,
            attachments: const [ControlAttachment(event: 'pin')],
          ),
        ],
      );
      expect(items.last.text, 'Ира закрепил(а) сообщение');
      expect(items.last.kind, NativeChatKind.control);
    });
  });

  group('разница строк', () {
    const older = NativeChatItem(
      id: '1',
      role: NativeChatRole.message,
      text: 'а',
    );
    const newer = NativeChatItem(
      id: '2',
      role: NativeChatRole.message,
      text: 'б',
    );

    test('без изменений ничего не уходит', () {
      final update = NativeChatUpdate.between(const [older, newer], const [
        older,
        newer,
      ]);
      expect(update.isEmpty, isTrue);
    });

    test('новая строка приходит вместе с порядком', () {
      final update = NativeChatUpdate.between(const [older], const [
        older,
        newer,
      ]);
      expect(update.order, ['1', '2']);
      expect(update.items, [newer]);
    });
  });

  group('контроллер канала', () {
    const channelName = '${NativeChatBridge.viewType}/4';

    test('отправляет только разницу', () async {
      const alpha = NativeChatItem(
        id: 'a',
        role: NativeChatRole.message,
        text: 'а',
      );
      const beta = NativeChatItem(
        id: 'b',
        role: NativeChatRole.message,
        text: 'б',
      );
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(const MethodChannel(channelName), (
        call,
      ) async {
        calls.add(call);
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          const MethodChannel(channelName),
          null,
        ),
      );
      final controller = NativeChatController(4, _callbacks([]))..seed([alpha]);
      addTearDown(controller.dispose);

      await controller.update([alpha]);
      expect(calls, isEmpty);

      await controller.update([beta, alpha]);
      expect(calls.single.method, 'apply');
      final args = calls.single.arguments as Map;
      expect(args['order'], ['b', 'a']);
      expect((args['items'] as List).single, beta.toMap());
    });

    test('события из Swift доходят до обработчиков', () async {
      final log = <Object>[];
      final controller = NativeChatController(4, _callbacks(log));
      addTearDown(controller.dispose);
      const codec = StandardMethodCodec();

      Future<void> send(String method, [Map<String, Object?>? args]) =>
          messenger.handlePlatformMessage(
            channelName,
            codec.encodeMethodCall(MethodCall(method, args)),
            (_) {},
          );

      await send('open', {'id': 'm'});
      await send('reaction', {'id': 'm', 'emoji': '👍'});
      await send('keyboard', {'id': 'm', 'index': 1});
      await send('nearBottom', {'on': false});
      await send('visible', {
        'ids': ['m', 'n'],
      });
      await send('loadOlder');
      expect(log, [
        'open m',
        'react m 👍',
        'key m 1',
        'bottom false',
        'visible [m, n]',
        'older',
      ]);
    });
  });

  test('нативный чат включён вместе со стеклом', () {
    NativeChatBridge.debugAvailable = true;
    expect(NativeChatBridge.isEligible, isFalse);
    AppIosGlass.debugSetSupported(true);
    expect(NativeChatBridge.isEligible, isTrue);
  });
}
