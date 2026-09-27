import '../../backend/modules/messages.dart';
import '../../core/native/native_chat_bridge.dart';
import '../../core/native/native_chat_snapshot.dart';
import '../../models/poll.dart';

/// Assembles the native transcript from the history store. The screen only
/// supplies the already-loaded window and the chrome callbacks.
List<NativeChatItem> presentNativeTranscript({
  required List<CachedMessage> messages,
  required int myId,
  required DateTime now,
  int? unreadAnchorMillis,
  Set<String> selected = const {},
  String? highlightId,
  bool showSenders = false,
  bool wide = false,
  bool canReply = true,
  bool withSeconds = false,
  int? otherReadMillis,
  String? playingId,
  String? progressId,
  double voiceProgress = 0,
  Poll? Function(int pollId)? pollOf,
  NativeChatName? nameOf,
  String? Function(int senderId)? avatarOf,
  String? Function(CachedMessage message)? statusOf,
  Map<dynamic, dynamic>? Function(CachedMessage message)? reactionOf,
  NativeChatTranscript Function(String messageId)? transcriptOf,
  String? Function(CachedMessage message)? commentsOf,
  String? Function(CachedMessage message)? notePathOf,
}) {
  return buildNativeChatItems(
    messages: messages,
    myId: myId,
    now: now,
    unreadAnchorMillis: unreadAnchorMillis,
    selected: selected,
    highlightId: highlightId,
    showSenders: showSenders,
    wide: wide,
    canReply: canReply,
    withSeconds: withSeconds,
    otherReadMillis: otherReadMillis,
    playingId: playingId,
    progressId: progressId,
    voiceProgress: voiceProgress,
    pollOf: pollOf,
    nameOf: nameOf,
    avatarOf: avatarOf,
    statusOf: statusOf,
    reactionOf: reactionOf,
    transcriptOf: transcriptOf,
    commentsOf: commentsOf,
    notePathOf: notePathOf,
  );
}
