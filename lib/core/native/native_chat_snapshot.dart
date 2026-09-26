import '../../backend/modules/messages.dart';
import '../../models/attachment.dart';
import '../../models/poll.dart';
import '../../models/reaction_info.dart';
import '../utils/format.dart';
import '../utils/text_format.dart';
import 'native_chat_bridge.dart';

const nativeChatMergeWindow = Duration(minutes: 10);

typedef NativeChatName = String Function(int senderId);
typedef NativeChatTranscript = ({String text, bool expanded})?;

String nativeChatDayLabel(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Сегодня';
  if (day == yesterday) return 'Вчера';
  const months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  if (date.year == now.year) return '${date.day} ${months[date.month - 1]}';
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

List<NativeChatItem> buildNativeChatItems({
  required List<CachedMessage> messages,
  required int myId,
  required DateTime now,
  int? unreadAnchorMillis,
  Set<String> selected = const {},
  String? highlightId,
  bool showSenders = false,
  bool canReply = true,
  bool withSeconds = false,
  int? otherReadMillis,
  String unreadLabel = 'Новые сообщения',
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
}) {
  final names = nameOf ?? ((id) => 'Пользователь');
  final visible = <CachedMessage>[
    for (final message in messages)
      if (!message.isSilentBotStart) message,
  ];
  final unreadIndex = unreadAnchorMillis == null
      ? -1
      : visible.indexWhere((message) => message.time > unreadAnchorMillis);

  final items = <NativeChatItem>[];
  final times = <String, int>{};
  for (var i = 0; i < visible.length; i++) {
    final message = visible[i];
    final stamp = DateTime.fromMillisecondsSinceEpoch(message.time);
    final previous = i == 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(visible[i - 1].time);
    if (previous == null || !_sameDay(previous, stamp)) {
      final day = DateTime(stamp.year, stamp.month, stamp.day);
      items.add(
        NativeChatItem.date(
          'date:${day.millisecondsSinceEpoch}',
          nativeChatDayLabel(stamp, now),
        ),
      );
    }
    if (i == unreadIndex) items.add(NativeChatItem.unread(unreadLabel));
    final built = _messageItem(
      message,
      myId: myId,
      names: names,
      avatarOf: avatarOf,
      statusOf: statusOf,
      reactionOf: reactionOf,
      transcriptOf: transcriptOf,
      commentsOf: commentsOf,
      selected: selected.contains(message.id),
      highlighted: highlightId == message.id,
      canReply: canReply,
      withSeconds: withSeconds,
      otherReadMillis: otherReadMillis,
      playing: playingId == message.id,
      voiceProgress: progressId == message.id ? voiceProgress : 0,
      pollOf: pollOf,
    );
    if (built != null) {
      times[built.id] = message.time;
      items.add(built);
    }
  }
  return _cluster(items, times: times, showSenders: showSenders, names: names);
}

NativeChatItem? _messageItem(
  CachedMessage message, {
  required int myId,
  required NativeChatName names,
  required String? Function(int senderId)? avatarOf,
  required String? Function(CachedMessage message)? statusOf,
  required Map<dynamic, dynamic>? Function(CachedMessage message)? reactionOf,
  required NativeChatTranscript Function(String messageId)? transcriptOf,
  required String? Function(CachedMessage message)? commentsOf,
  required bool selected,
  required bool highlighted,
  required bool canReply,
  required bool withSeconds,
  required int? otherReadMillis,
  required bool playing,
  required double voiceProgress,
  required Poll? Function(int pollId)? pollOf,
}) {
  final control = message.controlAttachment;
  if (message.isControl) {
    final text = _controlText(message, control, names);
    if (text.isEmpty) return null;
    return NativeChatItem(
      id: message.id,
      role: NativeChatRole.message,
      kind: NativeChatKind.control,
      text: text,
      senderId: control?.userId ?? message.senderId,
      time: '',
    );
  }

  final outgoing = message.senderId == myId;
  final reply = message.replyInfo;
  final forwarded = message.forwardedAttachment;
  final kind = _kind(message);
  final transcript = kind == NativeChatKind.voice
      ? transcriptOf?.call(message.id)
      : null;
  final stamp = DateTime.fromMillisecondsSinceEpoch(message.time);
  final edited =
      message.status == 'EDITED' ||
      (message.editHistory != null && message.editHistory!.isNotEmpty);
  final clock = formatClock(stamp, withSeconds: withSeconds);
  final body = _body(message, kind);
  final pollAttachment = _pollAttachment(message);
  final poll = pollAttachment == null ? null : pollOf?.call(pollAttachment.pollId);
  return NativeChatItem(
    id: message.id,
    role: NativeChatRole.message,
    kind: kind,
    outgoing: outgoing,
    text: (kind == NativeChatKind.sticker || kind == NativeChatKind.videoNote) &&
            (message.text == null || message.text!.trim().isEmpty)
        ? ''
        : body,
    time: edited ? '$clock ред.' : clock,
    delivery: outgoing
        ? _delivery(
            statusOf?.call(message) ?? message.status,
            message.time,
            otherReadMillis,
          )
        : NativeChatDelivery.none,
    edited: edited,
    deleted: message.deleted,
    canReply: canReply && !message.isControl,
    selected: selected,
    highlighted: highlighted,
    senderId: message.senderId,
    senderName: _named(names(message.senderId)),
    avatarUrl: avatarOf?.call(message.senderId),
    replyId: reply?.messageId,
    replyAuthor: reply == null ? null : _named(names(reply.senderId)),
    replyText: reply?.previewText(),
    forwardAuthor: forwarded == null
        ? null
        : _named(forwarded.originalSenderName ?? names(forwarded.originalSenderId)),
    mediaUrl: _mediaUrl(message),
    media: _mediaTiles(message),
    spans: _spans(message, body),
    pollId: pollAttachment?.pollId,
    pollTotal: poll?.total,
    pollMultiple: poll?.isMultiple ?? false,
    pollVoted: poll?.hasMyVote ?? false,
    pollChoices: [
      if (poll != null)
        for (final answer in poll.answers)
          NativeChatPollChoice(
            id: answer.answerId,
            text: answer.text,
            count: answer.voteCount,
            mine: answer.mine,
          ),
    ],
    fileName: _fileName(message),
    duration: _duration(message),
    audioId: _audioId(message),
    playing: playing && kind == NativeChatKind.voice,
    progress: kind == NativeChatKind.voice ? voiceProgress.clamp(0.0, 1.0) : 0,
    wave: kind == NativeChatKind.voice ? _wave(message) : const [],
    transcript: transcript?.text,
    transcriptOpen: transcript?.expanded ?? false,
    comments: commentsOf?.call(message),
    reactions: _reactions(reactionOf?.call(message) ?? message.payload?['reactionInfo']),
    buttons: _buttons(message),
  );
}

List<NativeChatItem> _cluster(
  List<NativeChatItem> items, {
  required Map<String, int> times,
  required bool showSenders,
  required NativeChatName names,
}) {
  final result = <NativeChatItem>[];
  var index = 0;
  while (index < items.length) {
    final item = items[index];
    if (!_clustersWith(item)) {
      result.add(item);
      index++;
      continue;
    }
    var end = index + 1;
    while (end < items.length &&
        _sameCluster(items[end - 1], items[end], times)) {
      end++;
    }
    final count = end - index;
    for (var offset = 0; offset < count; offset++) {
      final current = items[index + offset];
      final cluster = count == 1
          ? NativeChatCluster.single
          : offset == 0
          ? NativeChatCluster.top
          : offset == count - 1
          ? NativeChatCluster.bottom
          : NativeChatCluster.middle;
      final last = offset == count - 1;
      final first = offset == 0;
      result.add(
        current.copyWith(
          cluster: cluster,
          showAvatar: showSenders && !current.outgoing && last,
          showSender: showSenders && !current.outgoing && first,
          senderName: current.senderName ?? _named(names(current.senderId ?? 0)),
        ),
      );
    }
    index = end;
  }
  return result;
}

bool _clustersWith(NativeChatItem item) =>
    item.role == NativeChatRole.message && item.kind != NativeChatKind.control;

bool _sameCluster(
  NativeChatItem previous,
  NativeChatItem next,
  Map<String, int> times,
) {
  if (!_clustersWith(previous) || !_clustersWith(next)) return false;
  if (previous.senderId == null || previous.senderId != next.senderId) {
    return false;
  }
  if (previous.outgoing != next.outgoing) return false;
  final previousTime = times[previous.id];
  final nextTime = times[next.id];
  if (previousTime == null || nextTime == null) return false;
  if (nextTime - previousTime > nativeChatMergeWindow.inMilliseconds) {
    return false;
  }
  return _sameDay(
    DateTime.fromMillisecondsSinceEpoch(previousTime),
    DateTime.fromMillisecondsSinceEpoch(nextTime),
  );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _named(String raw) {
  final trimmed = raw.trim();
  return trimmed.isEmpty ? 'Пользователь' : trimmed;
}

String _controlText(
  CachedMessage message,
  ControlAttachment? control,
  NativeChatName names,
) {
  if (control == null) return '';
  final sender = _named(names(message.senderId));
  switch (control.event) {
    case 'new':
      return '$sender создал(а) чат';
    case 'add':
      final people = (control.userIds ?? const <int>[])
          .map((id) => _named(names(id)))
          .join(', ');
      return '$sender добавил(а) $people';
    case 'leave':
      return '$sender покинул(а) чат';
    case 'joinByLink':
      return '$sender присоединился(-ась) к чату';
    case 'pin':
      return '$sender закрепил(а) сообщение';
    case ControlAttachment.botStartedEvent:
      final payload = message.botStartPayload;
      return payload == null ? 'Бот запущен' : 'Бот запущен: $payload';
    default:
      return (control.title ?? '').trim();
  }
}

NativeChatKind _kind(CachedMessage message) {
  final forwarded = message.forwardedAttachment;
  final attachments =
      forwarded?.originalAttachments ?? message.attachments ?? const [];
  if (_visualCount(attachments) > 1) return NativeChatKind.album;
  for (final attachment in attachments) {
    if (attachment is InlineKeyboardAttachment) continue;
    if (attachment is VideoAttachment && attachment.isNote) {
      return NativeChatKind.videoNote;
    }
    switch (attachment.type) {
      case AttachmentType.photo:
        return NativeChatKind.photo;
      case AttachmentType.video:
        return NativeChatKind.video;
      case AttachmentType.audio:
        return NativeChatKind.voice;
      case AttachmentType.file:
        return NativeChatKind.file;
      case AttachmentType.sticker:
        return NativeChatKind.sticker;
      case AttachmentType.contact:
        return NativeChatKind.contact;
      case AttachmentType.location:
        return NativeChatKind.location;
      case AttachmentType.poll:
        return NativeChatKind.poll;
      case AttachmentType.call:
        return NativeChatKind.call;
      case AttachmentType.share:
        return NativeChatKind.share;
      case AttachmentType.forward:
        return NativeChatKind.forward;
      case AttachmentType.control:
      case AttachmentType.inlineKeyboard:
      case AttachmentType.unknown:
        continue;
    }
  }
  if (forwarded != null) return NativeChatKind.forward;
  return NativeChatKind.text;
}

String _body(CachedMessage message, NativeChatKind kind) {
  final own = message.text?.trim();
  if (own != null && own.isNotEmpty) return own;
  final forwarded = message.forwardedAttachment?.originalText?.trim();
  if (forwarded != null && forwarded.isNotEmpty) return forwarded;
  return switch (kind) {
    NativeChatKind.album => '',
    NativeChatKind.photo => 'Фото',
    NativeChatKind.video => 'Видео',
    NativeChatKind.videoNote => 'Видеосообщение',
    NativeChatKind.voice => 'Голосовое сообщение',
    NativeChatKind.file => _fileName(message) ?? 'Файл',
    NativeChatKind.sticker => 'Стикер',
    NativeChatKind.contact => 'Контакт',
    NativeChatKind.location => 'Геолокация',
    NativeChatKind.poll => _pollTitle(message) ?? 'Опрос',
    NativeChatKind.call => _callLabel(message),
    NativeChatKind.share => 'Ссылка',
    NativeChatKind.forward => 'Переслано',
    NativeChatKind.text || NativeChatKind.control => '',
  };
}

int _visualCount(List<MessageAttachment> attachments) {
  var count = 0;
  for (final attachment in attachments) {
    if (attachment is PhotoAttachment) count++;
    if (attachment is VideoAttachment && !attachment.isNote) count++;
  }
  return count;
}

List<NativeChatMedia> _mediaTiles(CachedMessage message) {
  final tiles = <NativeChatMedia>[];
  for (final attachment in _attachments(message)) {
    if (attachment is PhotoAttachment) {
      final url = attachment.localPath ?? attachment.baseUrl;
      if (url != null && (url.startsWith('http') || url.startsWith('file'))) {
        tiles.add(NativeChatMedia(url: url, kind: 'photo'));
      }
    } else if (attachment is VideoAttachment && !attachment.isNote) {
      final url = attachment.thumbnail ?? attachment.previewData;
      if (url != null && url.startsWith('http')) {
        tiles.add(NativeChatMedia(url: url, kind: 'video'));
      }
    }
  }
  return tiles;
}

List<NativeChatSpan> _spans(CachedMessage message, String text) {
  if (text.isEmpty) return const [];
  final own = message.text?.trim();
  final ranges = own != null && own.isNotEmpty
      ? message.formatRanges
      : message.forwardedAttachment?.originalFormatRanges ?? const [];
  return [
    for (final segment in segmentizeFormats(text, ranges))
      if (segment.formats.isNotEmpty)
        NativeChatSpan(
          start: segment.start,
          length: segment.end - segment.start,
          styles: [for (final format in segment.formats) _styleName(format)],
          url: segment.url,
          userId: segment.mentionId,
        ),
  ];
}

String _styleName(TextFormat format) => switch (format) {
  TextFormat.strong || TextFormat.heading => 'strong',
  TextFormat.emphasized => 'emphasized',
  TextFormat.underline => 'underline',
  TextFormat.strikethrough => 'strike',
  TextFormat.monospaced => 'mono',
  TextFormat.link => 'link',
  TextFormat.userMention => 'mention',
  TextFormat.quote => 'quote',
  TextFormat.animoji => 'animoji',
};

PollAttachment? _pollAttachment(CachedMessage message) {
  for (final attachment in message.attachments ?? const <MessageAttachment>[]) {
    if (attachment is PollAttachment) return attachment;
  }
  return null;
}

String? _fileName(CachedMessage message) {
  for (final attachment in _attachments(message)) {
    if (attachment is FileAttachment) {
      final name = attachment.name?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
  }
  return null;
}

String? _pollTitle(CachedMessage message) {
  for (final attachment in _attachments(message)) {
    if (attachment is PollAttachment) {
      final title = attachment.title?.trim();
      if (title != null && title.isNotEmpty) return title;
    }
  }
  return null;
}

String _callLabel(CachedMessage message) {
  for (final attachment in _attachments(message)) {
    if (attachment is CallAttachment) {
      return attachment.isVideo ? 'Видеозвонок' : 'Звонок';
    }
  }
  return 'Звонок';
}

String? _remote(String? url) {
  if (url == null) return null;
  if (url.startsWith('http') || url.startsWith('file')) return url;
  return null;
}

String? _mediaUrl(CachedMessage message) {
  for (final attachment in _attachments(message)) {
    final url = switch (attachment) {
      PhotoAttachment() => _remote(attachment.localPath) ?? _remote(attachment.baseUrl),
      VideoAttachment() => _remote(attachment.thumbnail) ?? _remote(attachment.previewData),
      StickerAttachment() => _remote(attachment.baseUrl) ?? _remote(attachment.previewData),
      _ => null,
    };
    if (url != null) return url;
  }
  return null;
}

String? _duration(CachedMessage message) {
  for (final attachment in _attachments(message)) {
    final millis = switch (attachment) {
      AudioAttachment() => attachment.duration,
      VideoAttachment() => attachment.duration,
      _ => null,
    };
    if (millis != null && millis > 0) {
      return formatSecondsMmSs((millis / 1000).round());
    }
  }
  return null;
}

List<int> _wave(CachedMessage message) {
  String? raw;
  for (final attachment in _attachments(message)) {
    if (attachment is AudioAttachment &&
        attachment.waveform != null &&
        attachment.waveform!.isNotEmpty) {
      raw = attachment.waveform;
    }
  }
  if (raw == null) return const [];
  final amps = raw.codeUnits;
  const maxBars = 48;
  if (amps.length <= maxBars) return amps;
  final step = amps.length / maxBars;
  return [
    for (var i = 0; i < maxBars; i++)
      amps[(i * step).floor().clamp(0, amps.length - 1)],
  ];
}

int? _audioId(CachedMessage message) {
  for (final attachment in _attachments(message)) {
    if (attachment is AudioAttachment) return attachment.audioId;
  }
  return null;
}

List<MessageAttachment> _attachments(CachedMessage message) {
  final forwarded = message.forwardedAttachment?.originalAttachments;
  if (forwarded != null && forwarded.isNotEmpty) return forwarded;
  return message.attachments ?? const [];
}

List<NativeChatReaction> _reactions(dynamic raw) {
  final info = raw is Map ? ReactionInfo.fromMap(raw) : null;
  if (info == null) return const [];
  return [
    for (final counter in info.counters)
      NativeChatReaction(
        emoji: counter.reaction,
        count: counter.count,
        mine: counter.reaction == info.yourReaction,
      ),
  ];
}

List<NativeChatButton> _buttons(CachedMessage message) {
  final buttons = <NativeChatButton>[];
  for (final attachment in message.attachments ?? const <MessageAttachment>[]) {
    if (attachment is! InlineKeyboardAttachment || attachment.isEmpty) continue;
    for (final row in attachment.rows) {
      for (final button in row) {
        if (button.text.isEmpty) continue;
        buttons.add(
          NativeChatButton(
            text: button.text,
            type: button.type,
            url: button.url,
            payload: button.payload,
            webApp: button.webApp,
            callbackId: attachment.callbackId,
            contactId: button.contactId,
          ),
        );
      }
    }
  }
  return buttons;
}

NativeChatDelivery _delivery(String? status, int messageTime, int? readTime) {
  if (status == 'sending' || status == 'pending') {
    return NativeChatDelivery.sending;
  }
  if (status == 'error' || status == 'failed') return NativeChatDelivery.error;
  if (status == 'read' ||
      (readTime != null && readTime > 0 && readTime >= messageTime)) {
    return NativeChatDelivery.read;
  }
  return NativeChatDelivery.sent;
}
