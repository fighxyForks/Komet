import '../native/native_chat_bridge.dart';
import 'package:flutter/widgets.dart';

/// One set of id-based actions shared by the Flutter rows and the native list.
class ChatInteractions {
  final void Function(String id) open;
  final void Function(String id, Rect origin) longPress;
  final void Function(String id) reply;
  final void Function(String id) swipeToReply;
  final void Function(String id) edit;
  final void Function(String id) delete;
  final void Function(List<String> ids) forward;
  final void Function(String id) pin;
  final void Function(List<String> ids) copy;
  final void Function(String id) copyLink;
  final void Function(String id) markUnread;
  final Future<bool> Function(String id, int reason) report;
  final void Function(String id, String emoji) react;
  final void Function(String id) select;
  final void Function(String id, {String? fromId, int time}) replyJump;
  final void Function(String id, int index) openMedia;
  final void Function(String url) link;
  final void Function(int userId) mention;
  final void Function(String id, List<int> answers) pollVote;
  final void Function(String id, int index) inlineButton;
  final void Function(String id) transcribe;
  final void Function(String id) voiceToggle;
  final void Function(String id, double fraction) voiceSeek;
  final void Function(String id) comments;
  final void Function(String id) openSticker;
  final void Function(int userId) openPeer;
  final void Function(String id) openForwardSource;
  final void Function(String id) openContact;
  final void Function(String id) openFile;
  final void Function(String id) openLocation;
  final void Function() loadOlder;
  final void Function() loadNewer;
  final void Function(bool atBottom) nearBottom;
  final void Function(List<String> ids) visibleIds;

  const ChatInteractions({
    required this.open,
    required this.longPress,
    required this.reply,
    required this.swipeToReply,
    required this.edit,
    required this.delete,
    required this.forward,
    required this.pin,
    required this.copy,
    required this.copyLink,
    required this.markUnread,
    required this.report,
    required this.react,
    required this.select,
    required this.replyJump,
    required this.openMedia,
    required this.link,
    required this.mention,
    required this.pollVote,
    required this.inlineButton,
    required this.transcribe,
    required this.voiceToggle,
    required this.voiceSeek,
    required this.comments,
    required this.openSticker,
    required this.openPeer,
    required this.openForwardSource,
    required this.openContact,
    required this.openFile,
    required this.openLocation,
    required this.loadOlder,
    required this.loadNewer,
    required this.nearBottom,
    required this.visibleIds,
  });

  NativeChatCallbacks toCallbacks() => NativeChatCallbacks(
    onOpen: open,
    onLongPress: longPress,
    onReply: reply,
    onReaction: react,
    onSelect: select,
    onReplyJump: (id) => replyJump(id),
    onMedia: openMedia,
    onLink: link,
    onMention: mention,
    onPoll: pollVote,
    onKeyboard: inlineButton,
    onTranscribe: transcribe,
    onVoice: voiceToggle,
    onVoiceSeek: voiceSeek,
    onComments: comments,
    onSticker: openSticker,
    onAvatar: openPeer,
    onContact: (id, _) => openContact(id),
    onFile: openFile,
    onLocation: openLocation,
    onLoadOlder: loadOlder,
    onLoadNewer: loadNewer,
    onNearBottom: nearBottom,
    onVisible: visibleIds,
  );
}

class MessageCapabilities {
  final bool canReply;
  final bool canEdit;
  final bool canDelete;
  final bool canForward;
  final bool canPin;
  final bool canCopy;
  final bool canCopyLink;
  final bool canReport;
  final bool canShowReadBy;

  const MessageCapabilities({
    this.canReply = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canForward = false,
    this.canPin = false,
    this.canCopy = false,
    this.canCopyLink = false,
    this.canReport = false,
    this.canShowReadBy = false,
  });
}

/// Capability flags shared by the Flutter row menu and the native menu.
MessageCapabilities messageCapabilities({
  required bool control,
  required bool outgoing,
  required bool channel,
  required bool admin,
  required bool canReplyInChat,
  required bool forwardDisabled,
  required bool copyDisabled,
  required bool canEdit,
  required bool canPin,
  required bool canLink,
  required bool canShowReadBy,
}) {
  final alive = !control;
  final canModerate = outgoing || !channel || admin;
  return MessageCapabilities(
    canReply: alive && canReplyInChat,
    canEdit: canEdit,
    canDelete: alive && canModerate,
    canForward: alive && !forwardDisabled,
    canPin: canPin,
    canCopy: !copyDisabled,
    canCopyLink: canLink,
    canReport: alive && !outgoing,
    canShowReadBy: canShowReadBy,
  );
}
