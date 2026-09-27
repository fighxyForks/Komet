import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/chat/chat_interactions.dart';

void main() {
  test('нативные события попадают в те же замыкания', () {
    final log = <String>[];
    final interactions = ChatInteractions(
      open: (id) => log.add('open $id'),
      longPress: (id, _) => log.add('long $id'),
      reply: (id) => log.add('reply $id'),
      swipeToReply: (id) => log.add('swipe $id'),
      edit: (id) => log.add('edit $id'),
      delete: (id) => log.add('delete $id'),
      forward: (ids) => log.add('forward $ids'),
      pin: (id) => log.add('pin $id'),
      copy: (ids) => log.add('copy $ids'),
      copyLink: (id) => log.add('linkcopy $id'),
      markUnread: (id) => log.add('unread $id'),
      report: (id, reason) {
        log.add('report $id $reason');
        return Future<bool>.value(true);
      },
      react: (id, emoji) => log.add('react $id $emoji'),
      select: (id) => log.add('select $id'),
      replyJump: (id, {String? fromId, int time = 0}) =>
          log.add('jump $id $fromId $time'),
      openMedia: (id, index) => log.add('media $id $index'),
      link: (url) => log.add('url $url'),
      mention: (id) => log.add('mention $id'),
      pollVote: (id, answers) => log.add('poll $id $answers'),
      inlineButton: (id, index) => log.add('key $id $index'),
      transcribe: (id) => log.add('transcribe $id'),
      voiceToggle: (id) => log.add('voice $id'),
      voiceSeek: (id, fraction) => log.add('seek $id $fraction'),
      comments: (id) => log.add('comments $id'),
      openSticker: (id) => log.add('sticker $id'),
      openPeer: (id) => log.add('peer $id'),
      openForwardSource: (id) => log.add('forward-source $id'),
      openContact: (id) => log.add('contact $id'),
      openFile: (id) => log.add('file $id'),
      openLocation: (id) => log.add('location $id'),
      loadOlder: () => log.add('older'),
      loadNewer: () => log.add('newer'),
      nearBottom: (atBottom) => log.add('bottom $atBottom'),
      visibleIds: (ids) => log.add('visible $ids'),
    );
    final callbacks = interactions.toCallbacks();
    callbacks.onReply('a');
    callbacks.onContact('a', 4);
    callbacks.onFile('a');
    callbacks.onLocation('a');
    callbacks.onReplyJump('b');
    interactions.replyJump('b', fromId: 'a', time: 5);
    interactions.swipeToReply('a');
    expect(log, [
      'reply a',
      'contact a',
      'file a',
      'location a',
      'jump b null 0',
      'jump b a 5',
      'swipe a',
    ]);
  });

  test('возможности сообщения не зависят от того, кто рисует строку', () {
    const caps = MessageCapabilities(
      canReply: true,
      canEdit: false,
      canDelete: true,
      canForward: false,
    );
    expect(caps.canReply, isTrue);
    expect(caps.canEdit, isFalse);
    expect(
      messageCapabilities(
        control: false,
        outgoing: true,
        channel: false,
        admin: false,
        canReplyInChat: true,
        forwardDisabled: true,
        copyDisabled: false,
        canEdit: false,
        canPin: false,
        canLink: false,
        canShowReadBy: false,
      ).canForward,
      isFalse,
    );
    expect(
      messageCapabilities(
        control: true,
        outgoing: false,
        channel: true,
        admin: true,
        canReplyInChat: true,
        forwardDisabled: false,
        copyDisabled: false,
        canEdit: true,
        canPin: true,
        canLink: true,
        canShowReadBy: true,
      ).canDelete,
      isFalse,
    );
  });

  test('пакет действий один и тот же объект между пересборками', () {
    var builds = 0;
    ChatInteractions? first;
    ChatInteractions make() {
      builds++;
      return ChatInteractions(
        open: (_) {},
        longPress: (_, _) {},
        reply: (_) {},
        swipeToReply: (_) {},
        edit: (_) {},
        delete: (_) {},
        forward: (_) {},
        pin: (_) {},
        copy: (_) {},
        copyLink: (_) {},
        markUnread: (_) {},
        report: (_, _) => Future<bool>.value(false),
        react: (_, _) {},
        select: (_) {},
        replyJump: (_, {fromId, time = 0}) {},
        openMedia: (_, _) {},
        link: (_) {},
        mention: (_) {},
        pollVote: (_, _) {},
        inlineButton: (_, _) {},
        transcribe: (_) {},
        voiceToggle: (_) {},
        voiceSeek: (_, _) {},
        comments: (_) {},
        openSticker: (_) {},
        openPeer: (_) {},
        openForwardSource: (_) {},
        openContact: (_) {},
        openFile: (_) {},
        openLocation: (_) {},
        loadOlder: () {},
        loadNewer: () {},
        nearBottom: (_) {},
        visibleIds: (_) {},
      );
    }

    final held = make();
    first = held;
    expect(identical(first, held), isTrue);
    expect(builds, 1);
  });
}
