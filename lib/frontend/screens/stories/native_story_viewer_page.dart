import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/media/video_request_headers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/stories/story_playback.dart';
import '../../../core/utils/haptics.dart';
import '../../../main.dart' show api, messagesModule, storiesModule;
import '../../../models/story.dart';
import '../../widgets/custom_notification.dart';
import 'story_owner_info.dart';

class NativeStoryViewerPage extends StatefulWidget {
  final List<StoryPreview> previews;
  final int initialIndex;
  final Map<int, StoryOwnerInfo> ownerOverrides;
  final Offset? origin;

  const NativeStoryViewerPage({
    super.key,
    required this.previews,
    this.initialIndex = 0,
    this.ownerOverrides = const {},
    this.origin,
  });

  @override
  State<NativeStoryViewerPage> createState() => _NativeStoryViewerPageState();
}

class _NativeStoryViewerPageState extends State<NativeStoryViewerPage> {
  static const _type = 'ru.komet.app/native_story_viewer';
  static const _reactions = ['❤️', '🔥', '👍', '😂', '😮', '😢'];

  MethodChannel? _channel;
  late int _ownerIndex;
  int _storyIndex = 0;
  int? _selfId;
  String _ownerName = '';
  String? _ownerAvatar;
  bool _replying = false;

  final Map<int, List<Story>> _stories = {};
  final Map<int, bool> _loading = {};
  final Set<int> _marked = {};

  StoryPreview get _owner => widget.previews[_ownerIndex];

  List<Story> get _ownerStories => _stories[_owner.owner.ownerId] ?? const [];

  Story? get _currentStory {
    final list = _ownerStories;
    if (_storyIndex < 0 || _storyIndex >= list.length) return null;
    return list[_storyIndex];
  }

  String get _storyKey {
    final story = _currentStory;
    if (story == null) return 'hold:${_owner.owner.ownerId}:$_storyIndex';
    return '${story.owner.ownerId}:${story.id}';
  }

  @override
  void initState() {
    super.initState();
    final last = widget.previews.isEmpty ? 0 : widget.previews.length - 1;
    _ownerIndex = widget.initialIndex.clamp(0, last);
    if (widget.previews.isNotEmpty) {
      _loadSelf();
      _loadOwner(_ownerIndex, autostart: true);
      _resolveOwner();
    }
  }

  Future<void> _loadSelf() async {
    final id = await TokenStorage.getActiveAccountId();
    if (!mounted) return;
    _selfId = id;
    await _push();
  }

  Map<String, Object?> _chrome() {
    final story = _currentStory;
    final media = story?.media;
    final ownerId = _owner.owner.ownerId;
    final loading = _loading[ownerId] ?? false;
    final video = media != null && media.isVideo && (media.url?.isNotEmpty ?? false);
    final photo = media != null && !video && (media.url?.isNotEmpty ?? false);
    final headers = <String, String>{};
    final rawUrl = media?.url;
    if (rawUrl != null && rawUrl.isNotEmpty) {
      final uri = Uri.tryParse(rawUrl);
      if (uri != null) {
        headers.addAll(
          videoRequestHeaders(uri, sessionUserAgent: api.session?.userAgent()),
        );
      }
    }
    final self = _selfId;
    final mine = self != null && self == ownerId;
    final reaction = story?.reaction;
    return {
      'key': _storyKey,
      'imageUrl': photo ? media.url : null,
      'videoUrl': video ? media.url : null,
      'thumbnailUrl': media?.thumbnailUrl,
      'preview': media?.previewData,
      'headers': headers,
      'name': _ownerName.isEmpty ? '…' : _ownerName,
      'timeLabel': story != null && story.time > 0
          ? storyTimeLabel(story.time, DateTime.now().millisecondsSinceEpoch)
          : '',
      'avatarUrl': _ownerAvatar,
      'count': _ownerStories.isEmpty ? 1 : _ownerStories.length,
      'index': _storyIndex,
      'loading': loading,
      'empty': story == null && !loading && _stories.containsKey(ownerId),
      'reaction': reaction != null && !reaction.isSticker ? reaction.id : '',
      'reactions': _reactions,
      'canReply': !mine && _owner.owner.isUser && self != null && story != null,
      'canReact': !mine && self != null && story != null,
      if (widget.origin != null) 'originX': widget.origin!.dx,
      if (widget.origin != null) 'originY': widget.origin!.dy,
    };
  }

  Future<void> _push() async {
    try {
      await _channel?.invokeMethod<void>('apply', _chrome());
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  void _created(int viewId) {
    final channel = MethodChannel('$_type/$viewId');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      final args = call.arguments is Map
          ? Map<String, Object?>.from(call.arguments as Map)
          : const <String, Object?>{};
      switch (call.method) {
        case 'dismiss':
          if (mounted) Navigator.of(context).pop();
        case 'advance':
        case 'ended':
          final key = args['key'] as String?;
          if (key == null || key == _storyKey) _advance();
        case 'rewind':
          _rewind();
        case 'nextOwner':
          return _nextOwner();
        case 'prevOwner':
          return _prevOwner();
        case 'reply':
          await _reply(args['text'] as String? ?? '');
        case 'react':
          await _react(args['emoji'] as String? ?? '');
      }
      return null;
    });
    _push();
  }

  Future<void> _loadOwner(int index, {bool autostart = false}) async {
    if (index < 0 || index >= widget.previews.length) return;
    final owner = widget.previews[index].owner;
    if (_stories.containsKey(owner.ownerId)) {
      if (autostart && index == _ownerIndex) {
        _startStory(_resumeIndex(index, _stories[owner.ownerId]!));
      }
      return;
    }
    _loading[owner.ownerId] = true;
    await _push();
    final stories = await storiesModule.getByOwner(owner);
    if (!mounted) return;
    _stories[owner.ownerId] = stories;
    _loading[owner.ownerId] = false;
    if (index != _ownerIndex) return;
    if (autostart) _startStory(_resumeIndex(index, stories));
  }

  int _resumeIndex(int index, List<Story> stories) {
    final preview = widget.previews[index];
    return storyResumeIndex(
      readCount: preview.readCount,
      storyIds: [for (final story in stories) story.id],
      savedId: storiesModule.lastViewedStoryId(preview.owner.ownerId),
    );
  }

  void _startStory(int index) {
    _storyIndex = index;
    final story = _currentStory;
    if (story != null) {
      _markViewed(story);
      storiesModule.setLastViewed(story.owner.ownerId, story.id);
    }
    _push();
  }

  void _markViewed(Story story) {
    if (story.id == 0 || _marked.contains(story.id)) return;
    _marked.add(story.id);
    storiesModule.mark(story.owner, story.id);
  }

  void _advance() {
    Haptics.selection();
    if (_storyIndex + 1 < _ownerStories.length) {
      _startStory(_storyIndex + 1);
      return;
    }
    storiesModule.clearLastViewed(_owner.owner.ownerId);
    _nextOwner();
  }

  void _rewind() {
    Haptics.selection();
    if (_storyIndex > 0) {
      _startStory(_storyIndex - 1);
      return;
    }
    _prevOwner();
  }

  bool _nextOwner() {
    if (_ownerIndex + 1 < widget.previews.length) {
      _showOwner(_ownerIndex + 1);
      return true;
    }
    if (mounted) Navigator.of(context).pop();
    return false;
  }

  bool _prevOwner() {
    if (_ownerIndex <= 0) return false;
    _showOwner(_ownerIndex - 1);
    return true;
  }

  void _showOwner(int index) {
    _ownerIndex = index;
    _storyIndex = 0;
    _resolveOwner();
    _loadOwner(index, autostart: true);
  }

  Future<void> _resolveOwner() async {
    final owner = _owner.owner;
    final override = widget.ownerOverrides[owner.ownerId];
    if (override != null) {
      _ownerName = override.name;
      _ownerAvatar = override.avatarUrl;
      await _push();
      return;
    }
    final peeked = peekStoryOwnerInfo(owner);
    _ownerName = peeked?.name ?? '';
    _ownerAvatar = peeked?.avatarUrl;
    await _push();
    final fetched = await fetchStoryOwnerInfo(owner);
    if (!mounted || _owner.owner != owner || fetched == null) return;
    _ownerName = fetched.name;
    _ownerAvatar = fetched.avatarUrl;
    await _push();
  }

  Future<void> _reply(String text) async {
    final trimmed = text.trim();
    final story = _currentStory;
    if (_replying || trimmed.isEmpty || story == null || !story.owner.isUser) {
      return;
    }
    final accountId = _selfId ?? await TokenStorage.getActiveAccountId();
    if (accountId == null || accountId == story.owner.ownerId) return;
    _replying = true;
    try {
      final existing = await AppDatabase.findDialogChatByParticipant(
        accountId,
        story.owner.ownerId,
      );
      final chatId = existing ?? (accountId ^ story.owner.ownerId);
      await messagesModule.sendMessage(accountId, chatId, trimmed);
      if (!mounted) return;
      showCustomNotification(context, 'Ответ отправлен');
    } catch (error) {
      if (!mounted) return;
      showCustomNotification(context, error.toString());
    } finally {
      _replying = false;
    }
  }

  Future<void> _react(String emoji) async {
    final story = _currentStory;
    if (story == null || emoji.isEmpty) return;
    final current = story.reaction;
    if (current != null && !current.isSticker && current.id == emoji) return;
    final reaction = StoryReaction(id: emoji);
    final ok = await storiesModule.react(story.owner, story.id, reaction);
    if (!mounted) return;
    if (!ok) {
      showCustomNotification(context, 'Не удалось поставить реакцию');
      return;
    }
    final list = _stories[story.owner.ownerId];
    if (list != null) {
      final index = list.indexWhere((item) => item.id == story.id);
      if (index >= 0) list[index] = list[index].copyWith(reaction: reaction);
    }
    await _push();
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: widget.previews.isEmpty
          ? const SizedBox.expand()
          : SizedBox.expand(
              child: UiKitView(
                viewType: _type,
                creationParams: _chrome(),
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: _created,
              ),
            ),
    );
  }
}
