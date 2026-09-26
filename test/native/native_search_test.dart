import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:komet/backend/modules/chats.dart';
import 'package:komet/core/native/native_search_session.dart';

void main() {
  test('секции идут каналы, чаты, группы, контакты, сообщения', () async {
    final session = NativeSearchSession(NativeSearchSources(
      accountId: () async => 1,
      contacts: (accountId, query) async => [
        {'id': 9, 'first_name': 'Анна', 'last_name': 'Ёлкина', 'phone': '1'},
      ],
      chats: (accountId, query) async => [
        {'id': 2, 'type': 'DIALOG', 'title': 'Личный'},
        {'id': 3, 'type': 'CHAT', 'title': 'Группа'},
        {'id': 4, 'type': 'CHANNEL', 'title': 'Свой канал'},
      ],
      publicChannels: (query, {required from, required count}) async => [
        const ChatSearchHit(id: 8, type: 'CHANNEL', title: 'Мир'),
        const ChatSearchHit(id: 4, type: 'CHANNEL', title: 'Свой канал'),
        const ChatSearchHit(id: 5, type: 'CHANNEL', title: 'Ещё'),
        const ChatSearchHit(id: 6, type: 'CHANNEL', title: 'Четвёртый'),
        const ChatSearchHit(id: 7, type: 'CHANNEL', title: 'Пятый'),
      ],
      serverMessages: (query) async => [
        const MessageSearchHit(chatId: 2, messageId: 'm', text: 'привет', time: 1, senderId: 1),
      ],
      localMessages: (accountId, query) async => [
        {'id': 'm', 'chat_id': 2, 'text': 'привет', 'time': 1},
        {'id': 'n', 'chat_id': 3, 'text': 'ещё', 'time': 2},
      ],
    ));
    addTearDown(session.dispose);

    session.setQuery('е');
    await Future<void>.delayed(const Duration(milliseconds: 340));

    expect(session.snapshot.hits.map((hit) => hit.id), [
      'header:Каналы',
      'channel:8',
      'channel:4',
      'channel:5',
      'channel:6',
      'channel:7',
      'more:channels',
      'header:Чаты',
      'chat:2',
      'header:Группы',
      'group:3',
      'header:Контакты',
      'contact:9',
      'header:Сообщения',
      'message:2:m',
      'message:3:n',
    ]);
  });

  test('устаревший запрос не затирает новый', () async {
    var release = Completer<void>();
    final session = NativeSearchSession(NativeSearchSources(
      accountId: () async => 1,
      contacts: (accountId, query) async => const [],
      chats: (accountId, query) async {
        if (query == 'старый') {
          await release.future;
          return [
            {'id': 1, 'type': 'DIALOG', 'title': 'Старый'},
          ];
        }
        return [
          {'id': 2, 'type': 'DIALOG', 'title': 'Новый'},
        ];
      },
      publicChannels: (query, {required from, required count}) async => const [],
      serverMessages: (query) async => const [],
      localMessages: (accountId, query) async => const [],
    ));
    addTearDown(session.dispose);

    session.setQuery('старый');
    await Future<void>.delayed(const Duration(milliseconds: 320));
    session.setQuery('новый');
    await Future<void>.delayed(const Duration(milliseconds: 340));
    release.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(session.snapshot.hits.map((hit) => hit.title), ['Чаты', 'Новый']);
  });
}
