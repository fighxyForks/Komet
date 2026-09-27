/// One ordered piece of a message. Dart builds the list; Swift only draws it.
abstract class ChatContentUnit {
  const ChatContentUnit();

  String get kind;

  Map<String, Object?> toMap() => {'kind': kind, ...fields};

  Map<String, Object?> get fields;

  @override
  bool operator ==(Object other) =>
      other is ChatContentUnit && other.kind == kind && _same(fields, other.fields);

  @override
  int get hashCode => Object.hash(kind, _canon(fields));
}

class TextUnit extends ChatContentUnit {
  final String text;
  final List<Map<String, Object?>> spans;

  const TextUnit(this.text, {this.spans = const []});

  @override
  String get kind => 'text';

  @override
  Map<String, Object?> get fields => {'text': text, 'spans': spans};
}

class PhotoUnit extends ChatContentUnit {
  final String url;
  final int width;
  final int height;

  const PhotoUnit({required this.url, this.width = 0, this.height = 0});

  @override
  String get kind => 'photo';

  @override
  Map<String, Object?> get fields => {
    'url': url,
    'width': width,
    'height': height,
  };
}

class VideoUnit extends ChatContentUnit {
  final String url;
  final int width;
  final int height;

  const VideoUnit({required this.url, this.width = 0, this.height = 0});

  @override
  String get kind => 'video';

  @override
  Map<String, Object?> get fields => {
    'url': url,
    'width': width,
    'height': height,
  };
}

class AlbumTile {
  final String url;
  final String tileKind;
  final int width;
  final int height;

  const AlbumTile({
    required this.url,
    required this.tileKind,
    this.width = 0,
    this.height = 0,
  });

  Map<String, Object?> toMap() => {
    'url': url,
    'kind': tileKind,
    'width': width,
    'height': height,
  };
}

class AlbumUnit extends ChatContentUnit {
  final List<AlbumTile> tiles;
  final int extra;

  const AlbumUnit(this.tiles, {this.extra = 0});

  @override
  String get kind => 'album';

  @override
  Map<String, Object?> get fields => {
    'tiles': [for (final tile in tiles) tile.toMap()],
    'extra': extra,
  };
}

class FileUnit extends ChatContentUnit {
  final String name;
  final int size;
  final String extensionName;

  const FileUnit({
    required this.name,
    this.size = 0,
    this.extensionName = '',
  });

  @override
  String get kind => 'file';

  @override
  Map<String, Object?> get fields => {
    'name': name,
    'size': size,
    'extension': extensionName,
  };
}

class VoiceUnit extends ChatContentUnit {
  final String duration;
  final List<int> wave;
  final int? audioId;

  const VoiceUnit({this.duration = '', this.wave = const [], this.audioId});

  @override
  String get kind => 'voice';

  @override
  Map<String, Object?> get fields => {
    'duration': duration,
    'wave': wave,
    'audioId': audioId,
  };
}

class VideoNoteUnit extends ChatContentUnit {
  final String url;

  const VideoNoteUnit({this.url = ''});

  @override
  String get kind => 'videoNote';

  @override
  Map<String, Object?> get fields => {'url': url};
}

class StickerUnit extends ChatContentUnit {
  final String url;

  const StickerUnit({this.url = ''});

  @override
  String get kind => 'sticker';

  @override
  Map<String, Object?> get fields => {'url': url};
}

class PollChoiceUnit {
  final int id;
  final String text;
  final int count;
  final bool mine;

  const PollChoiceUnit({
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
}

class PollUnit extends ChatContentUnit {
  final String title;
  final bool multiple;
  final bool voted;
  final List<PollChoiceUnit> choices;

  const PollUnit({
    this.title = '',
    this.multiple = false,
    this.voted = false,
    this.choices = const [],
  });

  @override
  String get kind => 'poll';

  @override
  Map<String, Object?> get fields => {
    'title': title,
    'multiple': multiple,
    'voted': voted,
    'choices': [for (final choice in choices) choice.toMap()],
  };
}

class ContactUnit extends ChatContentUnit {
  final String name;
  final bool hasPhone;
  final int? contactId;

  const ContactUnit({required this.name, this.hasPhone = false, this.contactId});

  @override
  String get kind => 'contact';

  @override
  Map<String, Object?> get fields => {
    'name': name,
    'hasPhone': hasPhone,
    'contactId': contactId,
  };
}

class LocationUnit extends ChatContentUnit {
  final double? latitude;
  final double? longitude;
  final String previewUrl;

  const LocationUnit({this.latitude, this.longitude, this.previewUrl = ''});

  @override
  String get kind => 'location';

  @override
  Map<String, Object?> get fields => {
    'latitude': latitude,
    'longitude': longitude,
    'previewUrl': previewUrl,
  };
}

class LinkPreviewUnit extends ChatContentUnit {
  final String title;
  final String description;
  final String url;
  final String thumbnail;

  const LinkPreviewUnit({
    this.title = '',
    this.description = '',
    this.url = '',
    this.thumbnail = '',
  });

  @override
  String get kind => 'linkPreview';

  @override
  Map<String, Object?> get fields => {
    'title': title,
    'description': description,
    'url': url,
    'thumbnail': thumbnail,
  };
}

class ReplyHeaderUnit extends ChatContentUnit {
  final String replyId;
  final String author;
  final String preview;

  const ReplyHeaderUnit({
    required this.replyId,
    required this.author,
    required this.preview,
  });

  @override
  String get kind => 'replyHeader';

  @override
  Map<String, Object?> get fields => {
    'replyId': replyId,
    'author': author,
    'preview': preview,
  };
}

class ForwardHeaderUnit extends ChatContentUnit {
  final String author;

  const ForwardHeaderUnit(this.author);

  @override
  String get kind => 'forwardHeader';

  @override
  Map<String, Object?> get fields => {'author': author};
}

class ReactionChip {
  final String emoji;
  final int count;
  final bool mine;

  const ReactionChip({required this.emoji, required this.count, this.mine = false});

  Map<String, Object?> toMap() => {
    'emoji': emoji,
    'count': count,
    'mine': mine,
  };
}

class ReactionsUnit extends ChatContentUnit {
  final List<ReactionChip> chips;

  const ReactionsUnit(this.chips);

  @override
  String get kind => 'reactions';

  @override
  Map<String, Object?> get fields => {
    'chips': [for (final chip in chips) chip.toMap()],
  };
}

class KeyboardButtonUnit {
  final String text;
  final int row;
  final int column;

  const KeyboardButtonUnit({
    required this.text,
    required this.row,
    required this.column,
  });

  Map<String, Object?> toMap() => {'text': text, 'row': row, 'column': column};
}

class BotKeyboardUnit extends ChatContentUnit {
  final List<List<KeyboardButtonUnit>> rows;

  const BotKeyboardUnit(this.rows);

  @override
  String get kind => 'botKeyboard';

  @override
  Map<String, Object?> get fields => {
    'rows': [
      for (final row in rows) [for (final button in row) button.toMap()],
    ],
  };
}

class ServiceUnit extends ChatContentUnit {
  final String text;

  const ServiceUnit(this.text);

  @override
  String get kind => 'service';

  @override
  Map<String, Object?> get fields => {'text': text};
}

class CommentsUnit extends ChatContentUnit {
  final String label;

  const CommentsUnit(this.label);

  @override
  String get kind => 'comments';

  @override
  Map<String, Object?> get fields => {'label': label};
}

bool _same(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_same(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_same(a[key], b[key])) return false;
    }
    return true;
  }
  return a == b;
}

String _canon(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return '{${keys.map((key) => '$key:${_canon(value[key])}').join(',')}}';
  }
  if (value is List) {
    return '[${value.map(_canon).join(',')}]';
  }
  return '$value';
}
