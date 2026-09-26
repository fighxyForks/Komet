import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../backend/modules/chats.dart';

enum NativeSearchKind { header, channel, chat, group, contact, message, more }

@immutable
class NativeSearchHit {
  final String id;
  final NativeSearchKind kind;
  final String title;
  final String subtitle;
  final String avatarUrl;
  final int? targetId;
  final String? messageId;
  final int? messageTime;
  final String type;

  const NativeSearchHit({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle = '',
    this.avatarUrl = '',
    this.targetId,
    this.messageId,
    this.messageTime,
    this.type = '',
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'subtitle': subtitle,
    'avatarUrl': avatarUrl,
    'targetId': targetId,
    'messageId': messageId,
    'messageTime': messageTime,
    'type': type,
  };

  @override
  bool operator ==(Object other) =>
      other is NativeSearchHit &&
          other.id == id &&
          other.title == title &&
          other.subtitle == subtitle &&
          other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(id, title, subtitle, avatarUrl);
}

@immutable
class NativeSearchSnapshot {
  final String query;
  final bool loading;
  final List<NativeSearchHit> hits;

  const NativeSearchSnapshot({
    this.query = '',
    this.loading = false,
    this.hits = const [],
  });
}

class NativeSearchSources {
  final Future<int?> Function() accountId;
  final Future<List<Map<String, dynamic>>> Function(int accountId, String query)
      contacts;
  final Future<List<Map<String, dynamic>>> Function(int accountId, String query)
      chats;
  final Future<List<ChatSearchHit>> Function(String query, {required int from, required int count})
      publicChannels;
  final Future<List<MessageSearchHit>> Function(String query) serverMessages;
  final Future<List<Map<String, dynamic>>> Function(int accountId, String query)
      localMessages;
  final Future<List<Map<String, dynamic>>> Function(int accountId, List<int> ids)?
      chatsByIds;

  const NativeSearchSources({
    required this.accountId,
    required this.contacts,
    required this.chats,
    required this.publicChannels,
    required this.serverMessages,
    required this.localMessages,
    this.chatsByIds,
  });
}

List<NativeSearchHit> nativeSearchNamedMessages(
  List<NativeSearchHit> messages,
  Map<int, Map<String, dynamic>> chats,
) {
  if (chats.isEmpty) return messages;
  return [
    for (final hit in messages)
      if (hit.kind == NativeSearchKind.message &&
          hit.targetId != null &&
          chats[hit.targetId] != null)
        NativeSearchHit(
          id: hit.id,
          kind: hit.kind,
          title: hit.title,
          subtitle: (chats[hit.targetId]!['title'] as String?)?.trim() ?? '',
          avatarUrl: (chats[hit.targetId]!['icon_url'] as String?) ?? '',
          targetId: hit.targetId,
          messageId: hit.messageId,
          messageTime: hit.messageTime,
          type: (chats[hit.targetId]!['type'] as String?) ?? hit.type,
        )
      else
        hit,
  ];
}

class NativeSearchSession extends ChangeNotifier {
  NativeSearchSession(this.sources);

  final NativeSearchSources sources;
  NativeSearchSnapshot snapshot = const NativeSearchSnapshot();

  Timer? _timer;
  int _token = 0;
  String _query = '';
  List<ChatSearchHit> _channels = const [];
  bool _channelsMore = false;

  void setQuery(String raw) {
    _timer?.cancel();
    _token++;
    _query = raw.trim();
    _channels = const [];
    _channelsMore = false;
    if (_query.isEmpty) {
      snapshot = const NativeSearchSnapshot();
      notifyListeners();
      return;
    }
    snapshot = NativeSearchSnapshot(query: _query, loading: true);
    notifyListeners();
    _timer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_search(_token, resetChannels: true));
    });
  }

  void moreChannels() {
    if (_query.isEmpty || !_channelsMore) return;
    unawaited(_search(_token, resetChannels: false));
  }

  Future<void> _search(int token, {required bool resetChannels}) async {
    final query = _query;
    final account = await sources.accountId();
    if (token != _token || query != _query) return;
    final from = resetChannels ? 0 : _channels.length;
    final count = resetChannels ? 5 : 10;
    final results = await Future.wait([
      account == null
          ? Future.value(const <Map<String, dynamic>>[])
          : sources.contacts(account, query),
      account == null
          ? Future.value(const <Map<String, dynamic>>[])
          : sources.chats(account, query),
      sources.publicChannels(query, from: from, count: count),
      sources.serverMessages(query),
      account == null
          ? Future.value(const <Map<String, dynamic>>[])
          : sources.localMessages(account, query),
    ]);
    if (token != _token || query != _query) return;

    final contacts = results[0] as List<Map<String, dynamic>>;
    final local = results[1] as List<Map<String, dynamic>>;
    final page = results[2] as List<ChatSearchHit>;
    final serverMessages = results[3] as List<MessageSearchHit>;
    final localMessages = results[4] as List<Map<String, dynamic>>;

    final channels = resetChannels
        ? _uniqueChannels(page.where((hit) => hit.type == 'CHANNEL'))
        : _uniqueChannels([..._channels, ...page.where((hit) => hit.type == 'CHANNEL')]);
    _channels = channels;
    _channelsMore = page.where((hit) => hit.type == 'CHANNEL').length >= count;

    final chats = <Map<String, dynamic>>[];
    final groups = <Map<String, dynamic>>[];
    final extraChannels = <ChatSearchHit>[];
    for (final row in local) {
      final id = row['id'];
      if (id is! int) continue;
      final type = (row['type'] as String?) ?? 'CHAT';
      if (type == 'DIALOG') {
        chats.add(row);
      } else if (type == 'CHANNEL') {
        if (!channels.any((hit) => hit.id == id)) {
          extraChannels.add(ChatSearchHit(
            id: id,
            type: 'CHANNEL',
            title: row['title'] as String?,
            avatarUrl: row['icon_url'] as String?,
          ));
        }
      } else if (!channels.any((hit) => hit.id == id)) {
        groups.add(row);
      }
    }
    if (extraChannels.isNotEmpty) {
      _channels = _uniqueChannels([...channels, ...extraChannels]);
    }

    var messages = _mergeMessages(serverMessages, localMessages);
    final lookup = sources.chatsByIds;
    if (account != null && lookup != null && messages.isNotEmpty) {
      final ids = [
        for (final hit in messages)
          if (hit.targetId != null) hit.targetId!,
      ];
      final rows = await lookup(account, ids.toSet().toList());
      if (token != _token) return;
      messages = nativeSearchNamedMessages(messages, {
        for (final row in rows)
          if (row['id'] is int) row['id'] as int: row,
      });
    }
    if (token != _token) return;
    snapshot = NativeSearchSnapshot(
      query: query,
      hits: [
        ..._section('Каналы', channels.map(_channelHit)),
        if (_channelsMore)
          const NativeSearchHit(id: 'more:channels', kind: NativeSearchKind.more, title: 'Больше'),
        ..._section('Чаты', chats.map(_chatHit)),
        ..._section('Группы', groups.map(_groupHit)),
        ..._section('Контакты', contacts.map(_contactHit)),
        ..._section('Сообщения', messages),
      ],
    );
    notifyListeners();
  }

  List<ChatSearchHit> _uniqueChannels(Iterable<ChatSearchHit> hits) {
    final seen = <int>{};
    return [
      for (final hit in hits)
        if (seen.add(hit.id)) hit,
    ];
  }

  List<NativeSearchHit> _section(String title, Iterable<NativeSearchHit> hits) {
    final rows = hits.toList();
    if (rows.isEmpty) return const [];
    return [
      NativeSearchHit(id: 'header:$title', kind: NativeSearchKind.header, title: title),
      ...rows,
    ];
  }

  NativeSearchHit _channelHit(ChatSearchHit hit) => NativeSearchHit(
    id: 'channel:${hit.id}',
    kind: NativeSearchKind.channel,
    title: hit.title ?? '',
    subtitle: hit.subtitle ?? '',
    avatarUrl: hit.avatarUrl ?? '',
    targetId: hit.id,
    type: hit.type,
  );

  NativeSearchHit _chatHit(Map<String, dynamic> row) => NativeSearchHit(
    id: 'chat:${row['id']}',
    kind: NativeSearchKind.chat,
    title: (row['title'] as String?) ?? '',
    avatarUrl: (row['icon_url'] as String?) ?? '',
    targetId: row['id'] as int?,
    type: 'DIALOG',
  );

  NativeSearchHit _groupHit(Map<String, dynamic> row) => NativeSearchHit(
    id: 'group:${row['id']}',
    kind: NativeSearchKind.group,
    title: (row['title'] as String?) ?? '',
    avatarUrl: (row['icon_url'] as String?) ?? '',
    targetId: row['id'] as int?,
    type: (row['type'] as String?) ?? 'CHAT',
  );

  NativeSearchHit _contactHit(Map<String, dynamic> row) {
    final first = (row['first_name'] as String?)?.trim() ?? '';
    final last = (row['last_name'] as String?)?.trim() ?? '';
    final title = '$first $last'.trim();
    return NativeSearchHit(
      id: 'contact:${row['id']}',
      kind: NativeSearchKind.contact,
      title: title.isEmpty ? 'Контакт' : title,
      subtitle: row['phone']?.toString() ?? '',
      avatarUrl: (row['base_url'] as String?) ?? '',
      targetId: row['id'] as int?,
    );
  }

  List<NativeSearchHit> _mergeMessages(
    List<MessageSearchHit> server,
    List<Map<String, dynamic>> local,
  ) {
    final seen = <String>{};
    final hits = <NativeSearchHit>[];
    void add(String key, NativeSearchHit hit) {
      if (seen.add(key)) hits.add(hit);
    }
    for (final hit in server) {
      final messageId = hit.messageId ?? '';
      add('$messageId:${hit.chatId}', NativeSearchHit(
        id: 'message:${hit.chatId}:$messageId',
        kind: NativeSearchKind.message,
        title: hit.text?.trim().isNotEmpty == true ? hit.text!.trim() : 'Сообщение',
        targetId: hit.chatId,
        messageId: messageId,
        messageTime: hit.time,
        type: 'CHAT',
      ));
    }
    for (final row in local) {
      final messageId = row['id']?.toString() ?? '';
      final chatId = row['chat_id'] as int? ?? 0;
      add('$messageId:$chatId', NativeSearchHit(
        id: 'message:$chatId:$messageId',
        kind: NativeSearchKind.message,
        title: (row['text'] as String?)?.trim().isNotEmpty == true
            ? (row['text'] as String).trim()
            : 'Сообщение',
        targetId: chatId,
        messageId: messageId,
        messageTime: row['time'] as int?,
        type: 'CHAT',
      ));
    }
    return hits;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _token++;
    super.dispose();
  }
}
