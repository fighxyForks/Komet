import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/app_ios_glass.dart';

/// Display model for one row in the UIKit transcript.
///
/// Dart owns history, networking and actions. Swift renders these rows in one
/// `UICollectionView` and sends the events below back on
/// `ru.komet.app/native_chat/<viewId>`:
/// `open`, `longPress`, `reply`, `reaction`, `select`, `replyJump`, `media`,
/// `keyboard`, `transcribe`, `comments`, `sticker`, `avatar`, `loadOlder`,
/// `loadNewer`, `nearBottom`, `visible`.
enum NativeChatRole { date, unread, message }

enum NativeChatKind {
  text,
  photo,
  video,
  videoNote,
  voice,
  file,
  sticker,
  contact,
  location,
  poll,
  call,
  share,
  control,
  forward,
  album,
}

enum NativeChatCluster { single, top, middle, bottom }

enum NativeChatDelivery { none, sending, sent, read, error }

@immutable
class NativeChatReaction {
  final String emoji;
  final int count;
  final bool mine;

  const NativeChatReaction({
    required this.emoji,
    required this.count,
    this.mine = false,
  });

  Map<String, Object?> toMap() => {
    'emoji': emoji,
    'count': count,
    'mine': mine,
  };

  @override
  bool operator ==(Object other) =>
      other is NativeChatReaction &&
      other.emoji == emoji &&
      other.count == count &&
      other.mine == mine;

  @override
  int get hashCode => Object.hash(emoji, count, mine);
}

@immutable
class NativeChatButton {
  final String text;
  final String type;
  final String? url;
  final String? payload;
  final String? webApp;
  final String? callbackId;
  final int? contactId;

  const NativeChatButton({
    required this.text,
    this.type = '',
    this.url,
    this.payload,
    this.webApp,
    this.callbackId,
    this.contactId,
  });

  Map<String, Object?> toMap() => {
    'text': text,
    'type': type,
    'url': url,
    'payload': payload,
    'webApp': webApp,
    'callbackId': callbackId,
    'contactId': contactId,
  };

  @override
  bool operator ==(Object other) =>
      other is NativeChatButton && mapEquals(toMap(), other.toMap());

  @override
  int get hashCode => Object.hash(text, type, url, payload, callbackId, contactId);
}

@immutable
class NativeChatSpan {
  final int start;
  final int length;
  final List<String> styles;
  final String? url;
  final int? userId;

  const NativeChatSpan({
    required this.start,
    required this.length,
    this.styles = const [],
    this.url,
    this.userId,
  });

  Map<String, Object?> toMap() => {
    'start': start,
    'length': length,
    'styles': styles,
    'url': url,
    'userId': userId,
  };

  @override
  bool operator ==(Object other) =>
      other is NativeChatSpan &&
      other.start == start &&
      other.length == length &&
      listEquals(other.styles, styles) &&
      other.url == url &&
      other.userId == userId;

  @override
  int get hashCode => Object.hash(start, length, Object.hashAll(styles), url, userId);
}

@immutable
class NativeChatMedia {
  final String url;
  final String kind;

  const NativeChatMedia({required this.url, required this.kind});

  Map<String, Object?> toMap() => {'url': url, 'kind': kind};

  @override
  bool operator ==(Object other) =>
      other is NativeChatMedia && other.url == url && other.kind == kind;

  @override
  int get hashCode => Object.hash(url, kind);
}

@immutable
class NativeChatPollChoice {
  final int id;
  final String text;
  final int count;
  final bool mine;

  const NativeChatPollChoice({
    required this.id,
    required this.text,
    this.count = 0,
    this.mine = false,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'text': text,
    'count': count,
    'mine': mine,
  };

  @override
  bool operator ==(Object other) =>
      other is NativeChatPollChoice &&
      other.id == id &&
      other.text == text &&
      other.count == count &&
      other.mine == mine;

  @override
  int get hashCode => Object.hash(id, text, count, mine);
}

@immutable
class NativeChatItem {
  final String id;
  final NativeChatRole role;
  final String text;
  final NativeChatKind kind;
  final bool outgoing;
  final String time;
  final NativeChatDelivery delivery;
  final NativeChatCluster cluster;
  final bool edited;
  final bool deleted;
  final bool canReply;
  final bool selected;
  final bool highlighted;
  final bool showAvatar;
  final bool showSender;
  final bool transcriptOpen;
  final bool playing;
  final double progress;
  final String? senderName;
  final String? avatarUrl;
  final String? replyId;
  final String? replyAuthor;
  final String? replyText;
  final String? forwardAuthor;
  final String? mediaUrl;
  final String? playUrl;
  final String? fileName;
  final String? duration;
  final String? transcript;
  final String? comments;
  final int? audioId;
  final int? senderId;
  final int? pollId;
  final int? pollTotal;
  final bool pollMultiple;
  final bool pollVoted;
  final List<int> wave;
  final List<NativeChatSpan> spans;
  final List<NativeChatMedia> media;
  final List<NativeChatPollChoice> pollChoices;
  final List<NativeChatReaction> reactions;
  final List<NativeChatButton> buttons;

  const NativeChatItem({
    required this.id,
    required this.role,
    this.text = '',
    this.kind = NativeChatKind.text,
    this.outgoing = false,
    this.time = '',
    this.delivery = NativeChatDelivery.none,
    this.cluster = NativeChatCluster.single,
    this.edited = false,
    this.deleted = false,
    this.canReply = false,
    this.selected = false,
    this.highlighted = false,
    this.showAvatar = false,
    this.showSender = false,
    this.transcriptOpen = false,
    this.playing = false,
    this.progress = 0,
    this.senderName,
    this.avatarUrl,
    this.replyId,
    this.replyAuthor,
    this.replyText,
    this.forwardAuthor,
    this.mediaUrl,
    this.playUrl,
    this.fileName,
    this.duration,
    this.transcript,
    this.comments,
    this.audioId,
    this.senderId,
    this.pollId,
    this.pollTotal,
    this.pollMultiple = false,
    this.pollVoted = false,
    this.wave = const [],
    this.spans = const [],
    this.media = const [],
    this.pollChoices = const [],
    this.reactions = const [],
    this.buttons = const [],
  });

  const NativeChatItem.date(String dayId, String label)
    : this(id: dayId, role: NativeChatRole.date, text: label);

  const NativeChatItem.unread(String label)
    : this(id: 'unread', role: NativeChatRole.unread, text: label);

  NativeChatItem copyWith({
    NativeChatCluster? cluster,
    bool? showAvatar,
    bool? showSender,
    String? senderName,
    String? playUrl,
  }) => NativeChatItem(
    id: id,
    role: role,
    text: text,
    kind: kind,
    outgoing: outgoing,
    time: time,
    delivery: delivery,
    cluster: cluster ?? this.cluster,
    edited: edited,
    deleted: deleted,
    canReply: canReply,
    selected: selected,
    highlighted: highlighted,
    showAvatar: showAvatar ?? this.showAvatar,
    showSender: showSender ?? this.showSender,
    transcriptOpen: transcriptOpen,
    playing: playing,
    progress: progress,
    senderName: senderName ?? this.senderName,
    avatarUrl: avatarUrl,
    replyId: replyId,
    replyAuthor: replyAuthor,
    replyText: replyText,
    forwardAuthor: forwardAuthor,
    mediaUrl: mediaUrl,
    playUrl: playUrl ?? this.playUrl,
    fileName: fileName,
    duration: duration,
    transcript: transcript,
    comments: comments,
    audioId: audioId,
    senderId: senderId,
    pollId: pollId,
    pollTotal: pollTotal,
    pollMultiple: pollMultiple,
    pollVoted: pollVoted,
    wave: wave,
    spans: spans,
    media: media,
    pollChoices: pollChoices,
    reactions: reactions,
    buttons: buttons,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'role': role.name,
    'text': text,
    if (role == NativeChatRole.message) ...{
      'kind': kind.name,
      'outgoing': outgoing,
      'time': time,
      'delivery': delivery.name,
      'cluster': cluster.name,
      'edited': edited,
      'deleted': deleted,
      'canReply': canReply,
      'selected': selected,
      'highlighted': highlighted,
      'showAvatar': showAvatar,
      'showSender': showSender,
      'transcriptOpen': transcriptOpen,
      'playing': playing,
      'progress': progress,
      'senderName': senderName,
      'avatarUrl': avatarUrl,
      'replyId': replyId,
      'replyAuthor': replyAuthor,
      'replyText': replyText,
      'forwardAuthor': forwardAuthor,
      'mediaUrl': mediaUrl,
      if (playUrl != null) 'playUrl': playUrl,
      'fileName': fileName,
      'duration': duration,
      'transcript': transcript,
      'comments': comments,
      'audioId': audioId,
      'senderId': senderId,
      'pollId': pollId,
      'pollTotal': pollTotal,
      'pollMultiple': pollMultiple,
      'pollVoted': pollVoted,
      'wave': wave,
      'spans': [for (final span in spans) span.toMap()],
      'media': [for (final tile in media) tile.toMap()],
      'pollChoices': [for (final choice in pollChoices) choice.toMap()],
      'reactions': [for (final reaction in reactions) reaction.toMap()],
      'buttons': [for (final button in buttons) button.toMap()],
    },
  };

  @override
  bool operator ==(Object other) {
    if (other is! NativeChatItem) return false;
    return id == other.id &&
        role == other.role &&
        text == other.text &&
        kind == other.kind &&
        outgoing == other.outgoing &&
        time == other.time &&
        delivery == other.delivery &&
        cluster == other.cluster &&
        edited == other.edited &&
        deleted == other.deleted &&
        canReply == other.canReply &&
        selected == other.selected &&
        highlighted == other.highlighted &&
        showAvatar == other.showAvatar &&
        showSender == other.showSender &&
        transcriptOpen == other.transcriptOpen &&
        playing == other.playing &&
        progress == other.progress &&
        senderName == other.senderName &&
        avatarUrl == other.avatarUrl &&
        replyId == other.replyId &&
        replyAuthor == other.replyAuthor &&
        replyText == other.replyText &&
        forwardAuthor == other.forwardAuthor &&
        mediaUrl == other.mediaUrl &&
        playUrl == other.playUrl &&
        fileName == other.fileName &&
        duration == other.duration &&
        transcript == other.transcript &&
        comments == other.comments &&
        audioId == other.audioId &&
        senderId == other.senderId &&
        pollId == other.pollId &&
        pollTotal == other.pollTotal &&
        pollMultiple == other.pollMultiple &&
        pollVoted == other.pollVoted &&
        listEquals(wave, other.wave) &&
        listEquals(spans, other.spans) &&
        listEquals(media, other.media) &&
        listEquals(pollChoices, other.pollChoices) &&
        listEquals(reactions, other.reactions) &&
        listEquals(buttons, other.buttons);
  }

  @override
  int get hashCode => Object.hash(
    id,
    role,
    text,
    kind,
    outgoing,
    time,
    delivery,
    cluster,
    edited,
    deleted,
    selected,
    highlighted,
    showSender,
    transcriptOpen,
    playing,
    replyText,
    senderId,
    pollId,
    pollVoted,
    Object.hash(
      progress,
      playUrl,
      Object.hashAll(wave),
      Object.hashAll(spans),
      Object.hashAll(media),
      Object.hashAll(pollChoices),
      Object.hashAll(reactions),
      Object.hashAll(buttons),
    ),
  );
}

@immutable
class NativeChatUpdate {
  final List<String>? order;
  final List<NativeChatItem> items;

  const NativeChatUpdate({this.order, this.items = const []});

  bool get isEmpty => order == null && items.isEmpty;

  Map<String, Object?> toMap() => {
    if (order != null) 'order': order,
    'items': [for (final item in items) item.toMap()],
  };

  static NativeChatUpdate between(
    List<NativeChatItem> previous,
    List<NativeChatItem> next,
  ) {
    final before = {for (final item in previous) item.id: item};
    final order = [for (final item in next) item.id];
    final orderChanged = !listEquals(order, [
      for (final item in previous) item.id,
    ]);
    return NativeChatUpdate(
      order: orderChanged ? order : null,
      items: [
        for (final item in next)
          if (before[item.id] != item) item,
      ],
    );
  }
}

class NativeChatCallbacks {
  final ValueChanged<String> onOpen;
  final void Function(String id, Rect origin) onLongPress;
  final ValueChanged<String> onReply;
  final void Function(String id, String emoji) onReaction;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onReplyJump;
  final void Function(String id, int index) onMedia;
  final ValueChanged<String> onLink;
  final ValueChanged<int> onMention;
  final void Function(String id, List<int> answers) onPoll;
  final void Function(String id, int index) onKeyboard;
  final ValueChanged<String> onTranscribe;
  final ValueChanged<String> onVoice;
  final ValueChanged<String> onComments;
  final ValueChanged<String> onSticker;
  final ValueChanged<int> onAvatar;
  final VoidCallback onLoadOlder;
  final VoidCallback onLoadNewer;
  final ValueChanged<bool> onNearBottom;
  final ValueChanged<List<String>> onVisible;

  const NativeChatCallbacks({
    required this.onOpen,
    required this.onLongPress,
    required this.onReply,
    required this.onReaction,
    required this.onSelect,
    required this.onReplyJump,
    required this.onMedia,
    required this.onLink,
    required this.onMention,
    required this.onPoll,
    required this.onKeyboard,
    required this.onTranscribe,
    required this.onVoice,
    required this.onComments,
    required this.onSticker,
    required this.onAvatar,
    required this.onLoadOlder,
    required this.onLoadNewer,
    required this.onNearBottom,
    required this.onVisible,
  });
}

class NativeChatCommands {
  NativeChatController? _controller;

  bool get isAttached => _controller != null;

  void attach(NativeChatController controller) => _controller = controller;

  void detach(NativeChatController controller) {
    if (identical(_controller, controller)) _controller = null;
  }

  Future<void> highlight(String? id) async => _controller?.highlight(id);

  Future<void> scrollTo(String id) async => _controller?.scrollTo(id);

  Future<void> scrollToEnd() async => _controller?.scrollToEnd();

  Future<void> stickerFrame(
    String id,
    Uint8List rgba,
    int width,
    int height,
  ) async {
    await _controller?.stickerFrame(id, rgba, width, height);
  }
}

class NativeChatController {
  NativeChatController(int viewId, this.callbacks)
    : channel = MethodChannel('${NativeChatBridge.viewType}/$viewId') {
    channel.setMethodCallHandler(_onCall);
  }

  final MethodChannel channel;
  NativeChatCallbacks callbacks;
  List<NativeChatItem> _sent = const [];
  bool _disposed = false;

  void seed(List<NativeChatItem> items) => _sent = items;

  Future<void> update(List<NativeChatItem> items) async {
    final update = NativeChatUpdate.between(_sent, items);
    _sent = items;
    if (update.isEmpty) return;
    await _invoke('apply', update.toMap());
  }

  Future<void> setChrome(Map<String, Object?> chrome) =>
      _invoke('setChrome', chrome);

  Future<void> highlight(String? id) => _invoke('highlight', {'id': id});

  Future<void> scrollTo(String id) => _invoke('scrollTo', {'id': id});

  Future<void> scrollToEnd() => _invoke('scrollToEnd', null);

  Future<void> stickerFrame(
    String id,
    Uint8List rgba,
    int width,
    int height,
  ) => _invoke('stickerFrame', {
    'id': id,
    'bytes': rgba,
    'width': width,
    'height': height,
  });

  Future<void> _invoke(String method, Object? arguments) async {
    if (_disposed) return;
    try {
      await channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<Object?> _onCall(MethodCall call) async {
    final args = call.arguments is Map
        ? Map<String, Object?>.from(call.arguments as Map)
        : const <String, Object?>{};
    final id = args['id'];
    switch (call.method) {
      case 'open':
        if (id is String) callbacks.onOpen(id);
      case 'longPress':
        if (id is String) callbacks.onLongPress(id, _rectOf(args));
      case 'reply':
        if (id is String) callbacks.onReply(id);
      case 'reaction':
        final emoji = args['emoji'];
        if (id is String && emoji is String) callbacks.onReaction(id, emoji);
      case 'select':
        if (id is String) callbacks.onSelect(id);
      case 'replyJump':
        if (id is String) callbacks.onReplyJump(id);
      case 'media':
        if (id is String) callbacks.onMedia(id, args['index'] is int ? args['index'] as int : 0);
      case 'link':
        final url = args['url'];
        if (url is String && url.isNotEmpty) callbacks.onLink(url);
      case 'mention':
        final userId = args['userId'];
        if (userId is int) callbacks.onMention(userId);
      case 'poll':
        if (id is String) callbacks.onPoll(id, _intIdsOf(args));
      case 'keyboard':
        final index = args['index'];
        if (id is String && index is int) callbacks.onKeyboard(id, index);
      case 'transcribe':
        if (id is String) callbacks.onTranscribe(id);
      case 'voice':
        if (id is String) callbacks.onVoice(id);
      case 'comments':
        if (id is String) callbacks.onComments(id);
      case 'sticker':
        if (id is String) callbacks.onSticker(id);
      case 'avatar':
        final senderId = args['senderId'];
        if (senderId is int) callbacks.onAvatar(senderId);
      case 'loadOlder':
        callbacks.onLoadOlder();
      case 'loadNewer':
        callbacks.onLoadNewer();
      case 'nearBottom':
        callbacks.onNearBottom(args['on'] == true);
      case 'visible':
        callbacks.onVisible(_idsOf(args));
    }
    return null;
  }

  static List<int> _intIdsOf(Map<String, Object?> args) {
    final raw = args['answers'];
    if (raw is! List) return const [];
    return [
      for (final value in raw)
        if (value is int) value,
    ];
  }

  static List<String> _idsOf(Map<String, Object?> args) {
    final raw = args['ids'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  static Rect _rectOf(Map<String, Object?> args) {
    double read(String key) => (args[key] as num?)?.toDouble() ?? 0;
    return Rect.fromLTWH(read('x'), read('y'), read('width'), read('height'));
  }

  void dispose() {
    _disposed = true;
    channel.setMethodCallHandler(null);
  }
}

class NativeChatBridge {
  NativeChatBridge._();

  static const viewType = 'ru.komet.app/native_chat';

  static bool? debugAvailable;

  static bool get isEligible {
    if (debugAvailable == false) return false;
    if (debugAvailable != true) {
      if (kIsWeb) return false;
      if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    }
    return AppIosGlass.active.value;
  }

  @visibleForTesting
  static void debugReset() {
    debugAvailable = null;
  }

  static Listenable get eligibility => AppIosGlass.active;
}
