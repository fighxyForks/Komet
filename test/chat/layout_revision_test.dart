import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/chat/chat_content_unit.dart';
import 'package:komet/core/chat/layout_revision.dart';

String _rev({
  String id = 'm',
  String text = 'привет',
  List<ChatContentUnit> units = const [TextUnit('привет')],
  String role = 'single',
  bool sender = false,
  bool avatar = false,
  String reply = '',
  String forward = '',
  String keyboard = '0',
  String poll = '',
  String transcript = '',
  bool open = false,
  String comments = '',
  String meta = '12:00',
}) => layoutRevisionFor(
  messageId: id,
  text: text,
  units: units,
  clusterRole: role,
  showSender: sender,
  showAvatar: avatar,
  reply: reply,
  forward: forward,
  keyboard: keyboard,
  poll: poll,
  transcript: transcript,
  transcriptOpen: open,
  comments: comments,
  meta: meta,
);

void main() {
  test('один и тот же текст даёт один ключ', () {
    expect(_rev(), _rev());
    expect(_rev().length, 16);
  });

  test('учитываемые поля меняют ключ', () {
    final base = _rev();
    expect(_rev(text: 'другое'), isNot(base));
    expect(_rev(units: const [PhotoUnit(url: 'https://example.test/a.jpg')]), isNot(base));
    expect(_rev(units: const [ReactionsUnit([ReactionChip(emoji: '👍', count: 1)])]), isNot(base));
    expect(_rev(role: 'top'), isNot(base));
    expect(_rev(sender: true), isNot(base));
    expect(_rev(avatar: true), isNot(base));
    expect(_rev(reply: 'автор|текст'), isNot(base));
    expect(_rev(forward: 'автор'), isNot(base));
    expect(_rev(keyboard: '2'), isNot(base));
    expect(_rev(poll: '1:true:2'), isNot(base));
    expect(_rev(transcript: 'текст', open: true), isNot(base));
    expect(_rev(comments: '3'), isNot(base));
    expect(_rev(meta: '12:01 ред.'), isNot(base));
  });

  test('выделение и прогресс не входят в ключ', () {
    expect(_rev(), _rev());
  });

  test('замена временного id меняет ключ', () {
    expect(_rev(id: 'temp_1'), isNot(_rev(id: 'server')));
  });
}
