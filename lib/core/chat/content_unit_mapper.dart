import '../../backend/modules/messages.dart';
import '../../models/attachment.dart';
import '../../models/poll.dart';
import 'chat_content_unit.dart';
import 'native_parity.dart';

const albumTileLimit = 10;

typedef UnitName = String Function(int senderId);

class UnitMapContext {
  final UnitName names;
  final String? comments;
  final String? transcript;
  final bool transcriptOpen;
  final Poll? Function(int pollId)? pollOf;

  const UnitMapContext({
    required this.names,
    this.comments,
    this.transcript,
    this.transcriptOpen = false,
    this.pollOf,
  });
}

List<ChatContentUnit> unitsFor(CachedMessage message, UnitMapContext context) {
  if (message.isControl) {
    return [ServiceUnit(_controlText(message, context.names))];
  }
  final units = <ChatContentUnit>[];
  final forwarded = message.forwardedAttachment;
  if (forwarded != null) {
    final author = (forwarded.originalSenderName ?? '').trim();
    units.add(
      ForwardHeaderUnit(
        author.isEmpty ? _named(context.names(forwarded.originalSenderId)) : author,
      ),
    );
  }
  final reply = message.replyInfo;
  if (reply != null) {
    units.add(
      ReplyHeaderUnit(
        replyId: reply.messageId ?? '',
        author: _named(context.names(reply.senderId)),
        preview: reply.previewText(),
      ),
    );
  }

  final attachments = _attachments(message);
  final visuals = _visuals(attachments);
  if (visuals.length > 1) {
    final kept = visuals.take(albumTileLimit).toList();
    units.add(
      AlbumUnit(
        kept,
        extra: visuals.length > albumTileLimit
            ? visuals.length - albumTileLimit
            : 0,
      ),
    );
  }

  for (final attachment in attachments) {
    if (attachment is InlineKeyboardAttachment) continue;
    if (visuals.length > 1 &&
        (attachment is PhotoAttachment ||
            (attachment is VideoAttachment && !attachment.isNote))) {
      continue;
    }
    final unit = _attachmentUnit(attachment, message, context);
    if (unit != null) units.add(unit);
  }

  final own = nativeVisibleText(
    accountId: message.accountId,
    chatId: message.chatId,
    messageId: message.id,
    stored: message.text,
  ).text.trim();
  final forwardedText = nativeVisibleText(
    accountId: message.accountId,
    chatId: forwarded?.originalChatId ?? message.chatId,
    messageId: forwarded?.originalMessageId,
    stored: forwarded?.originalText,
  ).text.trim();
  final text = own.isNotEmpty ? own : forwardedText;
  if (text.isNotEmpty && !_hidesCaption(attachments)) {
    units.add(TextUnit(text));
  }

  final reactions = _reactionChips(message);
  if (reactions.isNotEmpty) units.add(ReactionsUnit(reactions));

  final keyboard = _keyboard(message);
  if (keyboard.isNotEmpty) units.add(BotKeyboardUnit(keyboard));

  final comments = context.comments;
  if (comments != null && comments.isNotEmpty) units.add(CommentsUnit(comments));
  return units;
}

ChatContentUnit? _attachmentUnit(
  MessageAttachment attachment,
  CachedMessage message,
  UnitMapContext context,
) {
  if (attachment is VideoAttachment && attachment.isNote) {
    return VideoNoteUnit(url: attachment.thumbnail ?? attachment.previewData ?? '');
  }
  switch (attachment.type) {
    case AttachmentType.photo:
      final photo = attachment as PhotoAttachment;
      return PhotoUnit(
        url: photo.localPath ?? photo.baseUrl ?? '',
        width: photo.width ?? 0,
        height: photo.height ?? 0,
      );
    case AttachmentType.video:
      final video = attachment as VideoAttachment;
      return VideoUnit(
        url: video.thumbnail ?? video.previewData ?? '',
        width: video.width ?? 0,
        height: video.height ?? 0,
      );
    case AttachmentType.audio:
      final audio = attachment as AudioAttachment;
      return VoiceUnit(
        duration: _clock(audio.duration),
        wave: _wave(audio.waveform),
        audioId: audio.audioId,
      );
    case AttachmentType.file:
      final file = attachment as FileAttachment;
      final name = (file.name ?? '').trim();
      final dot = name.lastIndexOf('.');
      return FileUnit(
        name: name.isEmpty ? 'Файл' : name,
        size: file.size ?? 0,
        extensionName: dot >= 0 && dot < name.length - 1
            ? name.substring(dot + 1)
            : '',
      );
    case AttachmentType.sticker:
      final sticker = attachment as StickerAttachment;
      return StickerUnit(url: sticker.baseUrl ?? sticker.previewData ?? '');
    case AttachmentType.contact:
      final contact = attachment as ContactAttachment;
      final phone = contact.phoneNumber?.trim() ?? '';
      return ContactUnit(
        name: _contactName(contact),
        hasPhone: phone.isNotEmpty,
        contactId: contact.contactId,
      );
    case AttachmentType.location:
      final place = attachment as LocationAttachment;
      return LocationUnit(
        latitude: place.latitude,
        longitude: place.longitude,
        previewUrl: place.baseUrl ?? place.previewData ?? '',
      );
    case AttachmentType.share:
      final share = attachment as ShareAttachment;
      return LinkPreviewUnit(
        title: share.title ?? '',
        description: share.description ?? '',
        url: share.url ?? '',
        thumbnail: share.image?.baseUrl ?? share.image?.previewData ?? '',
      );
    case AttachmentType.poll:
      final pollAttachment = attachment as PollAttachment;
      final poll = context.pollOf?.call(pollAttachment.pollId);
      return PollUnit(
        title: (pollAttachment.title ?? '').trim(),
        multiple: poll?.isMultiple ?? false,
        voted: poll?.hasMyVote ?? false,
        choices: [
          if (poll != null)
            for (final answer in poll.answers)
              PollChoiceUnit(
                id: answer.answerId,
                text: answer.text,
                count: answer.voteCount,
                mine: answer.mine,
              ),
        ],
      );
    case AttachmentType.call:
    case AttachmentType.forward:
    case AttachmentType.control:
    case AttachmentType.inlineKeyboard:
    case AttachmentType.unknown:
      return null;
  }
}

bool _hidesCaption(List<MessageAttachment> attachments) {
  if (attachments.isEmpty) return false;
  final first = attachments.first;
  if (first is StickerAttachment) return true;
  if (first is VideoAttachment && first.isNote) return true;
  return false;
}

List<AlbumTile> _visuals(List<MessageAttachment> attachments) {
  final tiles = <AlbumTile>[];
  for (final attachment in attachments) {
    if (attachment is PhotoAttachment) {
      final url = attachment.localPath ?? attachment.baseUrl ?? '';
      if (url.isEmpty) continue;
      tiles.add(
        AlbumTile(
          url: url,
          tileKind: 'photo',
          width: attachment.width ?? 0,
          height: attachment.height ?? 0,
        ),
      );
    } else if (attachment is VideoAttachment && !attachment.isNote) {
      final url = attachment.thumbnail ?? attachment.previewData ?? '';
      if (url.isEmpty) continue;
      tiles.add(
        AlbumTile(
          url: url,
          tileKind: 'video',
          width: attachment.width ?? 0,
          height: attachment.height ?? 0,
        ),
      );
    }
  }
  return tiles;
}

List<List<KeyboardButtonUnit>> _keyboard(CachedMessage message) {
  final rows = <List<KeyboardButtonUnit>>[];
  for (final attachment in message.attachments ?? const <MessageAttachment>[]) {
    if (attachment is! InlineKeyboardAttachment || attachment.isEmpty) continue;
    for (var rowIndex = 0; rowIndex < attachment.rows.length; rowIndex++) {
      final row = <KeyboardButtonUnit>[];
      final source = attachment.rows[rowIndex];
      for (var column = 0; column < source.length; column++) {
        final button = source[column];
        if (button.text.isEmpty) continue;
        row.add(
          KeyboardButtonUnit(text: button.text, row: rowIndex, column: column),
        );
      }
      if (row.isNotEmpty) rows.add(row);
    }
  }
  return rows;
}

List<ReactionChip> _reactionChips(CachedMessage message) {
  final raw = message.payload?['reactionInfo'];
  if (raw is! Map) return const [];
  final counters = raw['counters'];
  if (counters is! List) return const [];
  final yours = raw['yourReaction']?.toString();
  return [
    for (final counter in counters)
      if (counter is Map && (counter['reaction']?.toString() ?? '').isNotEmpty)
        ReactionChip(
          emoji: counter['reaction'].toString(),
          count: (counter['count'] as num?)?.toInt() ?? 0,
          mine: counter['reaction'].toString() == yours,
        ),
  ];
}

List<MessageAttachment> _attachments(CachedMessage message) {
  final forwarded = message.forwardedAttachment?.originalAttachments;
  if (forwarded != null && forwarded.isNotEmpty) return forwarded;
  return message.attachments ?? const [];
}

String _contactName(ContactAttachment contact) {
  final named = (contact.name ?? '').trim();
  if (named.isNotEmpty) return named;
  final parts = [
    contact.firstName?.trim() ?? '',
    contact.lastName?.trim() ?? '',
  ].where((part) => part.isNotEmpty);
  final joined = parts.join(' ');
  return joined.isEmpty ? 'Контакт' : joined;
}

String _clock(int? millis) {
  if (millis == null || millis <= 0) return '';
  final total = (millis / 1000).round();
  final minutes = total ~/ 60;
  final seconds = (total % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

List<int> _wave(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  final amps = raw.codeUnits;
  const maxBars = 48;
  if (amps.length <= maxBars) return amps;
  final step = amps.length / maxBars;
  return [
    for (var i = 0; i < maxBars; i++)
      amps[(i * step).floor().clamp(0, amps.length - 1)],
  ];
}

String _named(String raw) {
  final trimmed = raw.trim();
  return trimmed.isEmpty ? 'Пользователь' : trimmed;
}

String _controlText(CachedMessage message, UnitName names) {
  final control = message.controlAttachment;
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
