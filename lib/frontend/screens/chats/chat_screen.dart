import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:komet/backend/modules/chat_preview.dart';
import 'package:komet/backend/modules/chats.dart';
import 'package:komet/backend/modules/comments.dart';
import 'package:komet/backend/modules/upload_service.dart';
import 'package:komet/backend/modules/webapp.dart';
import 'package:komet/frontend/screens/webapp/open_mini_app.dart';
import 'package:komet/core/media/clipboard/clipboard_media.dart';
import 'package:komet/core/media/clipboard/pasted_attachment.dart';
import 'package:komet/frontend/widgets/paste_media_toolbar.dart';
import 'package:komet/core/media/gallery_source.dart';
import 'package:komet/core/utils/format.dart';
import 'package:komet/frontend/screens/chats/chat_info_screen.dart';
import 'package:komet/frontend/screens/contacts/open_contact_profile.dart';
import 'package:komet/frontend/screens/chats/chat_list_screen.dart';
import 'package:komet/frontend/screens/chats/poll_create_screen.dart';
import 'package:komet/frontend/widgets/custom_notification.dart';
import 'package:komet/frontend/widgets/chat_menu_overlay.dart';
import '../../../main.dart';
import '../../../l10n/app_localizations.dart';
import '../../../backend/api.dart';
import '../../../backend/modules/messages.dart';
import '../../../backend/modules/contacts.dart';
import '../../../models/animoji.dart';
import '../../../backend/modules/complaints.dart';
import '../../../core/calls/call_controller.dart';
import '../../../core/media/tlottie/tlottie.dart';
import '../calls/call_screen.dart';
import '../../../core/protocol/opcode_map.dart';
import '../../../core/protocol/packet.dart';
import '../../../core/push/notification_bridge.dart';
import '../../../core/push/push_service.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/chat_activity_store.dart';
import '../../../core/storage/chat_members_store.dart';
import '../../../core/crypto/chat_crypto_service.dart';
import '../../../core/crypto/e2ee_service.dart';
import '../../../core/crypto/message_decryption_cache.dart';
import '../../../core/storage/chat_encryption_store.dart';
import '../../../core/storage/chat_wallpaper_store.dart';
import '../../../core/storage/draft_store.dart';
import '../../../core/storage/archived_chats_store.dart';
import '../../../core/cache/info_cache.dart';
import '../../../core/links/message_link_token.dart';
import '../../../core/cache/message_session_cache.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/emoji_keyword_index.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/route_settle.dart';
import '../../../core/config/app_cache_extent.dart';
import '../../../core/config/app_swipe_back_desktop.dart';
import 'chat/chat_prank_controller.dart';
import 'chat/chat_controller.dart';
import 'chat/read_marker_gate.dart';
import 'chat/chat_scroll_navigator.dart';
import 'chat/view/anchored_message_list.dart';
import 'chat/voice_record_controller.dart';
import 'chat/video_note_controller.dart';
import 'chat/command_panel_controller.dart';
import 'chat/sticker_panel_controller.dart';
import 'chat/chat_search_controller.dart';
import 'chat/message_search_result.dart';
import 'chat/typing_label.dart';
import 'chat/upload_status.dart';
import 'chat/mention_panel_controller.dart';
import 'chat/chat_media_send_controller.dart';
import 'chat/chat_text_send_controller.dart';
import 'chat/view/greeting_sticker_card.dart';
import 'chat/view/message_list_decorations.dart';
import 'chat/view/message_row_widgets.dart';
import 'chat/view/scroll_down_button.dart';
import 'chat/view/throttled_message_scrollbar.dart';
import 'chat/view/chat_app_bar.dart';
import 'chat/view/composer_area.dart';
import 'chat/view/chat_body_layout.dart';
import 'chat/view/shimmer_loading.dart';
import '../../../core/config/app_ios_glass.dart';
import '../../../core/config/app_message_actions_style.dart';
import '../../../core/native/native_chat_bridge.dart';
import '../../../core/native/native_chat_snapshot.dart';
import '../../../core/utils/link_opener.dart';
import '../../../core/utils/webview_support.dart';
import '../../widgets/glass/ios_glass.dart';
import '../../widgets/mesh_gradient_background.dart';
import '../../../core/config/app_visual_style.dart';
import '../../../core/config/app_chat_chrome.dart';
import 'package:komet/core/config/app_composer_background.dart';
import 'package:komet/core/config/app_composer_style.dart';
import '../../../core/config/komet_settings.dart';
import '../../../models/attachment.dart';
import '../../../models/contact_info.dart';
import '../../commands/commands.dart';
import '../../widgets/rich_message_controller.dart';
import '../../../core/utils/text_format.dart';
import '../../widgets/call_link_handler.dart';
import '../../widgets/connection_status.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/photo_viewer.dart';
import '../../native/native_chat_view.dart';
import '../../native/native_sticker_playback.dart';
import '../../widgets/message_actions_overlay.dart';
import '../../widgets/share_unopenable_file.dart';
import '../../widgets/text_entity_actions.dart';
import '../webapp/web_app_bridge.dart';
import '../webapp/web_app_screen.dart';
import '../../widgets/lottie_image.dart';
import '../../widgets/no_chat_access_card.dart';
import '../../widgets/attachment/attachment_sheet.dart';
import '../../widgets/attachment/paste_preview_sheet.dart';
import '../../widgets/sticker_pack_sheet.dart';
import '../../widgets/swipe_to_pop.dart';
import '../../widgets/swipe_route.dart';
import '../../widgets/reload_on_reconnect.dart';
import '../../widgets/schedule_time_picker.dart';
import '../../widgets/chat_wallpaper_sheet.dart';
import 'scheduled_messages_screen.dart';
import 'chat_encryption_screen.dart';
import 'e2ee_screen.dart';
import 'chat_wallpaper_preview_screen.dart';
import 'profile_action_sheets.dart';
import '../../../core/media/media_playback.dart';
import '../../../core/media/video_note_preloader.dart';
import '../../../core/media/voice_audio_controller.dart';
import '../../../core/utils/file_download.dart';
import '../../../core/config/app_shape.dart';
import '../../../core/security/app_lock.dart';
import '../../widgets/glass/ios_sheet.dart';
import '../../widgets/glass/ios_route.dart';
import '../../widgets/glass/glass_controls.dart';
import '../../widgets/glass/ios_symbols.dart';

class _DateSeparatorItem {
  final DateTime date;
  final GlobalKey key;
  _DateSeparatorItem(this.date, this.key);
}

class _MessageItem {
  final CachedMessage message;
  final int index;
  const _MessageItem(this.message, this.index);
}

class _UnreadSeparatorItem {
  const _UnreadSeparatorItem();
}

class ReplyRequest {
  final int sourceChatId;
  final CachedMessage message;

  const ReplyRequest({required this.sourceChatId, required this.message});
}

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String name;
  final String imageUrl;
  final String chatType;
  final bool? channelSubscribed;
  final bool embedded;
  final bool preview;
  final VoidCallback? onClose;
  final ForwardRequest? forwardRequest;
  final ReplyRequest? replyRequest;
  final String? initialMessageId;
  final int? initialMessageTime;
  final String? commentPostId;
  final CachedMessage? postMessage;
  final String? botStartPayload;
  final String? initialText;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.name,
    required this.imageUrl,
    required this.chatType,
    this.channelSubscribed,
    this.embedded = false,
    this.preview = false,
    this.onClose,
    this.forwardRequest,
    this.replyRequest,
    this.initialMessageId,
    this.initialMessageTime,
    this.commentPostId,
    this.postMessage,
    this.botStartPayload,
    this.initialText,
  });

  static final List<_ChatScreenState> _open = [];

  static bool revealOpenChat(int chatId) {
    for (final screen in _open.reversed) {
      if (screen.widget.chatId != chatId || !screen.mounted) continue;
      final route = ModalRoute.of(screen.context);
      if (route == null) return false;
      Navigator.of(screen.context).popUntil((r) => r == route);
      return true;
    }
    return false;
  }

  static bool startBotInVisibleChat(int chatId, String startPayload) {
    for (final screen in _open.reversed) {
      if (screen.widget.chatId != chatId) continue;
      if (!screen.mounted || !screen._isRouteCurrent) continue;
      unawaited(screen._sendBotStart(startPayload));
      return true;
    }
    return false;
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver, ReloadOnReconnect {
  final ValueNotifier<bool> _chatScrollActive = ValueNotifier<bool>(false);
  Timer? _chatScrollOpaqueHold;

  final RichMessageController _messageController = RichMessageController();
  final FocusNode _messageFocusNode = FocusNode();
  double _keyboardReserve = 0;
  bool _keyboardWasOpen = false;
  bool _keyboardBeforeStickers = false;
  final ScrollController _scrollController = ScrollController();
  bool _userDidScroll = false;
  int? _unreadAnchorTime;
  bool _awaitingPosition = false;
  bool _initialPositionDone = false;
  bool _positioningInFlight = false;
  int _historyAutoloadSuppressCount = 0;
  bool get _historyAutoloadSuppressed => _historyAutoloadSuppressCount > 0;
  int _readMarkTime = 0;
  late final ReadMarkerGate _readMarker = ReadMarkerGate(
    onFlush: _updateReadMarker,
  );
  final GlobalKey _listKey = GlobalKey();
  final GlobalKey _unreadSeparatorKey = GlobalKey();
  final Object _profileHeroTag = UniqueKey();
  final ValueNotifier<bool> _hasText = ValueNotifier(false);
  SlashCommand? _selectedCommand;
  bool _commandExecuting = false;
  Map<String, TextEditingController> _commandArgumentControllers = {};
  Map<String, FocusNode> _commandArgumentFocusNodes = {};
  bool _isLoading = true;
  bool _encryptionEnabled = false;
  final ValueNotifier<bool> _showAttachmentPanel = ValueNotifier(false);
  bool _pastePending = false;
  late final StickerPanelController _stickers;
  final ValueNotifier<UploadStatus> _uploadStatus = ValueNotifier(
    const UploadStatus(),
  );
  late final ChatMediaSendController _mediaSend;
  StreamSubscription<Packet>? _pushSub;
  StreamSubscription<MessageEvent>? _messageEventSub;
  StreamSubscription<Map<String, CommentsInfo>>? _commentsInfoSub;
  StreamSubscription<CommentAddedEvent>? _commentSub;
  final Map<String, int> _commentCounts = {};
  final Set<String> _commentCountsRequested = {};
  bool get _commentsMode => widget.commentPostId != null;
  bool _commentsLoadingMore = false;
  bool _commentsHasMore = true;
  StreamSubscription<SessionState>? _connSub;
  final Map<String, ValueNotifier<Map<String, dynamic>?>> _reactionNotifiers =
      {};
  final ValueNotifier<ReactionAnimationEvent?> _reactionAnimation =
      ValueNotifier(null);
  int _reactionAnimationToken = 0;
  final ValueNotifier<int> _scheduledCount = ValueNotifier(0);

  late final VoiceRecordController _voiceRec = VoiceRecordController(
    contextOf: () => context,
    isMounted: () => mounted,
    myId: () => _myId,
    onRecorded: _mediaSend.sendVoice,
  );

  late final VideoNoteController _note = VideoNoteController(
    contextOf: () => context,
    isMounted: () => mounted,
    onRecorded: _mediaSend.sendVideoNote,
    formatElapsed: formatVoiceElapsed,
    bottomInset: () => _composerHeight.value,
  );

  StreamSubscription<UploadJobEvent>? _uploadEventSub;

  ValueListenable<List<double>>? _photoProgressFor(CachedMessage m) =>
      UploadService.instance.progressFor(m.id);

  ValueNotifier<Map<String, dynamic>?> _reactionNotifierFor(CachedMessage m) {
    final existing = _reactionNotifiers[m.id];
    if (existing != null) return existing;
    final info = m.payload?['reactionInfo'];
    final notifier = ValueNotifier<Map<String, dynamic>?>(
      info is Map ? Map<String, dynamic>.from(info) : null,
    );
    _reactionNotifiers[m.id] = notifier;
    return notifier;
  }

  void _reactToMessage(CachedMessage message, String emoji) {
    if (message.isControl || message.id.startsWith('temp_')) return;
    final notifier = _reactionNotifierFor(message);
    final previous = notifier.value;
    final applied = _applyLocalReaction(previous, emoji);
    notifier.value = applied;
    final isToggleOff = applied == null || applied['yourReaction'] == null;
    unawaited(_sendReaction(message, emoji, isToggleOff, previous));
  }

  Future<void> _sendReaction(
    CachedMessage message,
    String emoji,
    bool isToggleOff,
    Map<String, dynamic>? previous,
  ) async {
    ({bool ok, Map<String, dynamic>? info}) result;
    try {
      result = isToggleOff
          ? await messagesModule.cancelReaction(widget.chatId, message.id)
          : await messagesModule.setReaction(widget.chatId, message.id, emoji);
    } catch (_) {
      result = (ok: false, info: null);
    }
    if (!mounted) return;
    final notifier = _reactionNotifiers[message.id];
    if (notifier == null) return;
    if (!result.ok) {
      notifier.value = previous;
      Haptics.error();
      showCustomNotification(context, 'Не удалось обновить реакцию');
      return;
    }
    notifier.value = result.info;
    _applyReactionInfoToMessage(message.id, result.info);
    final appliedReaction = result.info?['yourReaction']?.toString();
    if (!isToggleOff &&
        appliedReaction != null &&
        EmojiKeywordIndex.normalize(appliedReaction) ==
            EmojiKeywordIndex.normalize(emoji)) {
      final event = ReactionAnimationEvent(
        messageId: message.id,
        emoji: appliedReaction,
        token: ++_reactionAnimationToken,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reactionAnimation.value = event;
      });
    }
  }

  void _applyReactionInfoToMessage(
    String messageId,
    Map<String, dynamic>? info,
  ) {
    final idx = _chatController.indexOfId(messageId);
    if (idx == -1) return;
    final payload = <String, dynamic>{...?_messages[idx].payload};
    if (info == null) {
      payload.remove('reactionInfo');
    } else {
      payload['reactionInfo'] = info;
    }
    _chatController.setMessageAt(idx, _messages[idx].copyWith(payload: payload));
    if (NativeChatBridge.isEligible) _bumpMessageRows();
  }

  Map<String, dynamic>? _applyLocalReaction(
    Map<String, dynamic>? current,
    String emoji,
  ) {
    final counters = <String, int>{};
    final order = <String>[];
    final rawCounters = current?['counters'];
    if (rawCounters is List) {
      for (final c in rawCounters) {
        if (c is! Map) continue;
        final r = c['reaction']?.toString();
        if (r == null || r.isEmpty) continue;
        final n = c['count'];
        counters[r] = n is int ? n : 0;
        order.add(r);
      }
    }

    void decrement(String key) {
      final next = (counters[key] ?? 1) - 1;
      if (next <= 0) {
        counters.remove(key);
        order.remove(key);
      } else {
        counters[key] = next;
      }
    }

    final prev = current?['yourReaction']?.toString();
    String? your;
    if (prev != null &&
        EmojiKeywordIndex.normalize(prev) ==
            EmojiKeywordIndex.normalize(emoji)) {
      decrement(prev);
      your = null;
    } else {
      if (prev != null && prev.isNotEmpty) decrement(prev);
      if (!counters.containsKey(emoji)) order.add(emoji);
      counters[emoji] = (counters[emoji] ?? 0) + 1;
      your = emoji;
    }

    if (counters.isEmpty) return null;
    final total = counters.values.fold<int>(0, (a, b) => a + b);
    return {
      'counters': [
        for (final key in order) {'reaction': key, 'count': counters[key]},
      ],
      'yourReaction': ?your,
      'totalCount': total,
    };
  }

  void _pruneReactionNotifiers() {
    final liveIds = _messages.map((m) => m.id).toSet();
    final dead = _reactionNotifiers.keys
        .where((id) => !liveIds.contains(id))
        .toList();
    for (final id in dead) {
      _reactionNotifiers.remove(id)?.dispose();
    }
    _messageKeys.removeWhere((id, _) => !liveIds.contains(id));
    _rowCache.removeWhere((id, _) => !liveIds.contains(id));
  }

  int _otherStatus = 0;
  int? _otherSeenTime;

  final ValueNotifier<CachedMessage?> _replyTo = ValueNotifier(null);
  final ValueNotifier<List<CachedMessage>> _pendingForwards = ValueNotifier(
    const [],
  );
  static const bool _crossChatReplySupported = false;
  late final ChatTextSendController _textSend;

  late final RouteSettle _routeSettle = RouteSettle(isMounted: () => mounted);
  final bool _iosFastPath = AppIosGlass.active.value;

  late final ChatSearchController _search;
  late final AnimationController _searchAnim;
  final FocusNode _searchFocusNode = FocusNode();

  late final ChatPrankController _prank = ChatPrankController(
    vsync: this,
    contextOf: () => context,
    isMounted: () => mounted,
    onChanged: () {
      if (mounted) setState(() {});
    },
  );
  final ValueNotifier<String> _headerStatusNotifier = ValueNotifier('');
  final ValueNotifier<int> _otherReadTime = ValueNotifier(0);
  late final AnimationController _attachAnim;
  late final CommandPanelController _commandPanel;
  late final MentionPanelController _mentionPanel;

  late AnimationController _shimmerController;
  Timer? _shimmerStartTimer;
  bool _previewChat = false;
  bool _subscribing = false;
  String? _channelLink;
  final ChatController _chatController = ChatController();
  late final ChatScrollNavigator _scrollNav;

  List<CachedMessage> get _messages => _chatController.messages;
  set _messages(List<CachedMessage> v) => _chatController.messages = v;
  ValueNotifier<int> get _messagesRev => _chatController.messagesRev;
  bool get _historyKickedOff => _chatController.historyKickedOff;
  set _historyKickedOff(bool v) => _chatController.historyKickedOff = v;

  final GlobalKey _messageListKey = GlobalKey();
  _ChatMessageList? _messageListWidget;
  final NativeChatCommands _nativeChatCommands = NativeChatCommands();
  late final NativeStickerPlayback _nativeStickers = NativeStickerPlayback(
    onFrame: (id, bytes, width, height) {
      unawaited(_nativeChatCommands.stickerFrame(id, bytes, width, height));
    },
  );
  final Map<String, VoiceAudioController> _nativeVoices = {};
  final Map<String, String> _notePaths = {};
  final Set<String> _noteLoads = {};
  final Set<String> _noteMisses = {};
  double _nativeVoiceProgress = 0;
  String? _nativeVoiceId;
  bool _nativeVoicePlaying = false;
  final Set<String> _deletingIds = {};

  static const double _avgMessageHeight = 72.0;
  static const double _historyPrefetchExtent = _avgMessageHeight * 8;
  static const double _pinnedBannerLift = 6.0;
  static const double _iosPinnedBannerGap = 6.0;
  static const double _unreadSeparatorHeight = 30.0;
  static const double _unreadSeparatorInset = 72.0;
  static const double _unreadAnchorFallbackAlignment = 0.3;

  final BackdropKey _barBackdrop = BackdropKey();
  final BackdropKey _pillBackdrop = BackdropKey();
  bool get _isLoadingMore => _chatController.isLoadingMore;
  set _isLoadingMore(bool v) => _chatController.isLoadingMore = v;
  bool get _hasMoreHistory => _chatController.hasMoreHistory;
  set _hasMoreHistory(bool v) => _chatController.hasMoreHistory = v;
  List<Object>? _combinedItemsCache;
  int? _combinedItemsKey;
  bool _floatingDateScheduled = false;
  int get _myId => _chatController.myId;
  set _myId(int v) => _chatController.myId = v;
  CachedChat? chat;
  bool _peerIsBot = false;
  bool _peerKindKnown = false;
  bool _greetingMounted = false;
  bool _botStartRequested = false;
  ChatWallpaper? _wallpaper;

  bool get _composerFrosted =>
      ComposerMaterial.effective != ComposerBackground.standard;

  bool get _composerUnderlap =>
      AppChatChrome.current.value != ChatChromeStyle.color || _composerFrosted;

  bool get _materialComposer =>
      !ComposerChrome.isGlossy(ComposerChrome.effective);

  bool get _composerPaintsSurface {
    if (!_commentsMode &&
        widget.chatType == 'CHANNEL' &&
        _pendingForwards.value.isEmpty) {
      return false;
    }
    return _materialComposer && !_composerFrosted;
  }

  bool get _glossyChrome =>
      AppIosGlass.active.value || AppVisualStyle.current.value.glossyChrome;

  bool get _searchInBottomBar {
    if (!AppIosGlass.active.value || _pendingForwards.value.isNotEmpty) {
      return false;
    }
    final isChannel = widget.chatType == 'CHANNEL';
    final isGroup = widget.chatType == 'CHAT' || widget.chatType == 'GROUP';
    if ((isChannel || isGroup) && _previewChat) return true;
    return isChannel && !(chat?.iAmAdmin(_myId) ?? false);
  }

  bool get _liquidChrome =>
      !AppIosGlass.active.value &&
      AppVisualStyle.current.value.glossyChrome &&
      ChatChromeMaterial.isLiquid(AppChatChrome.current.value);

  ChatChromeStyle get _effectiveChrome {
    if (AppIosGlass.active.value) return ChatChromeStyle.transparent;
    final chrome = AppChatChrome.current.value;
    if (chrome == ChatChromeStyle.liquidGlass) {
      return ChatChromeStyle.transparent;
    }
    return chrome;
  }

  bool get _chromeVignette =>
      _effectiveChrome == ChatChromeStyle.none && _wallpaper == null;

  final ValueNotifier<double> _composerHeight = ValueNotifier(96);
  final ValueNotifier<double> _pinnedBannerHeight = ValueNotifier(0);

  final ValueNotifier<DateTime?> _floatingDate = ValueNotifier(null);
  Timer? _floatingDateTimer;
  late final AnimationController _floatingDateAnimController;
  late final CurvedAnimation _floatingDateCurved;
  late final AnimationController _scrollDownAnimController;
  late final CurvedAnimation _scrollDownCurved;
  final Set<String> _deferredIds = <String>{};
  final Map<int, GlobalKey> _separatorKeys = {};
  String? _lastSentId;
  final ValueNotifier<int> _otherUnread = ValueNotifier(0);
  final ValueNotifier<bool> _animojiHold = ValueNotifier(true);

  final ValueNotifier<Set<String>> _selectedIds = ValueNotifier(const {});
  final ValueNotifier<Offset?> _textSelectionDrag = ValueNotifier(null);
  final ValueNotifier<({String id, Offset pos})?> _textSelection =
      ValueNotifier(null);
  late final AnimationController _selectionAnim;

  bool get _selectionMode => _selectedIds.value.isNotEmpty;

  void _prewarmQuickReactions() {
    if (!mounted || !TlottieEngine.instance.available) return;
    final dpr = (MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0).clamp(
      1.0,
      2.0,
    );
    final px = ((44.0 * dpr).clamp(96.0, 512.0) / 32).ceil() * 32;
    for (final a in animojiModule.quickAnimojis) {
      for (final url in [a.lottieUrl, a.lottiePlayUrl]) {
        if (url != null && url.isNotEmpty) {
          unawaited(TlottieEngine.instance.prewarm(url, px));
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _previewChat = widget.channelSubscribed == false;
    _chatController.chatId = widget.chatId;
    _chatController.isMounted = () => mounted;
    _chatController.appendedCount.addListener(MeshGradientPulse.pulse);
    _mediaSend = ChatMediaSendController(
      chatController: _chatController,
      showAttachmentPanel: _showAttachmentPanel,
      uploadStatus: _uploadStatus,
      bumpMessages: _bumpMessages,
      scrollToBottom: () => _scrollNav.scrollToBottom(),
      setLastSentId: (id) => _lastSentId = id,
      notify: (msg) {
        if (mounted) showCustomNotification(context, msg);
      },
      isMounted: () => mounted,
      encryptionEnabled: () => _encryptionEnabled,
      encryptOutgoing: _encryptOutgoing,
      markHasScheduled: _markHasScheduled,
    );
    if (!_commentsMode && !widget.preview) ChatScreen._open.add(this);
    if (!widget.preview) {
      unawaited(PushService.clearChatNotification(widget.chatId));
    }
    if (!_commentsMode && !widget.preview) {
      unawaited(NotificationBridge.instance.pushActiveChat(widget.chatId));
    }
    unawaited(
      animojiModule
          .ensureLoaded()
          .then((_) {
            _prewarmQuickReactions();
            if (!mounted) return;
            if (_iosFastPath) {
              _routeSettle.run(_bumpMessages);
            } else {
              _bumpMessages();
            }
          })
          .catchError((_) {}),
    );
    WidgetsBinding.instance.addObserver(this);
    _uploadEventSub = UploadService.instance.events.listen(
      _mediaSend.onUploadEvent,
    );
    _mediaSend.syncUploadStatus();
    chats.chatsChanged.addListener(_onChatsBump);
    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(_onScrollForDate);
    _scrollController.addListener(_maybeLoadMoreHistory);
    _scrollController.addListener(_recordScrollPixels);
    _scrollController.addListener(_scheduleReadMarker);
    if (!widget.preview) MediaPlayback.instance.enterChat(widget.chatId);
    AppVisualStyle.current.addListener(_onVisualStyleChanged);
    AppIosGlass.active.addListener(_onVisualStyleChanged);
    AppChatChrome.current.addListener(_onVisualStyleChanged);
    AppComposerStyle.current.addListener(_onVisualStyleChanged);
    AppComposerBackground.current.addListener(_onVisualStyleChanged);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _attachAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _stickers = StickerPanelController(
      vsync: this,
      onSendTyping: () => messagesModule.sendTyping(widget.chatId, 'STICKER'),
    );
    _showAttachmentPanel.addListener(_onAttachPanelToggle);
    _commandPanel = CommandPanelController(
      vsync: this,
      textOf: () => _messageController.text,
      onSelected: _onCommandSelected,
    );
    _mentionPanel = MentionPanelController(
      vsync: this,
      chatId: widget.chatId,
      enabled: _mentionsAvailable,
      selfId: () => _myId,
      valueOf: () => _messageController.value,
      onSelected: _onMentionSelected,
    );
    _selectionAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _searchAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _search = ChatSearchController(
      chatId: widget.chatId,
      isMounted: () => mounted,
    );
    _textSend = ChatTextSendController(
      chatController: _chatController,
      messageController: _messageController,
      hasText: _hasText,
      replyTo: _replyTo,
      pendingForwards: _pendingForwards,
      commentsMode: _commentsMode,
      commentPostId: widget.commentPostId,
      bumpMessages: _bumpMessages,
      scrollToBottom: () => _scrollNav.scrollToBottom(),
      focusComposer: _messageFocusNode.requestFocus,
      setLastSentId: (id) => _lastSentId = id,
      notify: (msg) {
        if (mounted) showCustomNotification(context, msg);
      },
      isMounted: () => mounted,
      contextOf: () => context,
      chatOf: () => chat,
      encryptOutgoing: _encryptOutgoing,
      executeCommand: _executeCommand,
      checkPrankTrigger: _prank.checkTrigger,
    );
    final incomingReply = widget.replyRequest;
    if (incomingReply != null) {
      _replyTo.value = incomingReply.message;
      _textSend.replySourceChatId =
          incomingReply.sourceChatId == widget.chatId
          ? null
          : incomingReply.sourceChatId;
    }
    final incomingForward = widget.forwardRequest;
    if (incomingForward != null) {
      _textSend.forwardRequest = incomingForward;
      _pendingForwards.value = incomingForward.messages;
    }
    _pushSub = api.pushStream
        .where(
          (p) =>
              p.opcode == Opcode.notifMark ||
              p.opcode == Opcode.notifTyping ||
              p.opcode == Opcode.notifMsgDelayed,
        )
        .listen(_onIncomingPush);
    _messageEventSub = chats.messageEvents
        .where((e) => e.chatId == widget.chatId)
        .listen(_onMessageEvent);
    if (_commentsMode) {
      _commentSub = commentsModule.commentStream
          .where(
            (e) =>
                e.chatId == widget.chatId && e.postId == widget.commentPostId,
          )
          .listen(_onLiveComment);
    } else if (widget.chatType == 'CHANNEL') {
      _commentsInfoSub = commentsModule.infoStream.listen(_onCommentsInfo);
    }
    ChatActivityStore.instance
        .listenable(widget.chatId)
        .addListener(_recomputeHeaderStatus);
    ChatMembersStore.instance
        .listenable(widget.chatId)
        .addListener(_recomputeHeaderStatus);
    _connSub = api.stateStream.listen((_) {
      if (mounted) _recomputeHeaderStatus();
    });
    debugForceOffline.addListener(_recomputeHeaderStatus);
    PresenceFetch.revision.addListener(_onPresenceChanged);
    ContactsModule.revision.addListener(_onContactsChanged);
    _floatingDateAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 380),
    );
    _floatingDateCurved = CurvedAnimation(
      parent: _floatingDateAnimController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _scrollDownAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scrollDownCurved = CurvedAnimation(
      parent: _scrollDownAnimController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _scrollNav = ChatScrollNavigator(
      scrollController: _scrollController,
      chatController: _chatController,
      shimmerController: _shimmerController,
      scrollDownAnimController: _scrollDownAnimController,
      readMarker: _readMarker,
      listKey: _listKey,
      existingKeyFor: (id) => _messageKeys[id],
      loadMessageWindow: _loadMessageWindow,
      resetToLatest: _resetToLatest,
      flushDeferredMessages: _flushDeferredMessages,
      isDeferred: (id) => _deferredIds.contains(id),
      hasDeferredMessages: () => _deferredIds.isNotEmpty,
      bumpMessages: _bumpMessages,
      isMounted: () => mounted,
      notifyState: setState,
      showNotification: (message) => showCustomNotification(context, message),
      initialMessageIdOf: () => widget.initialMessageId,
      initialMessageTimeOf: () => widget.initialMessageTime,
      onNavigated: _maybeLoadMoreHistory,
    );
    _scrollNav.nativeScrollToEnd = () {
      unawaited(_nativeChatCommands.scrollToEnd());
    };
    pollsModule.addListener(_onNativePolls);
    _scrollController.addListener(_scrollNav.updateScrollDownVisible);

    unawaited(_fastPreloadCache());
    if (_iosFastPath) {
      _routeSettle.run(() => unawaited(_loadParticipantsCount()));
    } else {
      unawaited(_loadParticipantsCount());
    }
    WidgetsBinding.instance.addPostFrameCallback(_onFirstFrameRendered);
  }

  @override
  void reloadAfterReconnect() {
    if (!_historyKickedOff) return;
    unawaited(_loadHistory());
    unawaited(_loadParticipantsCount());
  }

  Future<void> _loadParticipantsCount() async {
    if (_commentsMode) return;
    if (widget.chatType != 'CHAT' && widget.chatType != 'CHANNEL') return;
    final info = await chats.getChatInfo(api, widget.chatId);
    if (!mounted) return;
    if (widget.chatType == 'CHANNEL') {
      final link = info?['link'];
      if (link is String && link.isNotEmpty) _channelLink = link;
    }
  }

  Future<void> _loadPeerKind() async {
    if (widget.chatType != 'DIALOG' || _myId == 0) return;
    final peerId = widget.chatId ^ _myId;
    if (peerId <= 0) return;
    final cached = ContactInfoFetch.peek(peerId);
    if (cached != null) _applyPeerInfo(peerId, cached);
    final info = await ContactInfoFetch.get(peerId);
    if (info != null) _applyPeerInfo(peerId, info);
    if ((info ?? cached)?.isBot ?? false) {
      unawaited(BotInfoFetch.get(peerId));
    }
  }

  void _applyPeerInfo(int peerId, ContactInfo info) {
    if (!mounted) return;
    final avatar = info.avatarUrl;
    final avatarIsNew =
        avatar != null &&
        avatar.isNotEmpty &&
        ContactCache.getAvatar(peerId) != avatar;
    if (avatarIsNew) ContactCache.putAvatar(peerId, avatar);
    if (_peerKindKnown && _peerIsBot == info.isBot && !avatarIsNew) return;
    setState(() {
      _peerKindKnown = true;
      _peerIsBot = info.isBot;
    });
  }

  Future<void> _fastPreloadCache() async {
    final p = await AppDatabase.loadActiveProfile();
    if (!mounted) return;
    _myId = p?.id ?? 0;
    if (p != null && p.id != 0) {
      final myName = [
        p.firstName,
        p.lastName,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
      if (myName.isNotEmpty) ContactCache.put(p.id, myName);
      ContactCache.putAvatar(p.id, p.baseUrl);
    }
    if (_commentsMode) return;
    _restoreDraft();
    unawaited(_loadPeerKind());
    unawaited(_loadWallpaper());
    unawaited(_loadEncryption());
    if (_iosFastPath) {
      _routeSettle.run(() => unawaited(_refreshBadge()));
    } else {
      unawaited(_refreshBadge());
    }

    try {
      final chatRows = await chats.getChat(_myId, widget.chatId);
      if (!mounted) return;
      final inList = await AppDatabase.isChatInList(_myId, widget.chatId);
      if (!mounted) return;
      if (widget.chatType == 'CHANNEL') {
        final preview = !inList;
        if (preview != _previewChat) setState(() => _previewChat = preview);
      }
      if (chatRows.isNotEmpty) {
        setState(() {
          chat = chatRows.first;
        });
        _bumpMessages();
        _seedPresenceFromChat();
        _recomputeHeaderStatus();
        _syncOtherReadTime();
      }
    } catch (_) {}

    _resolveUnreadAnchor();

    final cached = MessageSessionCache.get(_myId, widget.chatId);
    if (cached != null && cached.messages.isNotEmpty) {
      setState(() {
        _messages = List<CachedMessage>.of(cached.messages);
        _deferredIds.clear();
        _hasMoreHistory = !cached.reachedStart;
        _messagesRev.value++;
      });
      _mediaSend.mergePendingMedia();
      _syncReactionNotifiersFromMessages();
      _requestCommentCounts();
      _revealOrHoldInitial();
      return;
    }

    if (_iosFastPath) {
      await _loadLocalHistoryFast();
      if (!mounted || _messages.isEmpty) return;
      _deferredIds.clear();
      _mediaSend.mergePendingMedia();
      _revealOrHoldInitial();
      return;
    }

    final firstRows = await AppDatabase.loadMessages(
      _myId,
      widget.chatId,
      limit: 20,
      onlyVisible: !KometSettings.viewDeleted.value,
    );
    final ranges = await AppDatabase.loadMessageRanges(_myId, widget.chatId);
    if (!mounted) return;
    final first = ranges.clipLatest(
      firstRows.reversed.map((r) => CachedMessage.fromDbRow(r)).toList(),
      (m) => m.time,
    );
    if (first.isNotEmpty) {
      setState(() {
        _messages = first;
        _deferredIds.clear();
        _messagesRev.value++;
      });
      _mediaSend.mergePendingMedia();
      _requestCommentCounts();
      _revealOrHoldInitial();
    }
  }

  void _resolveUnreadAnchor() {
    final c = chat;
    _readMarkTime = c?.participants[_myId] ?? 0;
    if (c == null || c.unreadCount <= 0) {
      _unreadAnchorTime = null;
    } else {
      final myMark = c.participants[_myId] ?? 0;
      _unreadAnchorTime = myMark > 0 ? myMark : null;
    }
    _awaitingPosition =
        c != null && c.unreadCount > 0 && widget.initialMessageId == null;
  }

  void _resolveCountBasedAnchor() {
    final c = chat;
    if (c == null || c.unreadCount <= 0 || _messages.isEmpty) return;
    final unread = c.unreadCount;
    if (_messages.length > unread) {
      _unreadAnchorTime = _messages[_messages.length - unread - 1].time;
    } else if (!_hasMoreHistory) {
      _unreadAnchorTime = _messages.first.time - 1;
    }
  }

  void _revealOrHoldInitial() {
    if (_awaitingPosition && !_canPositionNow()) return;
    setState(() {
      _isLoading = false;
      _onLoadingFinished();
    });
  }

  bool _canPositionNow() {
    if (_unreadAnchorTime == null) _resolveCountBasedAnchor();
    final ua = _unreadAnchorTime;
    if (ua == null) return false;
    final firstUnread = _messages.indexWhere((m) => m.time > ua);
    if (firstUnread == -1) return _newestMessageLoaded();
    return firstUnread > 0 || !_hasMoreHistory;
  }

  bool _newestMessageLoaded() {
    if (_messages.isEmpty) return false;
    final serverLast = chat?.lastMsgTime ?? 0;
    return _messages.last.time >= serverLast;
  }

  void _onFirstFrameRendered(Duration _) {
    if (!mounted) return;
    if (!_commentsMode && !_iosFastPath) unawaited(_loadLocalHistoryFast());
    if (widget.embedded) {
      _routeSettle.settleNow();
    } else {
      _routeSettle.bind(context);
    }
    _routeSettle.run(_kickoffHistory);
  }

  List<CachedMessage>? _fastLocalDecoded;
  Future<void>? _fastLocalLoad;
  bool _fastLocalStarted = false;

  // #***! читаем сообщения из локальной БД сразу, не дожидаясь конца
  // анимации перехода (её ждёт только сетевая часть в _loadHistory)
  Future<void> _loadLocalHistoryFast() {
    if (_fastLocalStarted) return _fastLocalLoad ?? Future.value();
    _fastLocalStarted = true;
    return _fastLocalLoad = _readLocalHistoryFast();
  }

  Future<void> _readLocalHistoryFast() async {
    if (_myId == 0) {
      final activeProfile = await AppDatabase.loadActiveProfile();
      if (!mounted) return;
      _myId = activeProfile?.id ?? 0;
    }
    if (!mounted) return;
    _fastLocalDecoded = await _chatController.loadLocalHistory(
      onApplyMerged: _applyMergedMessages,
    );
  }

  void _kickoffHistory() {
    _animojiHold.value = false;
    if (_historyKickedOff) return;
    _historyKickedOff = true;
    _shimmerStartTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted || !_isLoading) return;
      _shimmerController.repeat();
    });
    unawaited(_loadHistory().then((_) => _sendPendingBotStart()));
  }

  bool get _isRouteCurrent {
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    return route == null || route.isCurrent;
  }

  Future<void> _sendPendingBotStart() async {
    final payload = widget.botStartPayload;
    if (payload == null || _botStartRequested || !mounted) return;
    _botStartRequested = true;
    await _sendBotStart(payload);
  }

  Future<void> _sendBotStart(String startPayload) async {
    if (_myId == 0) {
      final profile = await AppDatabase.loadActiveProfile();
      if (!mounted) return;
      _myId = profile?.id ?? 0;
    }
    try {
      final sent = await messagesModule.sendBotStart(
        widget.chatId,
        startPayload,
      );
      if (!mounted) return;
      if (sent == null) {
        showCustomNotification(context, 'Не удалось запустить бота');
        return;
      }
      await _chatController.persistOutgoing(
        CachedMessage.fromPushPayload(_myId, widget.chatId, sent),
      );
    } catch (_) {
      if (mounted) showCustomNotification(context, 'Не удалось запустить бота');
    }
  }

  void _onLoadingFinished() {
    _shimmerStartTimer?.cancel();
    _shimmerStartTimer = null;
    _applyInitialPositioning();
  }

  void _recordScrollPixels() {
    if (!_scrollController.hasClients) return;
    if (_initialPositionDone &&
        _scrollController.position.userScrollDirection !=
            ScrollDirection.idle) {
      _userDidScroll = true;
    }
  }

  double _unreadAnchorAlignment() {
    final listBox = _listKey.currentContext?.findRenderObject();
    if (listBox is! RenderBox || listBox.size.height <= 0) {
      return _unreadAnchorFallbackAlignment;
    }
    final separator =
        _unreadSeparatorKey.currentContext?.size?.height ??
        _unreadSeparatorHeight;
    final glossy = _glossyChrome;
    final chromeBottom = _effectiveChrome == ChatChromeStyle.color
        ? 0.0
        : MediaQuery.paddingOf(context).top +
              ChatAppBar.headerHeight(
                glossy: glossy,
                ios: AppIosGlass.active.value,
              ) +
              _pinnedBannerHeight.value;
    final desiredTop = chromeBottom + separator + _unreadSeparatorInset;
    return (desiredTop / listBox.size.height).clamp(0.0, 0.5);
  }

  void _positionToMessage(String messageId) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _scrollNav.positionAt(messageId, _unreadAnchorAlignment());
      if (mounted) setState(_markPositioned);
    });
  }

  void _applyInitialPositioning() {
    if (_initialPositionDone) {
      if (_shimmerController.isAnimating) _shimmerController.stop();
      _scheduleReadMarker();
      return;
    }
    if (_positioningInFlight) return;
    if (_commentsMode) {
      _initialPositionDone = true;
      _markPositioned();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
      return;
    }
    if (_messages.isEmpty) {
      if (!_hasMoreHistory) _markPositioned();
      return;
    }
    if (widget.initialMessageId != null) {
      _markPositioned();
      return;
    }

    final c = chat;
    if (c != null && c.unreadCount > 0) {
      if (_unreadAnchorTime == null) _resolveCountBasedAnchor();
      final ua = _unreadAnchorTime;
      if (ua == null) {
        if (_hasMoreHistory) {
          _positioningInFlight = true;
          unawaited(_loadUntilUnreadReady());
        } else {
          _markPositioned();
        }
        return;
      }
      final firstUnread = _messages.indexWhere((m) => m.time > ua);
      if (firstUnread == -1) {
        _markPositioned();
        return;
      }
      if (firstUnread > 0 || !_hasMoreHistory) {
        _initialPositionDone = true;
        _positionToMessage(_messages[firstUnread].id);
      } else {
        _positioningInFlight = true;
        unawaited(_loadUntilUnreadReady());
      }
      return;
    }

    _markPositioned();
  }

  void _markPositioned() {
    _positioningInFlight = false;
    _initialPositionDone = true;
    _awaitingPosition = false;
    _isLoading = false;
    if (_shimmerController.isAnimating) _shimmerController.stop();
    _scheduleReadMarker();
    _scrollNav.maybeRunInitialTarget();
  }

  void _openChatInfo({ChatInfoTab? initialTab}) {
    final navigator = Navigator.of(context);
    final chatRoute = ModalRoute.of(context);
    navigator.push(
      iosPageRoute(context,
        builder: (_) => ChatInfoScreen(
          chatId: widget.chatId,
          name: _headerName(),
          imageUrl: _headerAvatarUrl(),
          chatType: widget.chatType,
          heroTag: _profileHeroTag,
          initialTab: initialTab,
          openedFromChat: true,
          onJumpToMessage: (chatRoute == null || widget.embedded)
              ? null
              : (messageId, time) {
                  navigator.popUntil((r) => r == chatRoute);
                  _requestGoToMessage(messageId, time);
                },
        ),
      ),
    );
  }

  late final PhotoViewerActions _photoActions = PhotoViewerActions(
    goToMessage: _requestGoToMessage,
    forward: _forwardMessageById,
    delete: (messageId, senderId) =>
        _confirmDeleteMessage(messageId, senderId == _myId),
    viewAllMedia: () => _openChatInfo(initialTab: ChatInfoTab.media),
  );

  void _forwardMessageById(String messageId) {
    final message = _chatController.byId(messageId);
    if (message == null) {
      showCustomNotification(context, 'Сообщение не загружено');
      return;
    }
    unawaited(_forwardMessages([message]));
  }

  void _requestGoToMessage(String id, int time) {
    _scrollNav.requestGoToMessage(id, time);
  }

  Future<void> _loadUntilUnreadReady() async {
    await _walkHistoryBack(
      reached: () {
        if (_unreadAnchorTime == null) _resolveCountBasedAnchor();
        final ua = _unreadAnchorTime;
        return ua != null && _messages.indexWhere((m) => m.time > ua) > 0;
      },
      maxPages: 15,
    );
    if (!mounted) return;
    if (_unreadAnchorTime == null) _resolveCountBasedAnchor();
    final ua = _unreadAnchorTime;
    final idx = ua == null ? -1 : _messages.indexWhere((m) => m.time > ua);
    _positioningInFlight = false;
    _initialPositionDone = true;
    if (idx >= 0) {
      _positionToMessage(_messages[idx].id);
    } else {
      setState(_markPositioned);
    }
  }

  void _scheduleReadMarker() => _readMarker.schedule();

  void _holdReadMarker() => _readMarker.hold();

  void _releaseReadMarker() => _readMarker.release();

  void _updateReadMarker() {
    if (_commentsMode || widget.preview) return;
    if (!mounted || _myId == 0 || _messages.isEmpty) return;
    if (_awaitingPosition || !_initialPositionDone) return;
    if (_readMarker.held) return;
    if (!_scrollController.hasClients) return;
    final listBox = _listKey.currentContext?.findRenderObject();
    if (listBox is! RenderBox) return;
    final viewportBottom = listBox.size.height;
    if (viewportBottom <= 0) return;

    CachedMessage? candidate;
    int topIndex = -1;
    for (int i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      final ctx = _messageKeys[m.id]?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final top = box.localToGlobal(Offset.zero, ancestor: listBox).dy;
      final bottom = top + box.size.height;
      if (bottom <= 0 || top >= viewportBottom) continue;
      candidate ??= m;
      topIndex = i;
    }
    if (candidate == null) return;

    final atBottom = candidate.id == _messages.last.id;

    if (_unreadAnchorTime != null &&
        _userDidScroll &&
        _unreadSeparatorScrolledPast(
          atBottom,
          topIndex,
          listBox,
          viewportBottom,
        )) {
      _unreadAnchorTime = null;
      _bumpMessages();
    }

    if (candidate.time <= _readMarkTime) return;
    _readMarkTime = candidate.time;
    var remaining = _messages
        .where((m) => m.time > _readMarkTime && m.senderId != _myId)
        .length;
    if (_chatController.hasNewer) {
      remaining = math.max(remaining, chat?.unreadCount ?? 0);
    }
    unawaited(
      chats.markReadUpTo(
        api,
        _myId,
        widget.chatId,
        candidate.id,
        candidate.time,
        remaining: remaining,
      ),
    );
  }

  bool _unreadSeparatorScrolledPast(
    bool atBottom,
    int topIndex,
    RenderBox listBox,
    double viewportBottom,
  ) {
    if (atBottom) return true;
    final ua = _unreadAnchorTime;
    if (ua == null) return false;
    final firstUnread = _messages.indexWhere((m) => m.time > ua);
    if (firstUnread == -1) return true;
    if (topIndex >= 0 && topIndex > firstUnread) return true;
    final box = _messageKeys[_messages[firstUnread].id]?.currentContext
        ?.findRenderObject();
    if (box is RenderBox && box.attached) {
      final top = box.localToGlobal(Offset.zero, ancestor: listBox).dy;
      if (top <= 0) return true;
    }
    return false;
  }

  Future<void> _markMessageUnread(CachedMessage message) async {
    final unread = await chats.markUnread(
      api,
      _myId,
      widget.chatId,
      message.time,
    );
    if (!mounted) return;
    if (unread == null) {
      showCustomNotification(context, 'Не удалось пометить непрочитанным');
      return;
    }
    _leaveChat();
  }

  void _leaveChat() {
    if (widget.embedded) {
      widget.onClose?.call();
    } else {
      Navigator.of(context).pop();
    }
  }

  bool _canShowReadBy(CachedMessage message) {
    if (message.isControl || message.deleted) return false;
    if (int.tryParse(message.id) == null) return false;
    final type = chat?.type ?? widget.chatType;
    return type == 'CHAT' || type == 'GROUP';
  }

  Future<List<MessageReader>> _loadReadBy(CachedMessage message) async {
    final marks = await chats.getReadMarks(api, _myId, widget.chatId);
    final reactions = await messagesModule.getDetailedReactions(
      widget.chatId,
      message.id,
    );

    final readerIds = <int>{
      ...marks.entries.where((e) => e.value >= message.time).map((e) => e.key),
      ...reactions.keys,
    }..removeAll({_myId, message.senderId});
    if (readerIds.isEmpty || !mounted) return const [];

    await messagesModule.ensureContactNames(readerIds);
    await animojiModule.ensureLoaded();
    if (!mounted) return const [];

    final animojiByEmoji = {
      for (final animoji in animojiModule.animojis)
        EmojiKeywordIndex.normalize(animoji.emoji): animoji,
    };
    final unknownName = AppLocalizations.of(
      context,
    )!.msgActionsReadByUnknownUser;

    final readers = readerIds.map((id) {
      final emoji = reactions[id];
      final animoji = emoji == null
          ? null
          : animojiByEmoji[EmojiKeywordIndex.normalize(emoji)];
      final name = ContactCache.get(id);
      return MessageReader(
        id: id,
        name: name == null || name.isEmpty ? unknownName : name,
        avatarUrl: ContactCache.getAvatar(id),
        reaction: emoji == null
            ? null
            : ReactionEmoji(
                emoji: emoji,
                animationUrl: animoji?.lottieUrl,
                staticUrl: animoji?.iconUrl,
              ),
      );
    }).toList();

    readers.sort((a, b) {
      final aReacted = a.reaction != null;
      final bReacted = b.reaction != null;
      if (aReacted != bReacted) return aReacted ? -1 : 1;
      return (marks[b.id] ?? 0).compareTo(marks[a.id] ?? 0);
    });
    return readers;
  }

  bool _canLinkMessage(CachedMessage message) {
    if (_commentsMode || message.isControl) return false;
    final type = chat?.type ?? widget.chatType;
    if (type != 'CHAT' && type != 'GROUP' && type != 'CHANNEL') return false;
    return MessageLinkToken.encode(message.id) != null;
  }

  Future<void> _copyMessageLink(CachedMessage message) async {
    final url = MessageLinkToken.messageUrl(
      chatId: widget.chatId,
      messageId: message.id,
      publicLink: chat?.publicLink,
    );
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    showCustomNotification(
      context,
      AppLocalizations.of(context)!.sharedLinkCopied,
    );
  }

  bool _canPinMessage(CachedMessage message) {
    if (message.isControl) return false;
    if (int.tryParse(message.id) == null) return false;
    return chat?.canPinMessages(_myId) ?? false;
  }

  Future<void> _togglePinMessage(CachedMessage message) async {
    final messageId = int.tryParse(message.id);
    if (messageId == null) return;
    final previousChat = chat;
    final willUnpin = chat?.pinnedMsgId == messageId;
    if (willUnpin) {
      _applyPinnedMessageLocally();
    } else {
      final preview = _pinnedPreviewFor(message);
      _applyPinnedMessageLocally(
        messageId: messageId,
        text: preview.text,
        time: message.time,
        isPreview: preview.isPreview,
      );
    }
    final error = await chats.setPinnedMessage(
      api,
      chatId: widget.chatId,
      messageId: willUnpin ? null : messageId,
      notify: !willUnpin,
    );
    if (!mounted) return;
    if (error != null) {
      if (previousChat != null) setState(() => chat = previousChat);
      showCustomNotification(context, error);
      return;
    }
    showCustomNotification(
      context,
      willUnpin ? 'Сообщение откреплено' : 'Сообщение закреплено',
    );
  }

  Future<void> _unpinCurrentMessage() async {
    final previousChat = chat;
    _applyPinnedMessageLocally();
    final error = await chats.setPinnedMessage(
      api,
      chatId: widget.chatId,
      messageId: null,
      notify: false,
    );
    if (!mounted) return;
    if (error != null) {
      if (previousChat != null) setState(() => chat = previousChat);
      showCustomNotification(context, error);
      return;
    }
    showCustomNotification(context, 'Сообщение откреплено');
  }

  ({String? text, bool isPreview}) _pinnedPreviewFor(CachedMessage message) =>
      pinnedMessagePreview(message.previewPayload);

  void _applyPinnedMessageLocally({
    int? messageId,
    String? text,
    int? time,
    bool isPreview = false,
  }) {
    final current = chat;
    if (current == null) return;
    setState(() {
      chat = current.copyWith(
        pinnedMsgId: messageId,
        pinnedMsgText: text,
        pinnedMsgTime: time,
        pinnedMsgIsPreview: isPreview,
      );
    });
  }

  void _revealPlayingMessage(int chatId, String messageId, int messageTime) {
    if (chatId != widget.chatId) return;
    _scrollNav.revealMessage(messageId, messageTime);
  }

  void _jumpToPinnedMessage() {
    final pinnedId = chat?.pinnedMsgId;
    if (pinnedId == null) return;
    unawaited(
      _scrollNav.goTo(pinnedId.toString(), time: chat?.pinnedMsgTime ?? 0),
    );
  }

  bool _badgeRefreshing = false;
  bool _badgeRefreshQueued = false;

  void _onChatsBump() {
    unawaited(_reloadChatMeta());
    if (_badgeRefreshing) {
      _badgeRefreshQueued = true;
      return;
    }
    unawaited(_runBadgeRefresh());
  }

  bool _mergeReadMarks(CachedChat into, CachedChat from) {
    var changed = false;
    from.participants.forEach((userId, mark) {
      if (mark > (into.participants[userId] ?? 0)) {
        into.participants[userId] = mark;
        changed = true;
      }
    });
    return changed;
  }

  Future<void> _reloadChatMeta() async {
    if (_myId == 0) return;
    final rows = await chats.getChat(_myId, widget.chatId);
    if (!mounted || rows.isEmpty) return;
    final fresh = rows.first;
    final current = chat;
    if (current != null && _mergeReadMarks(current, fresh)) {
      _syncOtherReadTime();
    }
    if (current != null &&
        current.pinnedMsgId == fresh.pinnedMsgId &&
        current.pinnedMsgText == fresh.pinnedMsgText &&
        current.pinnedMsgTime == fresh.pinnedMsgTime &&
        current.pinnedMsgIsPreview == fresh.pinnedMsgIsPreview &&
        current.owner == fresh.owner &&
        current.options.length == fresh.options.length &&
        current.options.containsAll(fresh.options) &&
        current.admins.length == fresh.admins.length &&
        current.admins.containsAll(fresh.admins) &&
        current.activeCallData == fresh.activeCallData &&
        current.publicLink == fresh.publicLink) {
      return;
    }
    if (current != null) _mergeReadMarks(fresh, current);
    setState(() => chat = fresh);
    _syncOtherReadTime();
  }

  void _notePeerReadThrough(CachedMessage message) {
    if (widget.chatType != 'DIALOG' || message.senderId == _myId) return;
    final c = chat;
    if (c == null) return;
    if ((c.participants[message.senderId] ?? 0) >= message.time) return;
    c.participants[message.senderId] = message.time;
    _syncOtherReadTime();
  }

  bool get _showsCallBanner => !_commentsMode && chat?.activeCall != null;

  Future<void> _joinChatCall() async {
    final call = chat?.activeCall;
    if (call == null) return;
    await joinGroupCall(
      context,
      token: call.joinLink,
      name: _headerName(),
      isVideo: call.isVideo,
    );
  }

  Future<void> _runBadgeRefresh() async {
    _badgeRefreshing = true;
    try {
      await _refreshBadge();
    } finally {
      _badgeRefreshing = false;
      if (_badgeRefreshQueued && mounted) {
        _badgeRefreshQueued = false;
        unawaited(_runBadgeRefresh());
      }
    }
  }

  Future<void> _refreshBadge() async {
    if (_myId == 0) return;
    final total = await AppDatabase.sumUnread(
      _myId,
      excludeChatId: widget.chatId,
      excludeChatIds: ArchivedChatsStore.instance.archivedChatIds(_myId),
    );
    if (mounted) _otherUnread.value = total;
  }

  Future<void> _loadHistory() async {
    if (_myId == 0) {
      final activeProfile = await AppDatabase.loadActiveProfile();
      if (!mounted) return;
      _myId = activeProfile?.id ?? 0;
    }
    if (_commentsMode) {
      await _loadCommentsHistory();
      return;
    }
    if (widget.chatType == 'DIALOG') {
      unawaited(_loadOtherPresence());
    }
    unawaited(_refreshScheduledCount());
    final pendingFastLocal = _fastLocalLoad;
    if (_iosFastPath && pendingFastLocal != null) await pendingFastLocal;
    if (!mounted) return;
    final localDecoded =
        _fastLocalDecoded ??
        await _chatController.loadLocalHistory(
          onApplyMerged: _applyMergedMessages,
        );
    if (!mounted) return;
    await _chatController.loadRemainingHistory(
      localDecoded: localDecoded,
      onApplyMerged: _applyMergedMessages,
      onLoadingFinished: () {
        setState(() {
          _isLoading = false;
          _onLoadingFinished();
        });
      },
      onPreview: () => _previewChat = true,
      onSenderNames: () {
        _loadForwardedSenderNames();
        _loadGroupSenderNames();
      },
    );
  }

  void _maybeLoadMoreHistory() {
    if (!_scrollController.hasClients) return;
    if (_historyAutoloadSuppressed || _scrollNav.busy) return;
    if (_isLoading) return;
    if (_commentsMode) {
      if (_commentsLoadingMore || !_commentsHasMore || _messages.isEmpty) {
        return;
      }
      if (_scrollNav.distanceFromBottom() <= _historyPrefetchExtent) {
        unawaited(_loadMoreComments());
      }
      return;
    }
    _maybeLoadNewerHistory();
    if (_isLoadingMore || !_hasMoreHistory) return;
    if (_messages.isEmpty) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.maxScrollExtent - pos.pixels <= _historyPrefetchExtent) {
      unawaited(_loadMoreHistory());
    }
  }

  void _maybeLoadNewerHistory() {
    final controller = _chatController;
    if (!controller.hasNewer || controller.isLoadingNewer) return;
    if (_scrollNav.distanceFromBottom() > _historyPrefetchExtent) return;
    unawaited(_loadNewerHistory());
  }

  Future<void> _loadNewerHistory() async {
    _bumpMessages();
    final added = await _chatController.loadNewerHistory(
      newestKnownTime: chat?.lastMsgTime,
    );
    if (!mounted) return;
    if (added > 0) _syncReactionNotifiersFromMessages();
    _bumpMessages();
    _scrollNav.updateScrollDownVisible();
    if (added == 0) return;
    _loadForwardedSenderNames();
    _loadGroupSenderNames();
  }

  Future<void> _resetToLatest() async {
    await _chatController.resetToLatest();
    if (!mounted) return;
    _deferredIds.clear();
    _syncReactionNotifiersFromMessages();
    _bumpMessages();
    _loadForwardedSenderNames();
    _loadGroupSenderNames();
  }

  int get _visibleMessageCount {
    if (_deferredIds.isEmpty) return _messages.length;
    var visible = _messages.length;
    while (visible > 0 && _deferredIds.contains(_messages[visible - 1].id)) {
      visible--;
    }
    return visible;
  }

  void _flushDeferredMessages() {
    if (_deferredIds.isEmpty) return;
    _deferredIds.clear();
    _bumpMessages();
  }

  String? _viewportAnchorId() {
    final listBox = _listKey.currentContext?.findRenderObject();
    if (listBox is! RenderBox || !listBox.attached) return null;
    final height = listBox.size.height;
    String? newest;
    for (final message in _messages) {
      final box = _messageKeys[message.id]?.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final dy = box.localToGlobal(Offset.zero, ancestor: listBox).dy;
      if (dy >= 0 && dy <= height) newest = message.id;
    }
    return newest;
  }

  double? _messageOffsetInList(String messageId) {
    final listBox = _listKey.currentContext?.findRenderObject();
    final box = _messageKeys[messageId]?.currentContext?.findRenderObject();
    if (listBox is! RenderBox || box is! RenderBox || !box.attached) {
      return null;
    }
    return box.localToGlobal(Offset.zero, ancestor: listBox).dy;
  }

  double? _messageContentOffset(String messageId) {
    if (!_scrollController.hasClients) return null;
    final dy = _messageOffsetInList(messageId);
    if (dy == null) return null;
    return dy - _scrollController.position.pixels;
  }

  double? _messageAlignmentInList(String messageId) {
    final listBox = _listKey.currentContext?.findRenderObject();
    if (listBox is! RenderBox || listBox.size.height <= 0) return null;
    final dy = _messageOffsetInList(messageId);
    if (dy == null) return null;
    return (dy / listBox.size.height).clamp(0.0, 1.0);
  }

  bool _restoreContentOffset(String messageId, double before) {
    if (!_scrollController.hasClients) return false;
    final after = _messageContentOffset(messageId);
    if (after == null) return false;
    final delta = before - after;
    if (delta.abs() <= 0.5) return true;
    final pos = _scrollController.position;
    final target = (pos.pixels + delta).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    if ((target - pos.pixels).abs() <= 0.5) return true;
    _scrollController.jumpTo(target);
    return true;
  }

  Future<void> _loadMessageWindow(
    String messageId,
    int targetTime,
    bool Function() stillWanted,
  ) async {
    if (targetTime <= 0) {
      await _walkHistoryBack(
        reached: () =>
            _chatController.containsId(messageId) || !stillWanted(),
        maxPages: 10,
      );
      return;
    }

    _historyAutoloadSuppressCount++;
    final WindowLoad result;
    try {
      result = await _chatController.loadMessageWindow(
        targetId: messageId,
        targetTime: targetTime,
        newestKnownTime: chat?.lastMsgTime,
        stillWanted: stillWanted,
      );
    } finally {
      _historyAutoloadSuppressCount--;
    }
    if (!mounted) return;
    if (result == WindowLoad.replaced) _deferredIds.clear();
    _syncReactionNotifiersFromMessages();
    _bumpMessages();
    _loadForwardedSenderNames();
    _loadGroupSenderNames();
  }

  Future<void> _walkHistoryBack({
    required bool Function() reached,
    required int maxPages,
    int targetTime = 0,
  }) async {
    if (reached()) return;
    _historyAutoloadSuppressCount++;
    try {
      var page = 0;
      while (mounted &&
          page < maxPages &&
          _hasMoreHistory &&
          !reached() &&
          (_messages.isEmpty || _messages.first.time > targetTime)) {
        page++;
        final before = _messages.isEmpty ? 0 : _messages.first.time;
        await _loadMoreHistory(
          resolveSenderNames: false,
          pageSize: ChatController.historyWalkPageSize,
          persist: false,
        );
        if (!mounted) return;
        final after = _messages.isEmpty ? 0 : _messages.first.time;
        if (after == before) break;
      }
    } finally {
      _historyAutoloadSuppressCount--;
    }
    if (!mounted) return;
    _chatController.persistSessionCache();
    _loadForwardedSenderNames();
    _loadGroupSenderNames();
  }

  Future<void> _loadMoreHistory({
    bool resolveSenderNames = true,
    int? pageSize,
    bool persist = true,
  }) async {
    await _chatController.loadMoreHistory(
      pageSize: pageSize,
      persist: persist,
      onLoadingStarted: _bumpMessages,
      onLoaded: (added) {
        if (added > 0) _syncReactionNotifiersFromMessages();
        _bumpMessages();
        if (resolveSenderNames) {
          _loadForwardedSenderNames();
          _loadGroupSenderNames();
        }
      },
      onError: (_) {
        if (mounted) {
          _isLoadingMore = false;
          _bumpMessages();
        }
      },
    );
  }

  void _applyMergedMessages(
    List<CachedMessage> decodedDesc, {
    bool markLoaded = false,
  }) {
    final anchor = _captureViewportAnchor();
    final changed = _chatController.mergeMessages(decodedDesc);
    _requestCommentCounts();

    if (!changed && !markLoaded) return;

    setState(() {
      if (markLoaded) {
        _isLoading = false;
        _onLoadingFinished();
      }
    });
    if (changed) {
      _syncReactionNotifiersFromMessages();
      _pruneReactionNotifiers();
      _chatController.persistSessionCache();
      _restoreViewportAfterMerge(anchor);
    }
  }

  ({String id, double at, double alignment})? _captureViewportAnchor() {
    if (!_scrollController.hasClients || _scrollNav.isNearBottom()) return null;
    final id = _viewportAnchorId();
    if (id == null) return null;
    final at = _messageContentOffset(id);
    final alignment = _messageAlignmentInList(id);
    if (at == null || alignment == null) return null;
    return (id: id, at: at, alignment: alignment);
  }

  void _restoreViewportAfterMerge(
    ({String id, double at, double alignment})? anchor,
  ) {
    _holdReadMarker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || anchor == null) {
        _releaseReadMarker();
        return;
      }
      if (_restoreContentOffset(anchor.id, anchor.at)) {
        _releaseReadMarker();
        return;
      }
      _historyAutoloadSuppressCount++;
      unawaited(
        _scrollNav.keepInPlace(anchor.id, anchor.alignment).whenComplete(() {
          _historyAutoloadSuppressCount--;
          _releaseReadMarker();
        }),
      );
    });
  }

  void _requestCommentCounts() {
    if (_commentsMode) return;
    if ((chat?.type ?? widget.chatType) != 'CHANNEL') return;
    final pending = <String>[];
    for (final m in _messages) {
      if (m.isControl) continue;
      if (_commentCountsRequested.contains(m.id)) continue;
      _commentCountsRequested.add(m.id);
      pending.add(m.id);
    }
    if (pending.isEmpty) return;
    unawaited(
      commentsModule.fetchInfo(
        accountId: _myId,
        chatId: widget.chatId,
        postIds: pending,
      ),
    );
  }

  void _onCommentsInfo(Map<String, CommentsInfo> info) {
    if (!mounted) return;
    var changed = false;
    for (final m in _messages) {
      final count = info[m.id]?.totalCount;
      if (count == null) continue;
      if (_commentCounts[m.id] != count) {
        _commentCounts[m.id] = count;
        changed = true;
      }
    }
    if (changed) setState(() {});
  }

  String _commentsLabelFor(String postId) {
    final l10n = AppLocalizations.of(context)!;
    final count = _commentCounts[postId];
    if (count == null || count == 0) return l10n.commentsWrite;
    return l10n.commentsCount(count);
  }

  void _openComments(CachedMessage post) {
    Navigator.of(context)
        .push(
          iosPageRoute(context,
            builder: (_) => ChatScreen(
              chatId: widget.chatId,
              name: widget.name,
              imageUrl: widget.imageUrl,
              chatType: 'CHANNEL',
              commentPostId: post.id,
              postMessage: _stripInlineKeyboard(post),
            ),
          ),
        )
        .then((_) => _refreshCommentCount(post.id));
  }

  void _refreshCommentCount(String postId) {
    if (!mounted) return;
    _commentCountsRequested.remove(postId);
    _requestCommentCounts();
  }

  CachedMessage _stripInlineKeyboard(CachedMessage post) {
    final attaches = post.attachments;
    if (attaches == null || attaches.isEmpty) return post;
    final filtered = attaches
        .where((a) => a.type != AttachmentType.inlineKeyboard)
        .toList();
    if (filtered.length == attaches.length) return post;
    return post.copyWith(attachments: filtered);
  }

  Future<void> _loadCommentsHistory() async {
    final post = widget.postMessage;
    final loaded = await commentsModule.fetchHistory(
      _myId,
      widget.chatId,
      widget.commentPostId!,
      fromTime: post?.time ?? DateTime.now().millisecondsSinceEpoch,
      forward: 30,
      backward: 0,
    );
    if (!mounted) return;
    final comments = [...loaded]..sort((a, b) => a.time.compareTo(b.time));
    _messages = post != null ? [post, ...comments] : comments;
    _deferredIds.clear();
    _commentsHasMore = comments.isNotEmpty;
    _syncReactionNotifiersFromMessages();
    unawaited(_resolveCommentNames(comments));
    _bumpMessages();
    setState(() {
      _isLoading = false;
      _onLoadingFinished();
    });
  }

  Future<void> _loadMoreComments() async {
    if (_commentsLoadingMore || !_commentsHasMore || _messages.isEmpty) return;
    _commentsLoadingMore = true;
    final newest = _messages.last;
    try {
      final more = await commentsModule.fetchHistory(
        _myId,
        widget.chatId,
        widget.commentPostId!,
        fromTime: newest.time,
        forward: 30,
        backward: 0,
      );
      if (!mounted) return;
      final existing = _messages.map((m) => m.id).toSet();
      final fresh = more.where((c) => !existing.contains(c.id)).toList();
      if (fresh.isEmpty) {
        _commentsHasMore = false;
      } else {
        _messages = [..._messages, ...fresh]
          ..sort((a, b) => a.time.compareTo(b.time));
        _syncReactionNotifiersFromMessages();
        unawaited(_resolveCommentNames(fresh));
        _bumpMessages();
      }
    } finally {
      _commentsLoadingMore = false;
    }
  }

  void _onLiveComment(CommentAddedEvent event) {
    if (!mounted) return;
    final comment = event.comment;
    if (comment.senderId == _myId) return;
    if (_chatController.containsId(comment.id)) return;
    final nearBottom = _isNearListBottom();
    if (!nearBottom) _deferredIds.add(comment.id);
    _chatController.addMessage(comment);
    _syncReactionNotifiersFromMessages();
    _bumpMessages();
    unawaited(_resolveCommentNames([comment]));
    if (nearBottom) {
      _scrollNav.scrollToBottom();
    } else {
      _scrollNav.noteMissedMessage();
    }
  }

  bool _isNearListBottom() =>
      _scrollNav.distanceFromBottom() <= _historyPrefetchExtent;

  Future<void> _resolveCommentNames(List<CachedMessage> list) async {
    final ids = list
        .map((m) => m.senderId)
        .where((id) => id != 0 && ContactCache.get(id) == null)
        .toSet();
    if (ids.isEmpty) return;
    final resolved = await messagesModule.ensureContactNames(ids);
    if (resolved && mounted) _bumpMessages();
  }

  void _syncReactionNotifiersFromMessages() {
    for (final m in _messages) {
      if (_reactionNotifiers.containsKey(m.id)) continue;
      final info = m.payload?['reactionInfo'];
      _reactionNotifiers[m.id] = ValueNotifier(
        info is Map ? Map<String, dynamic>.from(info) : null,
      );
    }
  }

  @override
  void deactivate() {
    _saveDraft();
    super.deactivate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (_voiceRec.isRecording.value) {
        unawaited(_voiceRec.stop(cancel: true));
      }
      if (_note.isRecording.value) {
        unawaited(_note.stop(cancel: true));
      }
    }
    if (state != AppLifecycleState.resumed) _saveDraft();
    super.didChangeAppLifecycleState(state);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final view = View.of(context);
    final keyboardOpen = view.viewInsets.bottom / view.devicePixelRatio > 100;
    if (_keyboardWasOpen && !keyboardOpen && _messageFocusNode.hasFocus) {
      _messageFocusNode.unfocus();
    }
    _keyboardWasOpen = keyboardOpen;
  }

  @override
  void dispose() {
    _nativeStickers.dispose();
    _chatScrollOpaqueHold?.cancel();
    _chatScrollActive.dispose();
    ChatScreen._open.remove(this);
    if (!_commentsMode && !widget.preview) {
      unawaited(NotificationBridge.instance.popActiveChat(widget.chatId));
    }
    _chatController.persistSessionCache();
    if (_previewChat) {
      unawaited(chats.subscribeChat(api, widget.chatId, subscribe: false));
    }
    WidgetsBinding.instance.removeObserver(this);
    _uploadEventSub?.cancel();
    chats.chatsChanged.removeListener(_onChatsBump);
    _otherUnread.dispose();
    _animojiHold.dispose();
    _saveDraft();
    _messageController.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScrollForDate);
    _scrollController.removeListener(_maybeLoadMoreHistory);
    _scrollController.removeListener(_recordScrollPixels);
    _scrollController.removeListener(_scheduleReadMarker);
    _scrollController.removeListener(_scrollNav.updateScrollDownVisible);
    _readMarker.dispose();
    AppVisualStyle.current.removeListener(_onVisualStyleChanged);
    AppIosGlass.active.removeListener(_onVisualStyleChanged);
    if (!widget.preview) MediaPlayback.instance.leaveChat(widget.chatId);
    pollsModule.removeListener(_onNativePolls);
    for (final audio in _nativeVoices.values) {
      audio.playing.removeListener(_onNativeVoiceTick);
      audio.position.removeListener(_onNativeVoiceTick);
      MediaPlayback.instance.releaseVoice(audio);
    }
    _nativeVoices.clear();
    AppChatChrome.current.removeListener(_onVisualStyleChanged);
    AppComposerStyle.current.removeListener(_onVisualStyleChanged);
    AppComposerBackground.current.removeListener(_onVisualStyleChanged);
    _composerHeight.dispose();
    _pinnedBannerHeight.dispose();
    _floatingDateTimer?.cancel();
    _floatingDateCurved.dispose();
    _floatingDateAnimController.dispose();
    _floatingDate.dispose();
    _scrollDownCurved.dispose();
    _scrollDownAnimController.dispose();
    _hasText.dispose();
    _scheduledCount.dispose();
    _showAttachmentPanel.removeListener(_onAttachPanelToggle);
    _showAttachmentPanel.dispose();
    _mediaSend.dispose();
    _pushSub?.cancel();
    _messageEventSub?.cancel();
    _commentsInfoSub?.cancel();
    _commentSub?.cancel();
    _connSub?.cancel();
    _voiceRec.dispose();
    _note.dispose();
    debugForceOffline.removeListener(_recomputeHeaderStatus);
    for (final n in _reactionNotifiers.values) {
      n.dispose();
    }
    _reactionNotifiers.clear();
    _reactionAnimation.dispose();
    ChatActivityStore.instance
        .listenable(widget.chatId)
        .removeListener(_recomputeHeaderStatus);
    ChatMembersStore.instance
        .listenable(widget.chatId)
        .removeListener(_recomputeHeaderStatus);
    PresenceFetch.revision.removeListener(_onPresenceChanged);
    ContactsModule.revision.removeListener(_onContactsChanged);
    if (_wallpaperListening) {
      ChatWallpaperStore.instance.revision.removeListener(
        _applyEffectiveWallpaper,
      );
    }
    if (_encryptionListening) {
      ChatEncryptionStore.instance.revision.removeListener(_applyEncryption);
      E2eeService.instance.revision.removeListener(_applyEncryption);
    }
    _headerStatusNotifier.dispose();
    _otherReadTime.dispose();
    _chatController.appendedCount.removeListener(MeshGradientPulse.pulse);
    _chatController.dispose();
    _prank.dispose();
    _uploadStatus.dispose();
    _attachAnim.dispose();
    _commandPanel.dispose();
    _mentionPanel.dispose();
    _selectionAnim.dispose();
    _searchAnim.dispose();
    _searchFocusNode.dispose();
    _search.dispose();
    _selectedIds.dispose();
    _textSelection.dispose();
    _textSelectionDrag.dispose();
    _disposeCommandArguments();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _stickers.dispose();
    _scrollController.dispose();
    _shimmerStartTimer?.cancel();
    _shimmerController.dispose();
    _replyTo.dispose();
    _pendingForwards.dispose();
    _scrollNav.dispose();
    _routeSettle.dispose();
    _messageKeys.clear();
    super.dispose();
  }

  void _onTextChanged() {
    final newHasText = _messageController.text.trim().isNotEmpty;
    if (newHasText != _hasText.value) {
      _hasText.value = newHasText;
    }
    _commandPanel.update();
    _mentionPanel.update();
  }

  bool _mentionsAvailable() =>
      !_commentsMode && (chat?.type ?? widget.chatType) == 'CHAT';

  // #***! отвечать можно только там, где вообще есть поле ввода: в канале без
  // прав и в непросмотренной подписке композер заменён плашкой, и «Ответить»
  // раньше открывало ответ в никуда
  bool get _canReply {
    if (_commentsMode) return true;
    final type = chat?.type ?? widget.chatType;
    if (type == 'CHANNEL' || type == 'CHAT' || type == 'GROUP') {
      if (_previewChat) return false;
    }
    if (type != 'CHANNEL') return true;
    return chat?.iAmAdmin(_myId) ?? false;
  }

  void _onMentionSelected(MentionCandidate candidate, MentionQuery query) {
    _messageController.insertMention(
      userId: candidate.id,
      name: candidate.name,
      start: query.start,
      end: query.end,
    );
    _mentionPanel.update();
    _messageFocusNode.requestFocus();
  }

  void _onCommandSelected(SlashCommand c) {
    final oldControllers = _commandArgumentControllers;
    final oldFocusNodes = _commandArgumentFocusNodes;
    _commandArgumentControllers = {};
    _commandArgumentFocusNodes = {};
    for (final argument in c.arguments) {
      _commandArgumentControllers[argument.name] = TextEditingController();
      _commandArgumentFocusNodes[argument.name] = FocusNode();
    }
    _messageController.clear();
    _hasText.value = false;
    setState(() => _selectedCommand = c);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disposeCommandArgumentMaps(oldControllers, oldFocusNodes);
      if (!mounted) return;
      if (c.arguments.isEmpty) {
        _messageFocusNode.unfocus();
      } else {
        _commandArgumentFocusNodes[c.arguments.first.name]?.requestFocus();
      }
    });
  }

  void _cancelSelectedCommand() {
    if (_selectedCommand == null) return;
    _closeSelectedCommand(focusMessage: true);
  }

  void _disposeCommandArguments() {
    _disposeCommandArgumentMaps(
      _commandArgumentControllers,
      _commandArgumentFocusNodes,
    );
    _commandArgumentControllers = {};
    _commandArgumentFocusNodes = {};
  }

  void _closeSelectedCommand({bool focusMessage = false}) {
    final controllers = _commandArgumentControllers;
    final focusNodes = _commandArgumentFocusNodes;
    _commandArgumentControllers = {};
    _commandArgumentFocusNodes = {};
    setState(() => _selectedCommand = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disposeCommandArgumentMaps(controllers, focusNodes);
      if (focusMessage && mounted) _messageFocusNode.requestFocus();
    });
  }

  void _disposeCommandArgumentMaps(
    Map<String, TextEditingController> controllers,
    Map<String, FocusNode> focusNodes,
  ) {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    for (final node in focusNodes.values) {
      node.dispose();
    }
  }

  Map<String, dynamic> _selectedCommandArguments() => Map.unmodifiable({
    for (final entry in _commandArgumentControllers.entries)
      entry.key: entry.value.text.trim(),
  });

  void _restoreDraft() {
    if (_myId == 0 || _commentsMode || _messageController.text.isNotEmpty) {
      return;
    }
    final shared = widget.initialText?.trim();
    final draft = (shared != null && shared.isNotEmpty)
        ? shared
        : DraftStore.instance.get(_myId, widget.chatId);
    if (draft == null || draft.isEmpty) return;
    _messageController.text = draft;
    _messageController.selection = TextSelection.collapsed(
      offset: draft.length,
    );
  }

  void _saveDraft() {
    if (_myId == 0 || _commentsMode || widget.preview) return;
    // #***! черновик зашифрованного чата осел бы на диске открытым текстом
    if (_encryptionEnabled) {
      if (DraftStore.instance.get(_myId, widget.chatId) != null) {
        unawaited(DraftStore.instance.clear(_myId, widget.chatId));
      }
      return;
    }
    unawaited(
      DraftStore.instance.set(
        _myId,
        widget.chatId,
        _messageController.buildContent().text,
      ),
    );
  }

  void _onAttachPanelToggle() {
    if (_showAttachmentPanel.value) {
      _attachAnim.forward();
    } else {
      _attachAnim.reverse();
    }
  }

  int _computeOtherReadTime() {
    final c = chat;
    if (c == null) return 0;
    int otherReadTime = 0;
    for (final entry in c.participants.entries) {
      if (entry.key != _myId && entry.value > otherReadTime) {
        otherReadTime = entry.value;
      }
    }
    return otherReadTime;
  }

  void _syncOtherReadTime() {
    final t = _computeOtherReadTime();
    if (_otherReadTime.value != t) _otherReadTime.value = t;
  }

  String? _effectiveStatus(CachedMessage msg) {
    if (msg.senderId != _myId) return null;
    if (msg.status == 'sending' ||
        msg.status == 'pending' ||
        msg.status == 'error') {
      return msg.status;
    }
    return 'sent';
  }

  void _onIncomingPush(Packet packet) {
    if (!mounted) return;
    switch (packet.opcode) {
      case Opcode.notifMark:
        _onMessageRead(packet);
      case Opcode.notifTyping:
        _onTyping(packet);
      case Opcode.notifMsgDelayed:
        final p = packet.payload;
        if (p is Map && p['chatId'] == widget.chatId) {
          // lastDelayedUpdateTime — авторитетный признак от сервера:
          // 0 — отложенных в чате не осталось, иначе они есть. Реагируем
          // мгновенно по пушу, не дожидаясь повторного запроса.
          final t = p['lastDelayedUpdateTime'];
          if (t is int && t == 0) {
            _scheduledCount.value = 0;
          } else {
            if (_scheduledCount.value == 0) _scheduledCount.value = 1;
            _refreshScheduledCount();
          }
        }
    }
  }

  void _markHasScheduled() {
    if (_scheduledCount.value == 0) _scheduledCount.value = 1;
  }

  Future<void> _refreshScheduledCount() async {
    if (_myId == 0) return;
    try {
      final list = await messagesModule.fetchDelayedMessages(
        _myId,
        widget.chatId,
      );
      if (mounted) _scheduledCount.value = list.length;
    } catch (_) {}
  }

  void _bumpMessages() {
    _rowCache.clear();
    _bumpMessageRows();
  }

  void _bumpMessageRows() {
    _combinedItemsCache = null;
    _messagesRev.value++;
  }

  void _enterSelection(CachedMessage message) {
    if (message.isControl) return;
    Haptics.medium();
    if (_selectedIds.value.contains(message.id)) return;
    _selectedIds.value = {..._selectedIds.value, message.id};
    _syncSelectionAnim();
  }

  void _toggleSelection(CachedMessage message) {
    if (message.isControl) return;
    final next = Set<String>.from(_selectedIds.value);
    if (!next.remove(message.id)) next.add(message.id);
    Haptics.selection();
    _selectedIds.value = next;
    if (!next.contains(message.id)) _exitTextSelection(message.id);
    _syncSelectionAnim();
  }

  void _clearSelection() {
    _exitTextSelection();
    if (_selectedIds.value.isEmpty) return;
    _selectedIds.value = const {};
    _syncSelectionAnim();
  }

  void _startTextSelection(CachedMessage message, Offset globalPosition) {
    if (message.isControl || message.selectableText == null) return;
    _textSelectionDrag.value = null;
    _textSelection.value = (id: message.id, pos: globalPosition);
  }

  void _exitTextSelection([String? onlyId]) {
    final current = _textSelection.value;
    if (current == null) return;
    if (onlyId != null && current.id != onlyId) return;
    _textSelection.value = null;
  }

  void _syncSelectionAnim() {
    if (_selectedIds.value.isEmpty) {
      _selectionAnim.reverse();
    } else if (_selectionAnim.status != AnimationStatus.forward &&
        _selectionAnim.value < 1) {
      _selectionAnim.forward();
    }
  }

  List<CachedMessage> _selectedMessages(Set<String> ids) =>
      _messages.where((m) => ids.contains(m.id)).toList();

  List<CachedMessage> _copyableSelection(Set<String> ids) => [
    for (final m in _messages)
      if (ids.contains(m.id) &&
          (MessageDecryptionCache.instance.readableText(m) ?? '').isNotEmpty)
        m,
  ];

  CachedMessage? _singleEditable(Set<String> ids) {
    if (ids.length != 1) return null;
    final list = _selectedMessages(ids);
    if (list.isEmpty) return null;
    return _canEditMessage(list.first) ? list.first : null;
  }

  void _copySelected(List<CachedMessage> messages) {
    if (messages.isEmpty) return;
    final text = messages
        .map((m) => MessageDecryptionCache.instance.readableText(m) ?? '')
        .where((t) => t.isNotEmpty)
        .join('\n\n');
    Clipboard.setData(ClipboardData(text: text));
    Haptics.tap();
    showCustomNotification(context, 'Скопировано');
    _clearSelection();
  }

  void _editSelected(CachedMessage message) {
    _clearSelection();
    _startEditMessage(message);
  }

  Future<void> _deleteSelected() async {
    final msgs = _selectedMessages(_selectedIds.value);
    if (msgs.isEmpty) return;

    final serverMsgs = msgs.where((m) => !m.id.startsWith('temp_')).toList();
    if (serverMsgs.isEmpty) {
      for (final m in msgs) {
        _startDeleteAnimation(m.id);
      }
      _clearSelection();
      return;
    }

    final canForEveryone = serverMsgs.every((m) => m.senderId == _myId);
    final forEveryone = await _showDeleteMessageDialog(canForEveryone);
    if (forEveryone == null || !mounted) return;

    final ok = await messagesModule.deleteMessages(
      widget.chatId,
      serverMsgs.map((m) => m.id).toList(),
      forEveryone: forEveryone,
    );
    if (!mounted) return;
    if (!ok) {
      Haptics.error();
      showCustomNotification(context, 'Не удалось удалить сообщения');
      return;
    }
    for (final m in msgs) {
      _startDeleteAnimation(m.id);
    }
    _clearSelection();
  }

  void _replySelected() {
    final msgs = _selectedMessages(_selectedIds.value);
    if (msgs.isEmpty) return;
    final message = msgs.first;
    _clearSelection();
    _textSend.startReply(message);
  }

  void _forwardSelected() {
    final msgs = _selectedMessages(_selectedIds.value);
    _clearSelection();
    unawaited(_forwardMessages(msgs));
  }

  // #***! пересылка это серверная копия, текст подставляет сервер а не мы
  Future<void> _forwardMessages(List<CachedMessage> msgs) async {
    final forwardable = msgs
        .where((message) => int.tryParse(message.id) != null)
        .toList();
    if (forwardable.isEmpty) {
      showCustomNotification(context, 'Нечего пересылать');
      return;
    }
    if (_encryptionEnabled) {
      showCustomNotification(
        context,
        AppLocalizations.of(context)!.e2eeForwardBlocked,
      );
      return;
    }

    final target = await openForwardScreen(
      context: context,
      messageCount: forwardable.length,
    );
    if (target == null || !mounted) return;

    final ordered = [...forwardable]..sort((a, b) => a.time.compareTo(b.time));
    final request = ForwardRequest(
      sourceChatId: widget.chatId,
      sourceChatName: widget.name,
      sourceChatIconUrl: widget.imageUrl,
      sourceChatType: widget.chatType,
      messages: ordered,
    );

    if (target.chatId == widget.chatId) {
      _textSend.setForwardRequest(request);
      return;
    }

    pushSwipeable(
      context,
      (_) => ChatScreen(
        chatId: target.chatId,
        name: target.name,
        imageUrl: target.imageUrl,
        chatType: target.chatType,
        forwardRequest: request,
      ),
    );
  }

  PreferredSizeWidget _previewSafeBar(PreferredSizeWidget bar) =>
      widget.preview
      ? PreferredSize(
          preferredSize: bar.preferredSize,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: bar,
          ),
        )
      : bar;

  Widget _composerAreaWidget() {
    return ComposerArea(
      selectionAnim: _selectionAnim,
      searchAnim: _searchAnim,
      attachAnim: _attachAnim,
      stickers: _stickers,
      selectedCommand: _selectedCommand,
      commandArgumentControllers: _commandArgumentControllers,
      commandArgumentFocusNodes: _commandArgumentFocusNodes,
      onCancelSelectedCommand: _cancelSelectedCommand,
      onSendMessage: _sendMessage,
      showAttachmentPanel: _showAttachmentPanel,
      onPickFile: _pickAndUploadFile,
      onSendFileById: _mediaSend.sendFileById,
      commentsMode: _commentsMode,
      chatType: widget.chatType,
      chatId: widget.chatId,
      peerName: widget.name,
      onOpenEncryption: _openEncryptionSettings,
      chrome: _effectiveChrome,
      chromeVignette: _chromeVignette,
      pillBackdrop: _pillBackdrop,
      barBackdrop: _barBackdrop,
      replyTo: _replyTo,
      forwardMessages: _pendingForwards,
      myId: _myId,
      hasText: _hasText,
      uploadStatus: _uploadStatus,
      messageController: _messageController,
      messageFocusNode: _messageFocusNode,
      voiceRec: _voiceRec,
      note: _note,
      onToggleStickerPanel: _toggleStickerPanel,
      onScheduleMessage: _scheduleMessage,
      onOpenAttach: _openAttachmentSheet,
      onOpenAttachScheduled: _openAttachmentSheetScheduled,
      onSendHistory: _mediaSend.sendHistoryFile,
      onCancelReply: _textSend.cancelReply,
      onCancelForward: _textSend.cancelForward,
      crossChatReplySupported: _crossChatReplySupported,
      onPickReplyChat: _pickReplyChat,
      formatElapsed: formatVoiceElapsed,
      formatContextMenu: _formatContextMenu,
      pasteMenuItem: _pasteMenuItem,
      onPasteMedia: ClipboardMedia.supported ? _handlePasteMedia : null,
      onInsertContent: _insertKeyboardContent,
      isMuted: chat?.isMuted ?? false,
      onToggleMute: _toggleChatMute,
      channelSubscribed: !_previewChat,
      canPostToChannel: chat?.iAmAdmin(_myId) ?? false,
      channelSubscribing: _subscribing,
      onSubscribe: _subscribeChannel,
      onOpenSearch: _openSearch,
      onStickerTap: _mediaSend.sendSticker,
      onEmojiTap: _insertAnimoji,
      onPlainEmojiTap: _insertPlainEmoji,
      selectedIds: _selectedIds,
      onReplySelected: _replySelected,
      onForwardSelected: _forwardSelected,
      forwardDisabled: chat?.forwardDisabled ?? false,
      replyDisabled: !_canReply,
      useNativeComposer: NativeChatBridge.isEligible,
      composerFrosted: _composerFrosted,
      scrollOpaque: _chatScrollActive,
    );
  }

  bool _canEditMessage(CachedMessage message) {
    if (message.senderId != _myId) return false;
    if (message.id.startsWith('temp_')) return false;
    if (message.isControl) return false;
    if (message.forwardedAttachment != null) return false;
    final status = message.status;
    if (status == 'sending' || status == 'error') return false;
    return true;
  }

  Future<String?> _editableText(CachedMessage message) async {
    final text = message.text ?? '';
    final decryption = await MessageDecryptionCache.instance.resolve(
      accountId: message.accountId,
      chatId: message.chatId,
      messageId: message.id,
      cipherText: text,
    );
    if (decryption == null) return text;
    return decryption.isDecrypted ? decryption.plaintext : null;
  }

  Future<void> _startEditMessage(CachedMessage message) async {
    final original = await _editableText(message);
    if (!mounted) return;
    if (original == null) {
      showCustomNotification(
        context,
        AppLocalizations.of(context)!.e2eeEditUnavailable,
      );
      return;
    }
    final decrypted = original != (message.text ?? '');
    final formatRanges = decrypted
        ? const <FormatRange>[]
        : message.formatRanges;
    final cs = Theme.of(context).colorScheme;

    final content =
        await showIosSheet<
          ({String text, List<Map<String, dynamic>> elements})
        >(
          context: context,
          isScrollControlled: true,
          backgroundColor: cs.surfaceContainerHigh,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (sheetContext) => EditMessageSheet(
            text: original,
            formatRanges: formatRanges,
            contextMenuBuilder: _formatContextMenu,
          ),
        );

    if (content == null || !mounted) return;

    final rawText = content.text;
    final newText = rawText.trim();
    final elements = trimmedElements(content.elements, rawText, newText);

    final oldElements = serializeFormatElements(
      formatRanges.where((r) => composerFormats.contains(r.format)),
    );
    if (newText == original && _sameElements(elements, oldElements)) {
      return;
    }

    final wireText = await _encryptOutgoing(newText);
    if (wireText == null || !mounted) return;
    final editEncrypted = wireText != newText;
    final ok = await messagesModule.editMessage(
      widget.chatId,
      message.id,
      text: wireText,
      elements: editEncrypted ? const [] : elements,
    );
    if (!mounted) return;
    if (!ok) {
      Haptics.error();
      showCustomNotification(context, 'Не удалось изменить сообщение');
      return;
    }

    final idx = _chatController.indexOfId(message.id);
    if (idx != -1) {
      final old = _messages[idx];
      final newHistory = KometSettings.viewRedacted.value
          ? CachedMessage.appendEditHistory(
              old.editHistory,
              old.text,
              DateTime.now().millisecondsSinceEpoch,
            )
          : old.editHistory;
      final editSealed = editEncrypted && _e2eeActive
          ? await E2eeService.instance.sealText(_myId, widget.chatId, newText)
          : null;
      final edited = CachedMessage(
        id: old.id,
        accountId: old.accountId,
        chatId: old.chatId,
        senderId: old.senderId,
        text: wireText.isEmpty ? null : wireText,
        time: old.time,
        status: 'EDITED',
        payload: {
          ...?old.payload,
          'elements': editEncrypted ? const <Map<String, dynamic>>[] : elements,
        },
        attachments: old.attachments,
        isControl: old.isControl,
        editHistory: newHistory,
        sealedText: editSealed,
        e2ee: editSealed == null
            ? CachedMessage.e2eeNone
            : CachedMessage.e2eeText,
      );
      if (editEncrypted) {
        MessageDecryptionCache.instance.seed(message.id, newText);
      }
      _chatController.setMessageAt(idx, edited);
      _bumpMessages();
      unawaited(_chatController.persistOutgoing(edited));
    }
    Haptics.send();
  }

  Future<void> _confirmDeleteMessage(String messageId, bool isMe) async {
    final isLocalOnly = messageId.startsWith('temp_');
    final canForEveryone = isMe && !isLocalOnly;

    if (isLocalOnly) {
      _startDeleteAnimation(messageId);
      return;
    }

    final forEveryone = await _showDeleteMessageDialog(canForEveryone);
    if (forEveryone == null || !mounted) return;

    final ok = await messagesModule.deleteMessages(widget.chatId, [
      messageId,
    ], forEveryone: forEveryone);
    if (!mounted) return;
    if (!ok) {
      Haptics.error();
      showCustomNotification(context, 'Не удалось удалить сообщение');
      return;
    }
    _startDeleteAnimation(messageId);
  }

  void _startDeleteAnimation(String messageId) {
    if (!_deletingIds.add(messageId)) return;
    Haptics.tap();
    _bumpMessages();
  }

  Future<void> _finalizeDelete(String messageId) async {
    if (!mounted) return;
    _deletingIds.remove(messageId);
    final idx = _chatController.indexOfId(messageId);
    if (idx != -1) {
      _chatController.removeMessageAt(idx);
      _reactionNotifiers.remove(messageId)?.dispose();
    }
    _bumpMessages();
    try {
      await AppDatabase.deleteMessage(_myId, widget.chatId, messageId);
      await chats.reconcileLastMessage(_myId, widget.chatId);
    } catch (_) {}
  }

  Future<bool?> _showDeleteMessageDialog(bool canForEveryone) {
    final cs = Theme.of(context).colorScheme;
    var alsoForEveryone = canForEveryone;
    final ios = IosGlass.of(context);
    if (ios) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocalState) {
              return CupertinoAlertDialog(
                title: const Text('Удалить сообщение'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Вы точно хотите удалить это сообщение?'),
                    if (canForEveryone) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CupertinoCheckbox(
                            value: alsoForEveryone,
                            onChanged: (v) => setLocalState(
                              () => alsoForEveryone = v ?? false,
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setLocalState(
                                () => alsoForEveryone = !alsoForEveryone,
                              ),
                              child: Text(
                                'Также удалить для ${widget.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Отмена'),
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    onPressed: () => Navigator.pop(
                      ctx,
                      canForEveryone && alsoForEveryone,
                    ),
                    child: const Text('Удалить'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              backgroundColor: cs.surfaceContainerHigh,
              shape: AppShape.dialogBorder,
              title: const Text('Удалить сообщение'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Вы точно хотите удалить это сообщение?',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
                  ),
                  if (canForEveryone) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => setLocalState(
                        () => alsoForEveryone = !alsoForEveryone,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          IosCheckbox(
                            value: alsoForEveryone,
                            onChanged: (v) => setLocalState(
                              () => alsoForEveryone = v ?? false,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Также удалить для ${widget.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, canForEveryone && alsoForEveryone),
                  child: Text('Удалить', style: TextStyle(color: cs.error)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onMessageEvent(MessageEvent event) {
    if (!mounted) return;
    if (_commentsMode) return;
    switch (event) {
      case MessageAddedEvent(:final message):
        // #***! в Избранном senderId всегда == _myId, дедуп только по id
        if (widget.chatId != 0 &&
            message.senderId == _myId &&
            !message.isControl) {
          return;
        }
        if (_chatController.containsId(message.id)) return;
        _lastSentId = message.id;
        _notePeerReadThrough(message);
        _clearTyping(message.senderId);
        Haptics.tap();
        if (_chatController.hasNewer) {
          _scrollNav.noteMissedMessage();
          _prank.checkTrigger(message);
          return;
        }
        final nearBottom = _scrollNav.isNearBottom();
        if (!nearBottom) _deferredIds.add(message.id);
        _chatController.addMessage(message);
        _bumpMessageRows();
        if (nearBottom) {
          _scrollNav.scrollToBottom();
          _scheduleReadMarker();
        } else {
          _scrollNav.noteMissedMessage();
        }
        _prank.checkTrigger(message);
      case MessageEditedEvent(:final message):
        final idx = _chatController.indexOfId(message.id);
        if (idx == -1) return;
        _chatController.setMessageAt(idx, message);
        _bumpMessageRows();
      case MessageSentEvent(:final tempId, :final message):
        final idx = _chatController.indexOfId(tempId);
        if (idx == -1) return;
        _lastSentId = message.id;
        _chatController.setMessageAt(idx, message);
        _bumpMessageRows();
      case MessageRemovedEvent(:final messageId):
        final idx = _chatController.indexOfId(messageId);
        if (idx == -1) return;
        _chatController.removeMessageAt(idx);
        _bumpMessageRows();
        _reactionNotifiers.remove(messageId)?.dispose();
      case MessageMarkedDeletedEvent(:final messageId):
        final idx = _chatController.indexOfId(messageId);
        if (idx == -1) return;
        if (_messages[idx].deleted) return;
        _chatController.setMessageAt(idx, _messages[idx].copyWith(deleted: true));
        _bumpMessageRows();
      case MessageReactionsChangedEvent(:final messageId, :final reactionInfo):
        _reactionNotifiers[messageId]?.value = reactionInfo;
    }
  }

  Future<void> _loadOtherPresence() async {
    if (_myId == 0) return;
    final otherId = widget.chatId ^ _myId;
    if (otherId <= 0) return;
    if (PresenceFetch.live(otherId) != null) return;
    try {
      final entry = await PresenceFetch.get(otherId);
      if (!mounted || entry == null) return;
      PresenceFetch.apply(otherId, entry);
    } catch (_) {}
  }

  void _onPresenceChanged() {
    if (!mounted) return;
    final otherId = _resolveOtherId();
    if (otherId == null) return;
    final p = PresenceFetch.live(otherId);
    if (p == null) return;
    _otherStatus = (p['status'] as int?) ?? 0;
    _otherSeenTime = p['seen'] as int?;
    _recomputeHeaderStatus();
  }

  void _onVisualStyleChanged() {
    if (mounted) {
      setState(() {});
      _bumpMessages();
    }
  }

  void _onContactsChanged() {
    if (mounted) setState(() {});
  }

  String _headerAvatarUrl() {
    if (!_commentsMode && widget.chatType == 'DIALOG') {
      final otherId = _resolveOtherId();
      if (otherId != null) {
        final cached = ContactCache.getAvatar(otherId);
        if (cached != null && cached.isNotEmpty) return cached;
      }
    }
    return widget.imageUrl;
  }

  String _headerName() {
    if (_commentsMode) return AppLocalizations.of(context)!.commentsTitle;
    if (widget.chatType == 'DIALOG') {
      final otherId = _resolveOtherId();
      if (otherId != null) {
        final cached = ContactCache.get(otherId);
        if (cached != null && cached.isNotEmpty) return cached;
      }
    }
    return widget.name;
  }

  bool get _hasMiniApp {
    if (widget.chatType != 'DIALOG' || _commentsMode) return false;
    final peerId = _resolveOtherId();
    if (peerId == null) return false;
    if (hasMiniAppOption(ContactCache.getOptions(peerId))) return true;
    return hasMiniAppOption(chat?.options);
  }

  Future<void> _openMiniApp() async {
    final peerId = _resolveOtherId();
    if (peerId == null) return;
    await openMiniApp(
      context,
      botId: peerId,
      chatId: widget.chatId,
      title: _headerName(),
    );
  }

  void _openChatMenu(BuildContext btnContext) {
    final box = btnContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _openChatMenuAt(box.localToGlobal(Offset.zero) & box.size);
  }

  void _openChatMenuAt(Rect anchorRect) {
    showChatMenu(
      context: context,
      anchorRect: anchorRect,
      items: [
        if (_hasMiniApp)
          ChatMenuItem(
            icon: IosSymbols.apps(context),
            label: AppLocalizations.of(context)!.miniAppOpen,
            dividerAfter: true,
            onTap: () => unawaited(_openMiniApp()),
          ),
        ChatMenuItem(
          icon: (chat?.isMuted ?? false)
              ? IosSymbols.volumeOff(context)
              : IosSymbols.speaker(context),
          label: (chat?.isMuted ?? false)
              ? 'Включить уведомления'
              : 'Отключить уведомления',
          dividerAfter: true,
          onTap: _toggleChatMute,
        ),
        if (!_searchInBottomBar)
          ChatMenuItem(
            icon: IosSymbols.search(context),
            label: 'Поиск',
            onTap: _openSearch,
          ),
        ChatMenuItem(
          icon: IosSymbols.wallpaper(context),
          label: 'Изменить обои',
          onTap: _openWallpaperSheet,
        ),
        ChatMenuItem(
          icon: IosSymbols.mop(context),
          label: 'Очистить историю',
          onTap: _clearHistory,
        ),
        ChatMenuItem(
          icon: _encryptionEnabled ? IosSymbols.lock(context) : IosSymbols.lockOpen(context),
          label: 'Шифрование сообщений',
          onTap: _openEncryptionSettings,
        ),
        ChatMenuItem(
          icon: IosSymbols.delete(context),
          label: 'Удалить чат',
          onTap: _deleteChat,
        ),
      ],
    );
  }

  Future<void> _subscribeChannel() async {
    if (_subscribing) return;
    setState(() => _subscribing = true);
    try {
      var link = _channelLink;
      if (link == null || link.isEmpty) {
        final info = await chats.getChatInfo(api, widget.chatId);
        link = info?['link'] as String?;
      }
      if (link == null || link.isEmpty) {
        throw const PacketError('Не удалось получить ссылку чата');
      }
      final result = await chats.joinChannel(api, link, _myId);
      if (!mounted) return;
      setState(() {
        _previewChat = false;
        _subscribing = false;
        chat = result.chat;
      });
      ChatMembersStore.instance.setCount(
        widget.chatId,
        result.subscribersCount,
      );
      _recomputeHeaderStatus();
      showCustomNotification(
        context,
        widget.chatType == 'CHANNEL'
            ? 'Вы подписались на канал'
            : 'Вы вступили в группу',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _subscribing = false);
      showCustomNotification(
        context,
        e is PacketError
            ? e.message
            : (widget.chatType == 'CHANNEL'
                  ? 'Не удалось подписаться'
                  : 'Не удалось вступить'),
      );
    }
  }

  Future<void> _toggleChatMute() async {
    final current = chat;
    if (current == null) return;
    final muted = current.isMuted;
    final target = muted ? ChatsModule.muteOff : ChatsModule.muteForever;
    final error = await chats.setChatMute(
      api,
      chatId: widget.chatId,
      dontDisturbUntil: target,
    );
    if (!mounted) return;
    if (error != null) {
      showCustomNotification(context, error);
      return;
    }
    setState(() => chat = current.copyWith(dontDisturbUntil: target));
    showCustomNotification(
      context,
      muted ? 'Уведомления включены' : 'Уведомления отключены',
    );
  }

  bool _encryptionListening = false;

  Future<void> _loadEncryption() async {
    await ChatEncryptionStore.instance.load();
    await E2eeService.instance.ensureLoaded(_myId);
    if (!mounted) return;
    if (!_encryptionListening) {
      _encryptionListening = true;
      ChatEncryptionStore.instance.revision.addListener(_applyEncryption);
      E2eeService.instance.revision.addListener(_applyEncryption);
    }
    _applyEncryption();
  }

  bool get _e2eeActive =>
      widget.chatType == 'DIALOG' &&
      E2eeService.instance.isActive(_myId, widget.chatId);

  bool get _e2eeVerified =>
      _e2eeActive &&
      (E2eeService.instance.info(_myId, widget.chatId)?.verified ?? false);

  void _applyEncryption() {
    if (!mounted) return;
    final e2ee = _e2eeActive;
    final enabled =
        e2ee || ChatEncryptionStore.instance.isEnabled(_myId, widget.chatId);
    if (enabled != _encryptionEnabled) {
      setState(() => _encryptionEnabled = enabled);
    }
    if (enabled && !e2ee && _myId != 0) {
      unawaited(ChatCryptoService.instance.warmKey(_myId, widget.chatId));
    }
  }

  Future<void> _openEncryptionSettings() async {
    if (_myId == 0) return;
    await pushSwipeable(
      context,
      (context) => widget.chatType == 'DIALOG'
          ? E2eeScreen(
              accountId: _myId,
              chatId: widget.chatId,
              peerId: _resolveOtherId() ?? 0,
              peerName: widget.name,
            )
          : ChatEncryptionScreen(accountId: _myId, chatId: widget.chatId),
    );
    if (!mounted) return;
    _applyEncryption();
  }

  bool _wallpaperListening = false;

  Future<void> _loadWallpaper() async {
    await ChatWallpaperStore.instance.load();
    if (!mounted) return;
    if (!_wallpaperListening) {
      _wallpaperListening = true;
      ChatWallpaperStore.instance.revision.addListener(
        _applyEffectiveWallpaper,
      );
    }
    _applyEffectiveWallpaper();
  }

  void _applyEffectiveWallpaper() {
    if (!mounted) return;
    final store = ChatWallpaperStore.instance;
    final wp =
        store.get(_myId, widget.chatId) ??
        store.get(_myId, kGlobalWallpaperChatId);
    if (!identical(wp, _wallpaper)) setState(() => _wallpaper = wp);
  }

  Future<void> _openWallpaperSheet() async {
    if (_myId == 0) return;
    final pick = await showChatWallpaperSheet(context, current: _wallpaper);
    if (pick == null || !mounted) return;
    final store = ChatWallpaperStore.instance;
    switch (pick.type) {
      case WallpaperPickType.none:
        await store.clear(_myId, widget.chatId);
        _applyEffectiveWallpaper();
        break;
      case WallpaperPickType.theme:
        final theme = pick.theme;
        if (theme == null) break;
        await store.setTheme(_myId, widget.chatId, theme.id);
        _applyEffectiveWallpaper();
        break;
      case WallpaperPickType.gallery:
        await _pickWallpaperFromGallery();
        break;
      case WallpaperPickType.gradient:
        final colors = pick.gradientColors;
        if (colors == null || colors.isEmpty) break;
        await store.setGradient(
          _myId,
          widget.chatId,
          colors,
          animated: pick.gradientAnimated,
          rotation: pick.gradientRotation,
        );
        _applyEffectiveWallpaper();
        break;
    }
  }

  Future<void> _pickWallpaperFromGallery() async {
    final bytes = await pickWallpaperBytes(context);
    if (bytes == null || !mounted) return;
    final settings = await Navigator.of(context).push<WallpaperImageSettings>(
      iosPageRoute(context,
        builder: (_) => ChatWallpaperPreviewScreen(imageBytes: bytes),
      ),
    );
    if (settings == null || !mounted) return;
    final wp = await ChatWallpaperStore.instance.setImage(
      _myId,
      widget.chatId,
      bytes,
      settings: settings,
    );
    if (!mounted) return;
    if (wp == null) {
      showCustomNotification(context, 'Не удалось сохранить обои');
      return;
    }
    _applyEffectiveWallpaper();
  }

  bool get _canActForAll {
    final type = chat?.type ?? widget.chatType;
    if (type == 'DIALOG') return widget.chatId != 0;
    return (type == 'CHAT' || type == 'CHANNEL') &&
        (chat?.iAmAdmin(_myId) ?? false);
  }

  Future<void> _clearHistory() async {
    final current = chat;
    final canClearForAll = _canActForAll;
    final choice = await showBlurredConfirm(
      context,
      title: 'Очистить историю',
      message:
          'Все сообщения в этом чате будут удалены без возможности '
          'восстановления.',
      confirmLabel: 'Очистить',
      cancelLabel: 'Отмена',
      destructive: true,
      checkboxLabel: canClearForAll ? 'Для всех' : null,
    );
    if (!mounted || !choice.confirmed) return;
    final err = await chats.clearHistory(
      api,
      chatId: widget.chatId,
      lastEventTime: current?.lastEventTime ?? 0,
      forAll: canClearForAll && choice.checked,
    );
    if (!mounted) return;
    if (err != null) {
      showCustomNotification(context, err);
      return;
    }
    setState(() {
      _messages = [];
      _deferredIds.clear();
      _hasMoreHistory = false;
      _combinedItemsCache = null;
    });
    _messagesRev.value++;
  }

  Future<void> _deleteChat() async {
    final canDeleteForAll = _canActForAll;
    final choice = await showBlurredConfirm(
      context,
      title: 'Удалить чат',
      message: 'Чат будет удалён вместе со всей перепиской.',
      confirmLabel: 'Удалить',
      cancelLabel: 'Отмена',
      destructive: true,
      checkboxLabel: canDeleteForAll ? 'Для всех' : null,
    );
    if (!mounted || !choice.confirmed) return;
    final err = await chats.deleteChat(
      api,
      chatId: widget.chatId,
      lastEventTime: chat?.lastEventTime ?? 0,
      forAll: canDeleteForAll && choice.checked,
    );
    if (!mounted) return;
    if (err != null) {
      showCustomNotification(context, err);
      return;
    }
    _leaveChat();
  }

  Future<void> _startCall() async {
    if (widget.chatType != 'DIALOG' || _peerIsBot) {
      showCustomNotification(context, 'Звонки доступны только в диалогах');
      return;
    }
    // Звонок уже идёт (возможно, свёрнут) — просто открываем его экран снова.
    final navigator = Navigator.of(context);
    final active = CallController.instance.activeSession;
    if (active != null) {
      await navigator.push(
        iosPageRoute(context,
          builder: (_) => CallScreen(
            name: widget.name,
            avatarUrl: widget.imageUrl.isNotEmpty ? widget.imageUrl : null,
            session: active,
          ),
        ),
      );
      _onCallScreenClosed();
      return;
    }
    final peerId = widget.chatId ^ _myId;
    if (peerId <= 0) return;
    try {
      final session = await CallController.instance.startOutgoing(peerId);
      if (!mounted) return;
      await navigator.push(
        iosPageRoute(context,
          builder: (_) => CallScreen(
            name: widget.name,
            avatarUrl: widget.imageUrl.isNotEmpty ? widget.imageUrl : null,
            session: session,
          ),
        ),
      );
      _onCallScreenClosed();
    } catch (_) {
      if (!mounted) return;
      showCustomNotification(context, 'Не удалось начать звонок');
    }
  }

  void _onCallScreenClosed() {
    if (!mounted) return;
    if (CallController.instance.activeSession != null) return;
    unawaited(_refreshAfterCall());
  }

  Future<void> _refreshAfterCall() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted || _myId == 0) return;
    try {
      final serverMessages = await messagesModule.fetchHistory(
        _myId,
        widget.chatId,
      );
      if (KometSettings.viewDeleted.value) {
        await chats.reconcileDeletedFromFetch(
          _myId,
          widget.chatId,
          serverMessages,
        );
      }
      final rows = await AppDatabase.loadMessages(
        _myId,
        widget.chatId,
        limit: 100,
        onlyVisible: !KometSettings.viewDeleted.value,
      );
      final decoded = await CachedMessage.fromDbRowsAsync(rows);
      if (mounted) _applyMergedMessages(decoded);
    } catch (e) {
      logger.w('Обновление после звонка не удалось: $e');
    }
  }

  void _seedPresenceFromChat() {
    if (_otherStatus != 0 || _otherSeenTime != null) return;
    final otherId = _resolveOtherId();
    if (otherId == null) return;
    final p = PresenceFetch.live(otherId);
    if (p == null) return;
    _otherStatus = (p['status'] as int?) ?? 0;
    _otherSeenTime = p['seen'] as int?;
  }

  void _recomputeHeaderStatus() {
    if (_commentsMode) {
      _headerStatusNotifier.value = '';
      return;
    }
    _headerStatusNotifier.value = _headerStatus();
  }

  int get _memberCount =>
      ChatMembersStore.instance.count(widget.chatId) ??
      chat?.participants.length ??
      0;

  bool get _isGroupChat =>
      widget.chatType == 'CHAT' || widget.chatType == 'CHANNEL';

  String _headerStatus() {
    final conn = connectionStatusLabel(api.state);
    if (conn != null) return conn;
    final activity = ChatActivityStore.instance.snapshot(widget.chatId);
    if (activity != null) {
      return chatActivityLabel(activity, withNames: _isGroupChat);
    }
    if (widget.chatType == 'CHAT') {
      final count = _memberCount;
      return '$count участников';
    }
    if (widget.chatType == 'CHANNEL') {
      final count = _memberCount;
      return '$count подписчиков';
    }
    if (_otherStatus == 1) return 'В сети';
    if (_otherStatus == 2 || _otherStatus == 3) return 'Был(-а) недавно';
    final s = _otherSeenTime;
    if (s != null && s > 0) return formatLastSeen(s);
    return '';
  }

  void _onTyping(Packet packet) {
    final payload = packet.payload;
    if (payload is! Map) return;
    if (payload['chatId'] != widget.chatId) return;
    final userId = payload['userId'];
    if (userId is! int || userId == _myId) return;
    ChatActivityStore.instance.mark(
      widget.chatId,
      userId,
      chatActivityFromType(payload['type']),
    );
    unawaited(_ensureTypingName(userId));
  }

  Future<void> _ensureTypingName(int userId) async {
    if (!_isGroupChat) return;
    if (ContactCache.get(userId) != null) return;
    final resolved = await messagesModule.ensureContactNames({userId});
    if (resolved && mounted) _recomputeHeaderStatus();
  }

  void _clearTyping(int userId) {
    ChatActivityStore.instance.clearUser(widget.chatId, userId);
  }

  void _onMessageRead(Packet packet) {
    final payload = packet.payload;
    if (payload is! Map) return;
    if (payload['chatId'] != widget.chatId) return;
    final userId = payload['userId'];
    if (userId is! int || userId == _myId) return;
    final mark = payload['mark'];
    if (mark is! int) return;
    if (payload['setAsUnread'] == true) return;
    final c = chat;
    if (c == null) return;
    if (c.participants[userId] == mark) return;
    c.participants[userId] = mark;
    _syncOtherReadTime();
  }

  static String _formatLabel(TextFormat format) {
    switch (format) {
      case TextFormat.heading:
        return 'Заголовок';
      case TextFormat.strong:
        return 'Жирный';
      case TextFormat.emphasized:
        return 'Курсив';
      case TextFormat.underline:
        return 'Подчёркнутый';
      case TextFormat.strikethrough:
        return 'Зачёркнутый';
      case TextFormat.monospaced:
        return 'Моноширинный';
      case TextFormat.quote:
        return 'Цитата';
      case TextFormat.link:
        return 'Ссылка';
      case TextFormat.animoji:
        return 'Animoji';
      case TextFormat.userMention:
        return 'Упоминание';
    }
  }

  Widget _formatContextMenu(
    RichMessageController controller,
    BuildContext context,
    EditableTextState editableState, {
    ContextMenuButtonItem? pasteItem,
  }) {
    final selection = controller.selection;
    final buttonItems = <ContextMenuButtonItem>[];
    if (selection.isValid && !selection.isCollapsed) {
      for (final format in composerFormats) {
        final active = controller.isFormatActive(format);
        buttonItems.add(
          ContextMenuButtonItem(
            label: '${active ? '✓ ' : ''}${_formatLabel(format)}',
            onPressed: () {
              controller.toggleFormat(format);
              editableState.hideToolbar();
            },
          ),
        );
      }
    }
    if (pasteItem != null) buttonItems.add(pasteItem);
    buttonItems.addAll(editableState.contextMenuButtonItems);
    if (pasteItem == null) {
      return AdaptiveTextSelectionToolbar.buttonItems(
        anchors: editableState.contextMenuAnchors,
        buttonItems: buttonItems,
      );
    }
    return PasteMediaToolbar(
      anchors: editableState.contextMenuAnchors,
      buttonItems: buttonItems,
      pasteItem: pasteItem,
    );
  }

  static bool _sameElements(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    if (a.length != b.length) return false;
    String canon(List<Map<String, dynamic>> els) {
      final copy = [...els]
        ..sort((x, y) {
          final t = (x['type'] as String).compareTo(y['type'] as String);
          return t != 0 ? t : (x['from'] as int).compareTo(y['from'] as int);
        });
      return copy
          .map((e) => '${e['type']}:${e['from']}:${e['length']}')
          .join(',');
    }

    return canon(a) == canon(b);
  }

  int? _resolveOtherId() {
    if (widget.chatType != 'DIALOG' || _myId == 0) return null;
    if (widget.chatId == 0) return null;
    final id = widget.chatId ^ _myId;
    return id > 0 ? id : null;
  }

  int _complaintTypeId(String type) {
    switch (type) {
      case 'CHANNEL':
        return 5;
      case 'CHAT':
        return 4;
      default:
        return 3;
    }
  }

  Future<List<({int id, String title})>> _loadReportReasons(int typeId) async {
    final reasons = await ComplaintsModule.reasonsFor(api, typeId);
    return reasons.map((r) => (id: r.reasonId, title: r.reasonTitle)).toList();
  }

  Future<bool> _reportMessage(
    CachedMessage message,
    int typeId,
    int reasonId,
  ) async {
    final messageIdNum = int.tryParse(message.id);
    if (messageIdNum == null) {
      if (mounted) {
        showCustomNotification(context, 'Не удалось отправить жалобу');
      }
      return false;
    }
    final ok = await ComplaintsModule.sendComplaint(
      api,
      reasonId: reasonId,
      typeId: typeId,
      ids: [messageIdNum],
      parentId: widget.chatId,
    );
    if (!mounted) return ok;
    showCustomNotification(
      context,
      ok ? 'Жалоба отправлена' : 'Не удалось отправить жалобу',
    );
    return ok;
  }

  Future<String?> _encryptOutgoing(String text, {bool notify = true}) async {
    if (!_encryptionEnabled || _myId == 0) return text;
    if (_e2eeActive) {
      final l10n = AppLocalizations.of(context)!;
      if (!E2eeService.instance.fitsTransport(utf8.encode(text).length)) {
        if (mounted && notify) showCustomNotification(context, l10n.e2eeTooLong);
        return null;
      }
      final String? wire;
      try {
        wire = await E2eeService.instance.encryptText(
          _myId,
          widget.chatId,
          text,
        );
      } on E2eeAwaitingPeer {
        if (mounted && notify) {
          showCustomNotification(context, l10n.e2eeAwaitingPeer);
        }
        return null;
      }
      if (wire == null && mounted && notify) {
        showCustomNotification(context, l10n.e2eeEncryptFailed);
      }
      return wire;
    }
    final result = await ChatCryptoService.instance.encrypt(
      _myId,
      widget.chatId,
      text,
    );
    if (result.isOk) {
      if (result.text!.length > kMaxEncryptedMessageLength) {
        if (mounted && notify) {
          showCustomNotification(
            context,
            'Слишком длинное сообщение. Разделите на несколько',
          );
        }
        return null;
      }
      return result.text;
    }
    if (mounted && notify) {
      showCustomNotification(
        context,
        result.failure == CryptoFailure.noKey
            ? 'Не задан ключ шифрования'
            : 'Не удалось зашифровать сообщение',
      );
    }
    return null;
  }

  Future<void> _sendMessage() async {
    final selectedCommand = _selectedCommand;
    if (selectedCommand != null) {
      await _executeSelectedCommand(selectedCommand);
      return;
    }
    await _textSend.sendMessage();
  }

  PluginCommandContext _commandContext(
    SlashCommand command,
    String args, {
    Map<String, dynamic>? arguments,
  }) => PluginCommandContext(
    args: args,
    arguments: arguments ?? parseCommandArguments(args, command.arguments),
    replyMessage: _pluginReplyMessage(),
    onlineCheck: () => api.state == SessionState.online,
    activeCheck: () => mounted,
    sendTextCallback: _textSend.postCommandMessage,
    editTextCallback: _textSend.updateCommandMessage,
    sendPhotoCallback: _sendPluginPhoto,
    sendFileCallback: _sendPluginFile,
    notifyCallback: (message) async {
      if (mounted) showCustomNotification(context, message);
    },
    getPeerCallback: _pluginPeer,
  );

  Map<String, dynamic>? _pluginReplyMessage() {
    final message = _replyTo.value;
    if (message == null) return null;
    return {
      'id': message.id,
      'senderId': message.senderId,
      'text': message.text,
      'time': message.time,
      'attachments': [
        for (final attachment in message.attachments ?? const [])
          {'type': attachment.type.name},
      ],
    };
  }

  Future<void> _sendPluginPhoto(
    Uint8List bytes,
    String filename,
    String caption,
  ) async {
    final file = await _pluginTempFile(bytes, filename);
    try {
      await _mediaSend.sendPhotos(
        [PickedPhoto(item: GalleryItem.fromFile(file))],
        caption,
        waitForUpload: true,
      );
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _sendPluginFile(Uint8List bytes, String filename) async {
    if (_encryptionEnabled) {
      throw StateError('Файлы плагинов пока нельзя зашифровать');
    }
    final file = await _pluginTempFile(bytes, filename);
    try {
      await _mediaSend.uploadAsFile(
        source: file,
        filename: filename,
        size: bytes.length,
      );
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  Future<File> _pluginTempFile(Uint8List bytes, String filename) async {
    final directory = await getTemporaryDirectory();
    final extension = p.extension(filename);
    final file = File(
      p.join(
        directory.path,
        'komet_plugin_${DateTime.now().microsecondsSinceEpoch}$extension',
      ),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _executeCommand(SlashCommand command, String args) async {
    try {
      final commandContext = _commandContext(command, args);
      final missing = command.missingArgument(commandContext.arguments);
      if (missing != null) {
        showCustomNotification(
          context,
          'Не указан аргумент ${missing.name}. Формат: ${command.usage}',
        );
        return;
      }
      await command.execute(commandContext);
      if (!mounted) return;
      _replyTo.value = null;
      _textSend.replySourceChatId = null;
    } catch (error) {
      if (!mounted) return;
      showCustomNotification(context, 'Ошибка плагина: $error');
    }
  }

  Future<void> _executeSelectedCommand(SlashCommand command) async {
    if (_commandExecuting) return;
    final arguments = _selectedCommandArguments();
    final missing = command.missingArgument(arguments);
    if (missing != null) {
      showCustomNotification(context, 'Заполните поле ${missing.name}');
      _commandArgumentFocusNodes[missing.name]?.requestFocus();
      return;
    }
    final args = serializeCommandArguments(command.arguments, arguments);
    setState(() => _commandExecuting = true);
    try {
      await command.execute(
        _commandContext(command, args, arguments: arguments),
      );
      if (!mounted) return;
      _replyTo.value = null;
      _textSend.replySourceChatId = null;
      _closeSelectedCommand();
    } catch (error) {
      if (!mounted) return;
      showCustomNotification(context, 'Ошибка плагина: $error');
    } finally {
      if (mounted) setState(() => _commandExecuting = false);
    }
  }

  Future<Map<String, dynamic>?> _pluginPeer() async {
    final id = _resolveOtherId();
    if (id == null) return null;
    final contact = await ContactInfoFetch.get(id, forceRefresh: true);
    if (contact == null) return null;
    return {
      'id': contact.id ?? id,
      'displayName': contact.displayName,
      'country': contact.raw['country']?.toString(),
      'registrationTime': contact.raw['registrationTime'],
      'updateTime': contact.raw['updateTime'],
      'options': contact.options,
    };
  }

  Future<void> _scheduleMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _myId == 0) return;

    final when = await _pickScheduleTime();
    if (when == null || !mounted) return;

    final wireText = await _encryptOutgoing(text);
    if (wireText == null || !mounted) return;

    try {
      await messagesModule.sendMessage(
        _myId,
        widget.chatId,
        wireText,
        scheduledTime: when.millisecondsSinceEpoch,
      );
      if (!mounted) return;
      _hasText.value = false;
      _messageController.clear();
      Haptics.send();
      _markHasScheduled();
      showCustomNotification(
        context,
        'Запланировано на ${formatDateTimeWords(when)}',
      );
    } catch (_) {
      if (!mounted) return;
      Haptics.error();
      showCustomNotification(context, 'Не удалось запланировать сообщение');
    }
  }

  Future<DateTime?> _pickScheduleTime() => showScheduleTimePicker(context);

  void _openScheduledMessages() {
    Navigator.of(context)
        .push(
          iosPageRoute(context,
            builder: (_) => ScheduledMessagesScreen(
              chatId: widget.chatId,
              accountId: _myId,
              chatName: widget.name,
            ),
          ),
        )
        .then((_) {
          if (mounted) _refreshScheduledCount();
        });
  }

  Future<void> _loadGroupSenderNames() async {
    if (widget.chatType != 'CHAT' && widget.chatType != 'CHANNEL') return;

    final unknownIds = <int>{};
    for (final msg in _messages) {
      if (msg.isControl) continue;
      final id = msg.senderId;
      if (id == 0 || id == _myId) continue;
      if (ContactCache.get(id) == null) unknownIds.add(id);
    }
    if (unknownIds.isEmpty) return;

    final resolved = await messagesModule.ensureContactNames(unknownIds);
    if (resolved && mounted) _bumpMessages();
  }

  Future<void> _loadForwardedSenderNames() async {
    final forwardIds = <int>{};
    for (final msg in _messages) {
      if (msg.attachments != null) {
        for (final a in msg.attachments!) {
          if (a is ForwardedMessageAttachment) {
            if (a.originalSenderId != 0 &&
                a.originalSenderName == null &&
                ContactCache.get(a.originalSenderId) == null) {
              forwardIds.add(a.originalSenderId);
            }
          }
        }
      }
    }
    if (forwardIds.isEmpty) return;

    final resolved = <int, ({String name, String? avatar})>{};
    for (final id in forwardIds) {
      final name = await messagesModule.searchContactById(id);
      if (name != null) {
        resolved[id] = (name: name, avatar: ContactCache.getAvatar(id));
      }
    }
    if (resolved.isEmpty || !mounted) return;

    var anyChanged = false;
    for (var i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final attaches = msg.attachments;
      if (attaches == null) continue;

      var msgChanged = false;
      final newAttaches = attaches.map((a) {
        if (a is ForwardedMessageAttachment &&
            a.originalSenderName == null &&
            resolved.containsKey(a.originalSenderId)) {
          final r = resolved[a.originalSenderId]!;
          msgChanged = true;
          return ForwardedMessageAttachment(
            originalSenderId: a.originalSenderId,
            originalSenderName: r.name,
            originalSenderAvatar: r.avatar,
            originalType: a.originalType,
            originalMessageId: a.originalMessageId,
            originalTime: a.originalTime,
            originalText: a.originalText,
            originalChatId: a.originalChatId,
            originalChatAccess: a.originalChatAccess,
            originalFormatRanges: a.originalFormatRanges,
            originalAttachments: a.originalAttachments,
            originalContact: a.originalContact,
          );
        }
        return a;
      }).toList();

      if (!msgChanged) continue;
      anyChanged = true;
      _chatController.setMessageAt(i, msg.copyWith(attachments: newAttaches));
    }

    if (anyChanged) {
      _bumpMessages();
    }
  }


  Future<void> _pickReplyChat() async {
    final reply = _replyTo.value;
    if (reply == null) return;
    if (reply.id.startsWith('temp_')) {
      showCustomNotification(context, 'Сообщение ещё не отправлено');
      return;
    }

    final sourceChatId = _textSend.replySourceChatId ?? widget.chatId;
    final target = await openForwardScreen(context: context);
    if (target == null || !mounted) return;

    if (target.chatId == widget.chatId) {
      _textSend.replySourceChatId = sourceChatId == widget.chatId ? null : sourceChatId;
      _messageFocusNode.requestFocus();
      return;
    }

    await chats.ensureChatCached(api, _myId, target.chatId);
    if (!mounted) return;
    pushSwipeable(
      context,
      (_) => ChatScreen(
        chatId: target.chatId,
        name: target.name,
        imageUrl: target.imageUrl,
        chatType: target.chatType,
        replyRequest: ReplyRequest(sourceChatId: sourceChatId, message: reply),
      ),
    );
  }

  void _openSenderProfile(int senderId) {
    if (senderId == 0 || senderId == _myId) return;
    unawaited(
      openContactDialogProfile(
        context,
        contactId: senderId,
        name:
            ContactCache.get(senderId) ??
            AppLocalizations.of(context)!.userFallbackName(senderId),
        avatarUrl: ContactCache.getAvatar(senderId),
      ),
    );
  }

  void _openForwardedSource(ForwardedMessageAttachment forwarded) {
    if (forwarded.isChannel) {
      unawaited(_openForwardedChannel(forwarded));
      return;
    }
    final senderId = forwarded.originalSenderId;
    if (senderId == 0 || senderId == _myId) return;
    unawaited(
      openContactDialogProfile(
        context,
        contactId: senderId,
        name:
            forwarded.originalSenderName ??
            ContactCache.get(senderId) ??
            AppLocalizations.of(context)!.userFallbackName(senderId),
        avatarUrl:
            forwarded.originalSenderAvatar ?? ContactCache.getAvatar(senderId),
      ),
    );
  }

  Future<void> _openForwardedChannel(
    ForwardedMessageAttachment forwarded,
  ) async {
    final sourceChatId = forwarded.originalChatId;
    if (sourceChatId == null) {
      showCustomNotification(context, 'Канал недоступен');
      return;
    }
    final sourceMessageId = forwarded.originalMessageId;
    if (sourceChatId == widget.chatId) {
      if (sourceMessageId == null) return;
      await _scrollNav.goTo(
        sourceMessageId,
        time: forwarded.originalTime ?? 0,
      );
      return;
    }

    if (!await chats.canOpenForwardSource(api, _myId, forwarded)) {
      if (!mounted) return;
      await showNoChatAccessCard(context);
      return;
    }
    if (!mounted) return;

    await chats.ensureChatCached(api, _myId, sourceChatId);
    if (!mounted) return;
    final cached = await chats.getChat(_myId, sourceChatId);
    if (!mounted) return;
    final channel = cached.isEmpty ? null : cached.first;
    pushSwipeable(
      context,
      (_) => ChatScreen(
        chatId: sourceChatId,
        name: channel?.title ?? forwarded.originalSenderName ?? 'Канал',
        imageUrl: channel?.iconUrl ?? forwarded.originalSenderAvatar ?? '',
        chatType: channel?.type ?? 'CHANNEL',
        initialMessageId: sourceMessageId,
        initialMessageTime: forwarded.originalTime,
      ),
    );
  }

  void _openStickerPack(StickerAttachment sticker) {
    final stickerId = int.tryParse(sticker.stickerId ?? '');
    if (stickerId == null) {
      showCustomNotification(context, 'Стикерпак недоступен');
      return;
    }
    showStickerPackSheet(
      context,
      stickerId: stickerId,
      knownSetId: int.tryParse(sticker.stickerPackId ?? ''),
    );
  }

  final Map<String, GlobalKey> _messageKeys = {};
  final Map<String, ({Object signature, Widget row})> _rowCache = {};
  final Map<Key, int> _itemPositions = {};

  GlobalKey _keyForMessage(String messageId) =>
      _messageKeys.putIfAbsent(messageId, () => GlobalKey());

  String? _messageIdOfItem(Object item) =>
      item is _MessageItem ? item.message.id : null;

  void _openSearch() {
    if (_search.searchMode.value || _selectionMode) return;
    // #***! запрос уходит на сервер, а сервер видит только шифртекст
    if (_encryptionEnabled) {
      showCustomNotification(
        context,
        AppLocalizations.of(context)!.e2eeSearchBlocked,
      );
      return;
    }
    _search.searchMode.value = true;
    _searchAnim.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _search.searchMode.value) _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    if (!_search.searchMode.value) return;
    _searchFocusNode.unfocus();
    _searchAnim.reverse();
    _search.reset();
  }

  Future<void> _openSearchResult(MessageSearchResult result) async {
    _closeSearch();
    await _scrollNav.goTo(result.id, time: result.time);
  }


  String _searchSenderName(int senderId) {
    if (senderId == _myId) return 'Вы';
    final cached = ContactCache.get(senderId);
    if (cached != null && cached.isNotEmpty) return cached;
    if (widget.chatType == 'DIALOG') return widget.name;
    return 'Пользователь';
  }

  String? _searchSenderAvatar(int senderId) {
    final cached = ContactCache.getAvatar(senderId);
    if (cached != null && cached.isNotEmpty) return cached;
    if (senderId != _myId &&
        widget.chatType == 'DIALOG' &&
        widget.imageUrl.isNotEmpty) {
      return widget.imageUrl;
    }
    return null;
  }

  int _firstUnreadIndex() {
    final anchor = _unreadAnchorTime;
    if (anchor == null) return -1;
    return _messages.indexWhere((m) => m.time > anchor);
  }

  Widget _messageRow(_MessageItem item, int visibleCount, double listWidth) {
    if (!_iosFastPath) return _buildMessageRow(item, visibleCount, listWidth);
    final signature = _rowSignature(item, visibleCount, listWidth);
    final cached = _rowCache[item.message.id];
    if (cached != null && cached.signature == signature) return cached.row;
    final row = _buildMessageRow(item, visibleCount, listWidth);
    _rowCache[item.message.id] = (signature: signature, row: row);
    return row;
  }

  Object _rowSignature(_MessageItem item, int visibleCount, double listWidth) {
    final message = item.message;
    final index = item.index;
    return (
      message,
      index > 0 ? _messages[index - 1] : null,
      index < visibleCount - 1 ? _messages[index + 1] : null,
      listWidth,
      chat,
      _myId,
      _previewChat,
      _effectiveStatus(message),
      _photoProgressFor(message),
      _reactionNotifierFor(message),
      _commentsLabelFor(message.id),
      _canEditMessage(message),
      _canPinMessage(message),
      _canLinkMessage(message),
      _canShowReadBy(message),
      _deletingIds.contains(message.id),
      _lastSentId == message.id,
      _prank.bubbleId == message.id,
    );
  }

  int? _findItemIndex(Key key) => _itemPositions[key];

  Widget _buildMessageRow(
    _MessageItem msgItem,
    int visibleCount,
    double listWidth,
  ) {
    final message = msgItem.message;
    final msgIndex = msgItem.index;
    final isMe = message.senderId == _myId;
    final prevMessage = msgIndex > 0
        ? _messages[msgIndex - 1]
        : null;
    final nextMessage = msgIndex < visibleCount - 1
        ? _messages[msgIndex + 1]
        : null;

    final bool isChannelPost =
        !_commentsMode &&
        (chat?.type ?? widget.chatType) ==
            'CHANNEL' &&
        !message.isControl;
    final bool isCommentedPost =
        _commentsMode &&
        message.id == widget.commentPostId;

    final bubble = MessageBubble(
      message: message,
      isMe: isMe,
      myId: _myId,
      prevMessage: prevMessage,
      nextMessage: nextMessage,
      chatType: _commentsMode
          ? 'CHAT'
          : (chat?.type ?? 'CHAT'),
      chatId: widget.chatId,
      photoActions: _photoActions,
      overrideStatus: _effectiveStatus(message),
      otherReadTime: _otherReadTime,
      reactionsListenable: _reactionNotifierFor(
        message,
      ),
      reactionAnimation: _reactionAnimation,
      uploadProgress: _photoProgressFor(message),
      onReplyTap: (id) => unawaited(
        _scrollNav.goTo(
          id,
          time: message.replyInfo?.time ?? 0,
          fromId: message.id,
        ),
      ),
      resolveLocalMessage: _chatController.byId,
      listWidth: listWidth,
      onAvatarTap: _openSenderProfile,
      onForwardedSourceTap: _openForwardedSource,
      onStickerTap: _openStickerPack,
      onReactionTap: message.isControl
          ? null
          : (emoji) =>
                _reactToMessage(message, emoji),
      peerName: widget.name,
      peerAvatarUrl: widget.imageUrl,
      senderNameOverride: isCommentedPost
          ? widget.name
          : null,
      senderAvatarOverride: isCommentedPost
          ? widget.imageUrl
          : null,
      textSelection: _textSelection,
      textSelectionDrag: _textSelectionDrag,
      onExitTextSelection: _exitTextSelection,
      commentsLabel: isChannelPost
          ? _commentsLabelFor(message.id)
          : null,
      onCommentsTap: isChannelPost
          ? () => _openComments(message)
          : null,
    );

    final canReport = !isMe && !message.isControl;
    final reportTypeId = _complaintTypeId(
      chat?.type ?? widget.chatType,
    );

    final pressable = SelectableMessageRow(
      message: message,
      isMe: isMe,
      composerHeight: _composerHeight,
      selectedIds: _selectedIds,
      selectionAnim: _selectionAnim,
      isSelectionActive: () => _selectionMode,
      onToggleSelection: () =>
          _toggleSelection(message),
      onEnterSelection: () =>
          _enterSelection(message),
      onStartTextSelection: (pos) =>
          _startTextSelection(message, pos),
      onDragTextSelection: (pos) =>
          _textSelectionDrag.value = pos,
      onDelete: () =>
          _confirmDeleteMessage(message.id, isMe),
      allowDelete:
          !message.isControl &&
          (isMe ||
              chat?.type != 'CHANNEL' ||
              (chat?.iAmAdmin(_myId) ?? false)),
      onEdit: _canEditMessage(message)
          ? () => _startEditMessage(message)
          : null,
      onReply: message.isControl || !_canReply
          ? null
          : () => _textSend.startReply(message),
      onForward:
          message.isControl ||
              (chat?.forwardDisabled ?? false)
          ? null
          : () => _forwardMessages([message]),
      allowCopy: !(chat?.copyDisabled ?? false),
      onMarkUnread: message.isControl
          ? null
          : () => _markMessageUnread(message),
      onPin: _canPinMessage(message)
          ? () => _togglePinMessage(message)
          : null,
      onCopyLink: _canLinkMessage(message)
          ? () => _copyMessageLink(message)
          : null,
      isPinned: () =>
          chat?.pinnedMsgId ==
          int.tryParse(message.id),
      loadReadBy: _canShowReadBy(message)
          ? () => _loadReadBy(message)
          : null,
      onReaderTap: _openSenderProfile,
      loadReportReasons: canReport
          ? () => _loadReportReasons(reportTypeId)
          : null,
      onReport: canReport
          ? (reasonId) => _reportMessage(
              message,
              reportTypeId,
              reasonId,
            )
          : null,
      onReact: message.isControl
          ? null
          : (emoji) =>
                _reactToMessage(message, emoji),
      reactions: _reactionNotifierFor(message),
      child: bubble,
    );

    final isChannel =
        (chat?.type ?? widget.chatType) == 'CHANNEL';
    final swipeable =
        (message.isControl ||
            isChannel ||
            !_canReply)
        ? pressable
        : SwipeToReply(
            isMe: isMe,
            onReply: () => _textSend.startReply(message),
            child: pressable,
          );

    final Widget child;
    if (_deletingIds.contains(message.id)) {
      child = DeletingMessageAnimation(
        key: ValueKey('del_${message.id}'),
        onComplete: () => _finalizeDelete(message.id),
        child: IgnorePointer(child: swipeable),
      );
    } else if (message.id == _lastSentId) {
      child = SentMessageAnimation(
        key: ValueKey('anim_${message.id}'),
        onComplete: () {
          if (mounted) {
            _lastSentId = null;
            _bumpMessageRows();
          }
        },
        child: swipeable,
      );
    } else {
      child = swipeable;
    }

    final highlightable =
        ValueListenableBuilder<String?>(
          valueListenable: _scrollNav.highlightMessageId,
          builder: (context, hl, c) =>
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 250,
                ),
                color: hl == message.id
                    ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12)
                    : Colors.transparent,
                child: c,
              ),
          child: child,
        );

    final builtItem = RepaintBoundary(
      key: ValueKey('msg_${message.id}'),
      child: KeyedSubtree(
        key: _keyForMessage(message.id),
        child: highlightable,
      ),
    );
    if (widget.preview) return IgnorePointer(child: builtItem);
    return message.id == _prank.bubbleId
        ? KeyedSubtree(
            key: _prank.bubbleKey,
            child: builtItem,
          )
        : builtItem;
  }

  List<Object> _buildCombinedItems() {
    final visible = _visibleMessageCount;
    final key = Object.hash(
      _messagesRev.value,
      _messages.length,
      visible,
      _unreadAnchorTime,
    );
    final cached = _combinedItemsCache;
    if (cached != null && _combinedItemsKey == key) return cached;

    final unreadIndex = _firstUnreadIndex();

    final List<Object> items = [];
    final Set<int> usedDates = {};

    for (int i = 0; i < visible; i++) {
      final msg = _messages[i];
      final msgDate = DateTime.fromMillisecondsSinceEpoch(msg.time);
      final dayMillis = DateTime(
        msgDate.year,
        msgDate.month,
        msgDate.day,
      ).millisecondsSinceEpoch;

      bool needSeparator = i == 0;
      if (!needSeparator) {
        final prevDate = DateTime.fromMillisecondsSinceEpoch(
          _messages[i - 1].time,
        );
        final prevDayMillis = DateTime(
          prevDate.year,
          prevDate.month,
          prevDate.day,
        ).millisecondsSinceEpoch;
        needSeparator = dayMillis != prevDayMillis;
      }

      if (needSeparator) {
        _separatorKeys.putIfAbsent(dayMillis, () => GlobalKey());
        usedDates.add(dayMillis);
        items.add(
          _DateSeparatorItem(
            DateTime.fromMillisecondsSinceEpoch(dayMillis),
            _separatorKeys[dayMillis]!,
          ),
        );
      }

      if (i == unreadIndex) {
        items.add(const _UnreadSeparatorItem());
      }

      items.add(_MessageItem(msg, i));
    }

    _separatorKeys.removeWhere((k, _) => !usedDates.contains(k));
    if (_iosFastPath) _indexItemPositions(items);
    _combinedItemsCache = items;
    _combinedItemsKey = key;
    return items;
  }

  void _indexItemPositions(List<Object> items) {
    _itemPositions.clear();
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final Key key = switch (item) {
        _MessageItem(:final message) => ValueKey('msg_${message.id}'),
        _DateSeparatorItem(:final key) => key,
        _ => _unreadSeparatorKey,
      };
      _itemPositions[key] = i;
    }
  }

  void _onScrollForDate() {
    if (!_scrollController.hasClients) return;

    _floatingDateTimer?.cancel();
    _floatingDateTimer = Timer(FloatingDateBehavior.idleHideDelay, () {
      if (mounted) _floatingDateAnimController.reverse();
    });

    if (_floatingDateScheduled) return;
    _floatingDateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _floatingDateScheduled = false;
      _updateFloatingDate();
    });
  }

  void _updateFloatingDate() {
    if (!mounted || _separatorKeys.isEmpty) return;
    DateTime? result;

    final listRenderBox = _listKey.currentContext?.findRenderObject();
    if (listRenderBox is! RenderBox) return;

    _separatorKeys.forEach((dayMillis, gkey) {
      final ctx = gkey.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject();
      if (box is! RenderBox) return;
      final pos = box.localToGlobal(Offset.zero, ancestor: listRenderBox);
      if (pos.dy + box.size.height < 4) {
        final date = DateTime.fromMillisecondsSinceEpoch(dayMillis);
        if (result == null || date.isAfter(result!)) {
          result = date;
        }
      }
    });

    if (result == null) return;

    final bool dateChanged = result != _floatingDate.value;
    _floatingDate.value = result;

    if (dateChanged) {
      _floatingDateAnimController.forward(from: 0);
    } else {
      _floatingDateAnimController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _prank.active
        ? _prank.pinkTheme(Theme.of(context))
        : Theme.of(context);
    final cs = theme.colorScheme;
    final underlap = _effectiveChrome != ChatChromeStyle.color;

    // TODO: Локализация
    // TODO: Cклонения
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final bottomInset = _keyboardReserve > 0
        ? math.max(viewInsets.bottom, _keyboardReserve)
        : viewInsets.bottom;
    return ListenableBuilder(
      listenable: Listenable.merge([
        _selectedIds,
        _search.searchMode,
        _textSelection,
      ]),
      builder: (context, child) => PopScope(
        canPop:
            _selectedIds.value.isEmpty &&
            !_search.searchMode.value &&
            _textSelection.value == null,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_search.searchMode.value) {
            _closeSearch();
          } else if (_textSelection.value != null) {
            _exitTextSelection();
          } else {
            _clearSelection();
          }
        },
        child: child!,
      ),
      child: MediaQuery(
        data:
            context
                .getInheritedWidgetOfExactType<MediaQuery>()!
                .data
                .copyWith(
                  viewInsets: viewInsets.copyWith(bottom: bottomInset),
                ),
        child: Theme(
          data: theme,
          child: RepaintBoundary(
            key: _prank.captureKey,
            child: ValueListenableBuilder<bool>(
              valueListenable: AppSwipeBackDesktop.current,
              builder: (context, desktopSwipe, child) => SwipeToPop(
                enabled: widget.embedded && desktopSwipe,
                onPop: widget.onClose,
                child: child!,
              ),
              child: AnimatedBuilder(
                animation: _searchAnim,
                child: LottieHoldScope(
                  isHeld: _animojiHold,
                  child: ChatBodyLayout(
                    underlap: underlap,
                    cs: cs,
                    chat: chat,
                    effectiveChrome: _effectiveChrome,
                    liquidChrome: _liquidChrome,
                    pillBackdrop: _pillBackdrop,
                    myId: _myId,
                    onJumpToPinnedMessage: _jumpToPinnedMessage,
                    onRevealPlayingMessage: _revealPlayingMessage,
                    onUnpinCurrentMessage: _unpinCurrentMessage,
                    onJoinCall: _commentsMode ? null : _joinChatCall,
                    composerFrosted: _composerFrosted,
                    composerHeight: _composerHeight,
                    pinnedBannerHeight: _pinnedBannerHeight,
                    composerAreaBuilder: (context) => widget.preview
                        ? const SizedBox.shrink()
                        : _composerAreaWidget(),
                    messagesArea: _buildMessagesArea(),
                    mentionPanel: _mentionPanel,
                    commandPanel: _commandPanel,
                    note: _note,
                    searchAnim: _searchAnim,
                    search: _search,
                    onOpenSearchResult: _openSearchResult,
                    searchSenderName: _searchSenderName,
                    searchSenderAvatar: _searchSenderAvatar,
                    useNativeSearch: NativeChatBridge.isEligible,
                    chromeVignette: _chromeVignette,
                    composerPaintsSurface: _composerPaintsSurface,
                    pinnedBannerTop: _pinnedBannerTop(),
                    defaultEdgeVignetteHeight: _defaultEdgeVignetteHeight(),
                    wallpaper: _wallpaper,
                  ),
                ),
                builder: (context, body) => Scaffold(
                  backgroundColor: cs.surface,
                  extendBodyBehindAppBar: underlap,
                  appBar: _previewSafeBar(ChatAppBar(
                    cs: cs,
                    searchAnim: _searchAnim,
                    selectionAnim: _selectionAnim,
                    chrome: _effectiveChrome,
                    chromeVignette: _chromeVignette,
                    liquidChrome: _liquidChrome,
                    barBackdrop: _barBackdrop,
                    pillBackdrop: _pillBackdrop,
                    glossyChrome: _glossyChrome,
                    iosGlass: AppIosGlass.active.value,
                    embedded: widget.embedded,
                    chatId: widget.chatId,
                    heroTag: _profileHeroTag,
                    name: _headerName(),
                    imageUrl: _headerAvatarUrl(),
                    chatType: widget.chatType,
                    isOfficial: chat?.isOfficial ?? false,
                    encrypted: _encryptionEnabled,
                    verified: _e2eeVerified,
                    myId: _myId,
                    headerStatus: _headerStatusNotifier,
                    scheduledCount: _scheduledCount,
                    otherUnread: _otherUnread,
                    showCall:
                        !_commentsMode &&
                        widget.chatType == 'DIALOG' &&
                        widget.chatId != 0 &&
                        !_peerIsBot,
                    onClose: widget.onClose,
                    onOpenInfo: _commentsMode ? () {} : _openChatInfo,
                    onOpenScheduled: _openScheduledMessages,
                    onCall: _startCall,
                    onMenu: _commentsMode ? (_) {} : _openChatMenu,
                    useNativeHeader:
                        NativeChatBridge.isEligible && AppIosGlass.active.value,
                    onMenuAt: _commentsMode ? null : _openChatMenuAt,
                    selectedIds: _selectedIds,
                    copyableSelection: _copyableSelection,
                    singleEditable: _singleEditable,
                    onClearSelection: _clearSelection,
                    onCopySelected: _copySelected,
                    onEditSelected: _editSelected,
                    onDeleteSelected: _deleteSelected,
                    search: _search,
                    searchFocusNode: _searchFocusNode,
                    onCloseSearch: _closeSearch,
                  )),
                  body: body,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _pinnedBannerTop() {
    final glossy = _glossyChrome;
    return MediaQuery.paddingOf(context).top +
        ChatAppBar.headerHeight(
                glossy: glossy,
                ios: AppIosGlass.active.value,
              ) +
        (AppIosGlass.active.value ? _iosPinnedBannerGap : -_pinnedBannerLift);
  }

  double _defaultEdgeVignetteHeight() {
    final glossy = _glossyChrome;
    final ios = AppIosGlass.active.value;
    final base = MediaQuery.paddingOf(context).top +
        ChatAppBar.headerHeight(glossy: glossy, ios: ios);
    return ios ? base + IosScrollEdgeFade.headerOverlap : base;
  }

  Widget _buildMessagesArea() {
    final showShimmer = _messages.isEmpty
        ? _isLoading
        : (_awaitingPosition || _scrollNav.navigatingToTarget);
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: showShimmer ? 0.0 : 1.0,
          child: PerfScrollProbe(
            tag: 'чат',
            hidden: showShimmer,
            child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _scrollNav.bumpGestureEpoch();
                _chatScrollOpaqueHold?.cancel();
                if (!_chatScrollActive.value) {
                  _chatScrollActive.value = true;
                }
              } else if (notification is ScrollUpdateNotification ||
                  notification is OverscrollNotification) {
                _chatScrollOpaqueHold?.cancel();
                if (!_chatScrollActive.value) {
                  _chatScrollActive.value = true;
                }
              } else if (notification is ScrollEndNotification) {
                _readMarker.flush();
                _chatScrollOpaqueHold?.cancel();
                _chatScrollOpaqueHold = Timer(
                  const Duration(milliseconds: 120),
                  () {
                    if (mounted) _chatScrollActive.value = false;
                  },
                );
              }
              return false;
            },
            child: _buildMessagesList(),
          ),
          ),
        ),
        if (showShimmer)
          Positioned.fill(child: ShimmerLoading(shimmer: _shimmerController)),
        Positioned.fill(
          child: ValueListenableBuilder<int>(
            valueListenable: _messagesRev,
            builder: (context, _, _) => _buildEmptyState(),
          ),
        ),
      ],
    );
  }

  bool get _isPersonDialog =>
      !_commentsMode && widget.chatType == 'DIALOG' && widget.chatId != 0;

  Widget _buildEmptyState() {
    final empty = _messages.isEmpty && !_isLoading;
    final greetingDue =
        empty && _isPersonDialog && _peerKindKnown && !_peerIsBot;
    if (greetingDue) _greetingMounted = true;
    if (_greetingMounted) {
      return GreetingStickerCard(
        accountId: _myId,
        visible: greetingDue,
        onSend: _mediaSend.sendSticker,
      );
    }
    if (!empty) return const SizedBox.shrink();
    return IgnorePointer(
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.chatEmptyTitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListenableBuilder(
      listenable: NativeChatBridge.eligibility,
      builder: (context, _) {
        if (!IosGlass.of(context) ||
            !NativeChatBridge.isEligible ||
            widget.preview) {
          return _messageListWidget ??= _ChatMessageList(
            this,
            key: _messageListKey,
          );
        }
        return ListenableBuilder(
          listenable: Listenable.merge([
            _messagesRev,
            _otherReadTime,
            _selectedIds,
            _composerHeight,
            _scrollNav.highlightMessageId,
            KometSettings.fullTimestamp,
          ]),
          builder: (context, _) => _buildNativeTranscript(),
        );
      },
    );
  }

  Widget _buildNativeTranscript() {
    final type = _commentsMode ? 'CHAT' : (chat?.type ?? widget.chatType);
    final visible = _messages.take(_visibleMessageCount).toList(growable: false);
    _scheduleNativePollFetches(visible);
    _scheduleNativeNotes(visible);
    final items = buildNativeChatItems(
      messages: visible,
      myId: _myId,
      now: DateTime.now(),
      unreadAnchorMillis: _unreadAnchorTime,
      selected: _selectedIds.value,
      highlightId: _scrollNav.highlightMessageId.value,
      showSenders: type != 'DIALOG',
      canReply: _canReply && type != 'CHANNEL',
      withSeconds: KometSettings.fullTimestamp.value,
      otherReadMillis: _otherReadTime.value,
      nameOf: (id) {
        if (id == _myId) return 'Вы';
        final cached = ContactCache.get(id);
        if (cached != null && cached.isNotEmpty) return cached;
        if (type == 'DIALOG') return widget.name;
        return '';
      },
      avatarOf: ContactCache.getAvatar,
      statusOf: _effectiveStatus,
      reactionOf: (message) => _reactionNotifierFor(message).value,
      transcriptOf: (id) {
        final cached = TranscriptionCache.get(id);
        if (cached == null) return null;
        return (
          text: cached.text ?? '',
          expanded: TranscriptionCache.isExpanded(id),
        );
      },
      playingId: _nativePlayingVoiceId(),
      progressId: _nativeVoiceId,
      voiceProgress: _nativeVoiceProgress,
      pollOf: pollsModule.get,
      notePathOf: (message) => _notePaths[message.id],
      commentsOf: (message) {
        final channel = !_commentsMode && type == 'CHANNEL' && !message.isControl;
        return channel ? _commentsLabelFor(message.id) : null;
      },
    );
    return NativeChatView(
      items: items,
      highlightId: _scrollNav.highlightMessageId.value,
      commands: _nativeChatCommands,
      chrome: {
        'accent': Theme.of(context).colorScheme.primary.toARGB32(),
        'bottomInset': _composerHeight.value,
        'selecting': _selectionMode,
      },
      callbacks: NativeChatCallbacks(
        onOpen: _onNativeOpen,
        onLongPress: _showNativeMessageActions,
        onReply: (id) {
          final message = _chatController.byId(id);
          if (message != null) _textSend.startReply(message);
        },
        onReaction: (id, emoji) {
          final message = _chatController.byId(id);
          if (message != null) _reactToMessage(message, emoji);
        },
        onSelect: (id) {
          final message = _chatController.byId(id);
          if (message == null) return;
          if (_selectionMode) {
            _toggleSelection(message);
          } else {
            _enterSelection(message);
          }
        },
        onReplyJump: (id) {
          final message = _chatController.byId(id);
          unawaited(_scrollNav.goTo(id, time: message?.time ?? 0));
        },
        onMedia: _openNativeMedia,
        onLink: (url) => unawaited(openExternalUrl(context, url)),
        onMention: _openSenderProfile,
        onPoll: (id, answers) => unawaited(_voteNativePoll(id, answers)),
        onKeyboard: _onNativeKeyboard,
        onTranscribe: (id) => unawaited(_nativeTranscribe(id)),
        onVoice: _toggleNativeVoice,
        onComments: (id) {
          final message = _chatController.byId(id);
          if (message != null) _openComments(message);
        },
        onSticker: _openNativeSticker,
        onAvatar: _openSenderProfile,
        onLoadOlder: _nativeLoadOlder,
        onLoadNewer: () {
          if (_chatController.hasNewer && !_chatController.isLoadingNewer) {
            unawaited(_loadNewerHistory());
          }
        },
        onNearBottom: (atBottom) {
          _scrollNav.nativeNearBottom = atBottom;
          if (!atBottom) _userDidScroll = true;
          _scrollNav.updateScrollDownVisible();
          if (atBottom) _readMarker.flush();
        },
        onVisible: _markVisibleNative,
      ),
    );
  }

  EdgeInsets _messagesListPadding(BuildContext context) {
    if (AppChatChrome.current.value == ChatChromeStyle.color) {
      return const EdgeInsets.symmetric(vertical: 8);
    }
    final topInset = MediaQuery.paddingOf(context).top;
    return EdgeInsets.only(top: topInset + 8, bottom: 8);
  }

  double _floatingDateTop(double pinnedHeight) {
    if (AppChatChrome.current.value == ChatChromeStyle.color) {
      final glossy = _glossyChrome;
      return glossy ? 2 : 4;
    }
    final hasBanner =
        chat?.hasPinnedMessage == true || _showsCallBanner;
    if (hasBanner && pinnedHeight > 0) {
      return _pinnedBannerTop() + pinnedHeight + 2;
    }
    return _pinnedBannerTop() + 2;
  }


  Widget _buildMessagesListContent() {
    if (_messages.isEmpty) return const SizedBox.shrink();

    final items = _buildCombinedItems();
    final visibleCount = _visibleMessageCount;

    return LayoutBuilder(
      builder: (context, listConstraints) =>
          _buildMessagesStack(items, visibleCount, listConstraints.maxWidth),
    );
  }

  Widget _buildMessagesStack(
    List<Object> items,
    int visibleCount,
    double listWidth,
  ) {
    return Stack(
      key: _listKey,
      children: [
        ValueListenableBuilder<double>(
          valueListenable: AppCacheExtent.current,
          builder: (context, userCacheExtent, _) =>
              ValueListenableBuilder<double?>(
                valueListenable: _scrollNav.jumpCacheExtent,
                builder: (context, jumpExtent, _) {
                  final cacheExtent =
                      jumpExtent != null && jumpExtent < userCacheExtent
                      ? jumpExtent
                      : userCacheExtent;
                  return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: AnchoredMessageList(
                    controller: _scrollController,
                    cacheExtent: cacheExtent,
                    padding: _messagesListPadding(context),
                    epoch: _scrollNav.listEpoch,
                    itemCount: items.length,
                    anchorIndex: _scrollNav.anchorIndexIn(
                      items,
                      _messageIdOfItem,
                    ),
                    loadingOlder: _isLoadingMore,
                    loadingNewer: _chatController.isLoadingNewer,
                    findItemIndex: _iosFastPath ? _findItemIndex : null,
                    bottomSpacer: ValueListenableBuilder<double>(
                      valueListenable: _composerHeight,
                      builder: (context, height, _) => SizedBox(
                        height: _composerUnderlap ? height : 0,
                      ),
                    ),
                    itemBuilder: (context, itemIndex) {
                              final item = items[itemIndex];

                              if (item is _DateSeparatorItem) {
                                return DateSeparatorLabel(
                                  key: item.key,
                                  date: item.date,
                                );
                              }

                              if (item is _UnreadSeparatorItem) {
                                return UnreadSeparatorBar(
                                  key: _unreadSeparatorKey,
                                );
                              }

                              return _messageRow(
                                item as _MessageItem,
                                visibleCount,
                                listWidth,
                              );
                            },
                    ),
                  );
                },
              ),
        ),
        ThrottledMessageScrollbar(
          controller: _scrollController,
          itemCountOf: () => _messages.length,
          jumpCacheExtent: _scrollNav.jumpCacheExtent,
        ),
        ValueListenableBuilder<double>(
          valueListenable: _pinnedBannerHeight,
          builder: (context, pinnedHeight, child) => Positioned(
            top: _floatingDateTop(pinnedHeight),
            left: 0,
            right: 0,
            child: child!,
          ),
          child: IgnorePointer(
            child: ValueListenableBuilder<DateTime?>(
              valueListenable: _floatingDate,
              builder: (context, date, _) {
                if (date == null) return const SizedBox.shrink();
                return AnimatedBuilder(
                  animation: _floatingDateCurved,
                  builder: (context, child) {
                    final t = _floatingDateCurved.value;
                    return Opacity(
                      opacity: t,
                      child: Transform.scale(
                        scale: 0.82 + 0.18 * t,
                        child: child,
                      ),
                    );
                  },
                  child: DateSeparatorLabel(date: date, floating: true),
                );
              },
            ),
          ),
        ),
        ScrollDownButton(
          composerHeight: _composerHeight,
          materialComposer: _materialComposer,
          composerUnderlap: _composerUnderlap,
          frosted: _effectiveChrome == ChatChromeStyle.transparent,
          liquidChrome: _liquidChrome,
          pillBackdrop: _pillBackdrop,
          scrollDownCurved: _scrollDownCurved,
          newMessageCount: _scrollNav.newMessageCount,
          onTap: _scrollNav.onScrollDownTap,
        ),
      ],
    );
  }


  Future<void> _openAttachmentSheetScheduled() async {
    final when = await _pickScheduleTime();
    if (when == null || !mounted) return;
    await _openAttachmentSheet(scheduledTime: when.millisecondsSinceEpoch);
  }

  Future<void> _openAttachmentSheet({int? scheduledTime}) async {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final hadKeyboard = keyboard > 0;
    if (hadKeyboard) {
      setState(() => _keyboardReserve = keyboard);
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await showAttachmentSheet(
      context,
      title: widget.name,
      onSend: scheduledTime == null
          ? _mediaSend.sendPhotos
          : (picked, caption) =>
                _mediaSend.sendScheduledPhotos(picked, caption, scheduledTime),
      videoNote: scheduledTime == null
          ? VideoNoteSend(
              limit: const Duration(milliseconds: VideoNoteController.maxMs),
              send: _mediaSend.sendVideoNote,
            )
          : null,
      onSendSeparately: scheduledTime == null
          ? (picked, caption) =>
                _mediaSend.sendPhotos(picked, caption, separate: true)
          : (picked, caption) => _mediaSend.sendScheduledPhotos(
              picked,
              caption,
              scheduledTime,
              separate: true,
            ),
      onPickFile: _encryptionEnabled
          ? () => _refuseUnencrypted('Файлы')
          : (scheduledTime == null
                ? _pickAndUploadFile
                : () => _pickAndUploadFile(scheduledTime: scheduledTime)),
      onShareLocation: _encryptionEnabled
          ? () => _refuseUnencrypted('Геолокацию')
          : _mediaSend.shareLocation,
      onCreatePoll: _encryptionEnabled
          ? () => _refuseUnencrypted('Опросы')
          : _createPoll,
      onSendContact: _encryptionEnabled
          ? (_) => _refuseUnencrypted('Контакты')
          : _mediaSend.sendContact,
    );
    if (!mounted || !hadKeyboard) return;
    _messageFocusNode.requestFocus();
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) setState(() => _keyboardReserve = 0);
  }

  void _toggleStickerPanel() {
    if (_stickers.showPanel.value) {
      _stickers.hide();
      if (_keyboardBeforeStickers) _messageFocusNode.requestFocus();
      return;
    }
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    _keyboardBeforeStickers = keyboard > 120 || _messageFocusNode.hasFocus;
    if (keyboard > 120) _stickers.setBaseHeight(keyboard);
    FocusManager.instance.primaryFocus?.unfocus();
    _stickers.showPanel.value = true;
  }

  void _insertPlainEmoji(String emoji) {
    _messageController.insertPlainText(emoji);
  }

  void _insertAnimoji(Animoji animoji) {
    _messageController.insertAnimoji(animoji);
    unawaited(animojiModule.noteUsed(animoji));
    Haptics.selection();
  }

  Future<void> _createPoll() async {
    final draft = await showCreatePollSheet(context);
    if (draft == null || !mounted) return;
    await _mediaSend.sendAttachMessage(
      [PollAttachment(pollId: 0, title: draft.title)],
      () => messagesModule.sendPollMessage(
        widget.chatId,
        draft.title,
        draft.answers,
        multiple: draft.multiple,
        anonymous: draft.anonymous,
      ),
    );
  }

  void _refuseUnencrypted(String what) {
    if (!mounted) return;
    _showAttachmentPanel.value = false;
    showCustomNotification(context, '$what пока нельзя зашифровать');
  }

  ContextMenuButtonItem? _pasteMenuItem(
    BuildContext context,
    EditableTextState editableState,
  ) {
    if (!ClipboardMedia.supported) return null;
    return ContextMenuButtonItem(
      label: AppLocalizations.of(context)!.composerPasteAttachment,
      onPressed: () {
        editableState.hideToolbar();
        unawaited(_pasteClipboardMedia());
      },
    );
  }

  Future<bool> _handlePasteMedia() async {
    if (!await ClipboardMedia.hasMedia()) return false;
    unawaited(_pasteClipboardMedia());
    return true;
  }

  Future<void> _pasteClipboardMedia() async {
    if (_pastePending) return;
    _pastePending = true;
    try {
      final payload = await ClipboardMedia.read();
      if (!mounted) return;
      final items = payload == null
          ? const <PastedAttachment>[]
          : await materializeClipboardMedia(payload);
      if (!mounted) return;
      await _offerPastedAttachments(items);
    } finally {
      _pastePending = false;
    }
  }

  Future<void> _insertKeyboardContent(KeyboardInsertedContent content) async {
    if (_pastePending) return;
    _pastePending = true;
    try {
      final data = content.data;
      final stored = data == null || data.isEmpty
          ? null
          : await storePastedImage(
              ClipboardImageData(
                bytes: data,
                extension: pastedImageExtension(content.mimeType),
              ),
            );
      if (!mounted) return;
      await _offerPastedAttachments(stored == null ? const [] : [stored]);
    } finally {
      _pastePending = false;
    }
  }

  Future<void> _offerPastedAttachments(List<PastedAttachment> items) async {
    if (_myId == 0) return;
    if (items.isEmpty) {
      showCustomNotification(
        context,
        AppLocalizations.of(context)!.pasteAttachFailed,
      );
      return;
    }

    final media = items.where((it) => it.isMedia).toList();
    final documents = items.where((it) => !it.isMedia).toList();
    if (_encryptionEnabled && documents.isNotEmpty) {
      _refuseUnencrypted('Файлы');
      if (media.isEmpty) return;
      documents.clear();
    }

    final caption = await showPastePreviewSheet(
      context,
      items: [...media, ...documents],
    );
    if (caption == null || !mounted) return;

    if (media.isNotEmpty) {
      await _mediaSend.sendPhotos(
        media
            .map((it) => PickedPhoto(item: GalleryItem.fromFile(it.file)))
            .toList(),
        caption,
      );
    }
    for (final document in documents) {
      if (!mounted) return;
      await _mediaSend.uploadAsFile(
        source: document.file,
        filename: document.name,
        size: document.size,
      );
    }
  }

  Future<void> _pickAndUploadFile({int? scheduledTime}) async {
    final result = await AppLock.instance.external(() => FilePicker.platform.pickFiles());
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;
    await _mediaSend.uploadAsFile(
      source: File(picked.path!),
      filename: picked.name,
      size: picked.size,
      scheduledTime: scheduledTime,
    );
  }

  void _nativeLoadOlder() {
    if (_historyAutoloadSuppressed || _scrollNav.busy || _isLoading) return;
    if (_commentsMode) {
      if (!_commentsLoadingMore && _commentsHasMore && _messages.isNotEmpty) {
        unawaited(_loadMoreComments());
      }
      return;
    }
    if (_isLoadingMore || !_hasMoreHistory || _messages.isEmpty) return;
    unawaited(_loadMoreHistory());
  }

  void _markVisibleNative(List<String> ids) {
    _syncNativeStickers(ids);
    if (_commentsMode || widget.preview) return;
    if (!mounted || _myId == 0 || ids.isEmpty) return;
    if (_awaitingPosition || !_initialPositionDone) return;
    if (_readMarker.held) return;
    CachedMessage? candidate;
    for (final id in ids) {
      final message = _chatController.byId(id);
      if (message == null || message.isControl) continue;
      if (candidate == null || message.time > candidate.time) candidate = message;
    }
    if (candidate == null) return;
    if (candidate.id == _messages.last.id &&
        _unreadAnchorTime != null &&
        _userDidScroll) {
      _unreadAnchorTime = null;
      _bumpMessages();
    }
    if (candidate.time <= _readMarkTime) return;
    _readMarkTime = candidate.time;
    var remaining = _messages
        .where((message) => message.time > _readMarkTime && message.senderId != _myId)
        .length;
    if (_chatController.hasNewer) {
      remaining = math.max(remaining, chat?.unreadCount ?? 0);
    }
    unawaited(
      chats.markReadUpTo(
        api,
        _myId,
        widget.chatId,
        candidate.id,
        candidate.time,
        remaining: remaining,
      ),
    );
  }

  void _onNativeOpen(String id) {
    final message = _chatController.byId(id);
    if (message == null) return;
    if (_selectionMode) {
      _toggleSelection(message);
      return;
    }
    if (message.isControl) {
      final userId = message.controlAttachment?.userId ?? message.senderId;
      if (userId != 0) _openSenderProfile(userId);
      return;
    }
    final kind = _nativeKind(message);
    if (kind == NativeChatKind.photo) {
      _openNativeMedia(id);
    } else if (kind == NativeChatKind.video || kind == NativeChatKind.videoNote) {
      unawaited(_openNativeVideo(message));
    } else if (kind == NativeChatKind.file) {
      unawaited(_openNativeFile(message));
    } else if (kind == NativeChatKind.location) {
      _openNativeLocation(message);
    } else if (kind == NativeChatKind.sticker) {
      _openNativeSticker(id);
    } else if (kind == NativeChatKind.voice) {
      _toggleNativeVoice(id);
    }
  }

  NativeChatKind _nativeKind(CachedMessage message) {
    final items = buildNativeChatItems(
      messages: [message],
      myId: _myId,
      now: DateTime.now(),
    );
    for (final item in items) {
      if (item.role == NativeChatRole.message) return item.kind;
    }
    return NativeChatKind.text;
  }

  void _openNativeMedia(String id, [int index = 0]) {
    final message = _chatController.byId(id);
    if (message == null || !mounted) return;
    final visuals = [
      for (final attachment in _nativeAttachments(message))
        if (attachment is PhotoAttachment ||
            (attachment is VideoAttachment && !attachment.isNote))
          attachment,
    ];
    if (index >= 0 && index < visuals.length && visuals[index] is VideoAttachment) {
      unawaited(_openNativeVideo(message));
      return;
    }
    final photos = visuals.whereType<PhotoAttachment>().toList(growable: false);
    if (photos.isEmpty) return;
    final photoIndex = visuals[index] is PhotoAttachment
        ? photos.indexOf(visuals[index] as PhotoAttachment)
        : 0;
    Navigator.of(context).push(
      iosPageRoute(
        context,
        builder: (_) => PhotoViewerScreen(
          photos: photos,
          initialIndex: photoIndex < 0 ? 0 : photoIndex,
          chatId: widget.chatId,
          message: message,
          actions: _photoActions,
          sourceName: widget.name,
          videoUserAgentProvider: () => api.session?.userAgent(),
        ),
      ),
    );
  }

  void _onNativePolls() {
    if (!mounted || !NativeChatBridge.isEligible) return;
    _bumpMessageRows();
  }

  void _syncNativeStickers(List<String> ids) {
    if (widget.preview) {
      _nativeStickers.setVisible(const {});
      return;
    }
    final rows = <NativeStickerPlay>[];
    for (final id in ids) {
      final message = _chatController.byId(id);
      if (message == null) continue;
      rows.add(NativeStickerPlay(id: id, lottieUrl: _stickerLottie(message)));
    }
    _nativeStickers.setVisible(nativeStickerPlays(rows));
  }

  String? _stickerLottie(CachedMessage message) {
    for (final attachment in _nativeAttachments(message)) {
      if (attachment is! StickerAttachment) continue;
      final url = attachment.lottieUrl;
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  VideoAttachment? _videoNoteAttachment(CachedMessage message) {
    for (final attachment in _nativeAttachments(message)) {
      if (attachment is VideoAttachment && attachment.isNote) return attachment;
    }
    return null;
  }

  void _scheduleNativeNotes(List<CachedMessage> messages) {
    for (final message in messages) {
      if (_notePaths.containsKey(message.id) ||
          _noteLoads.contains(message.id) ||
          _noteMisses.contains(message.id)) {
        continue;
      }
      final video = _videoNoteAttachment(message);
      if (video == null) continue;
      final local = video.localPath;
      if (local != null && local.isNotEmpty && File(local).existsSync()) {
        _notePaths[message.id] = local;
        continue;
      }
      final videoId = video.videoId;
      final token = video.videoToken;
      if (videoId == null ||
          token == null ||
          token.isEmpty ||
          !VideoNotePreloader.autoLoads(video.duration)) {
        continue;
      }
      _noteLoads.add(message.id);
      unawaited(_loadNativeNote(message, videoId, token));
    }
  }

  Future<void> _loadNativeNote(
    CachedMessage message,
    int videoId,
    String token,
  ) async {
    final file = await VideoNotePreloader.load(
      'videonote_$videoId.mp4',
      () => messagesModule.getVideoUrl(
        messageId: message.id,
        chatId: message.chatId,
        token: token,
        videoId: videoId,
      ),
      cancelled: () => !mounted,
    );
    _noteLoads.remove(message.id);
    if (!mounted || file == null) {
      if (file == null) _noteMisses.add(message.id);
      return;
    }
    if (_notePaths[message.id] == file.path) return;
    _notePaths[message.id] = file.path;
    _bumpMessageRows();
  }

  void _scheduleNativePollFetches(List<CachedMessage> messages) {
    for (final message in messages) {
      for (final attachment in message.attachments ?? const <MessageAttachment>[]) {
        if (attachment is! PollAttachment || attachment.pollId == 0) continue;
        if (pollsModule.get(attachment.pollId) != null) continue;
        unawaited(pollsModule.fetch(widget.chatId, message.id, attachment.pollId));
      }
    }
  }

  Future<void> _voteNativePoll(String id, List<int> answers) async {
    if (answers.isEmpty) return;
    final message = _chatController.byId(id);
    if (message == null) return;
    PollAttachment? poll;
    for (final attachment in _nativeAttachments(message)) {
      if (attachment is PollAttachment) poll = attachment;
    }
    if (poll == null) return;
    final ok = await pollsModule.vote(widget.chatId, id, poll.pollId, answers);
    if (!ok && mounted) {
      showCustomNotification(context, 'Не удалось проголосовать');
    }
  }

  void _openNativeSticker(String id) {
    final message = _chatController.byId(id);
    if (message == null) return;
    final attachments = [
      ...?message.attachments,
      ...?message.forwardedAttachment?.originalAttachments,
    ];
    for (final attachment in attachments) {
      if (attachment is StickerAttachment) {
        _openStickerPack(attachment);
        return;
      }
    }
  }

  String? _nativePlayingVoiceId() {
    for (final entry in _nativeVoices.entries) {
      if (entry.value.playing.value) return entry.key;
    }
    return null;
  }

  void _onNativeVoiceTick() {
    if (!mounted || !NativeChatBridge.isEligible) return;
    final playingId = _nativePlayingVoiceId();
    if (playingId != null) _nativeVoiceId = playingId;
    final id = _nativeVoiceId;
    final audio = id == null ? null : _nativeVoices[id];
    final playing = audio?.playing.value ?? false;
    final total = audio?.duration.value ?? 0;
    final next = audio == null || total <= 0
        ? 0.0
        : (audio.position.value / total).clamp(0.0, 1.0);
    if ((next - _nativeVoiceProgress).abs() < 0.04 &&
        playing == _nativeVoicePlaying) {
      return;
    }
    _nativeVoiceProgress = next;
    _nativeVoicePlaying = playing;
    _bumpMessageRows();
  }

  void _toggleNativeVoice(String id) {
    final message = _chatController.byId(id);
    if (message == null) return;
    AudioAttachment? audio;
    for (final attachment in _nativeAttachments(message)) {
      if (attachment is AudioAttachment) audio = attachment;
    }
    var url = audio?.fileUrl ?? audio?.baseUrl ?? '';
    var durationMs = audio?.duration ?? 0;
    if (durationMs == 0 && url.isEmpty) {
      final voice = message.payload?['voice'];
      if (voice is Map) {
        final raw = voice['duration'];
        if (raw is int) durationMs = raw;
        url = voice['url']?.toString() ?? url;
      }
    }
    final controller = _nativeVoices.putIfAbsent(id, () {
      final created = MediaPlayback.instance.acquireVoice(
        cacheName: '${audio?.audioId ?? id}.ogg',
        resolveUrl: () async => url.isEmpty ? null : url,
        fallbackDuration: Duration(milliseconds: durationMs),
      );
      created.playing.addListener(_onNativeVoiceTick);
      created.position.addListener(_onNativeVoiceTick);
      return created;
    });
    MediaPlayback.instance.activateVoice(
      VoiceTrack(
        cacheName: '${audio?.audioId ?? id}.ogg',
        chatId: message.chatId,
        messageId: message.id,
        senderId: message.senderId,
        isMe: message.senderId == _myId,
        time: message.time,
        audio: controller,
      ),
    );
    unawaited(controller.toggle());
  }

  List<MessageAttachment> _nativeAttachments(CachedMessage message) => [
    ...?message.attachments,
    ...?message.forwardedAttachment?.originalAttachments,
  ];

  Future<void> _openNativeVideo(CachedMessage message) async {
    VideoAttachment? video;
    for (final attachment in _nativeAttachments(message)) {
      if (attachment is VideoAttachment) video = attachment;
    }
    final token = video?.videoToken;
    final videoId = video?.videoId;
    if (video == null || token == null || videoId == null) {
      if (mounted) showCustomNotification(context, 'Не удалось открыть видео');
      return;
    }
    final sources = await messagesModule.getVideoSources(
      messageId: message.id,
      chatId: message.chatId,
      token: token,
      videoId: videoId,
    );
    if (!mounted) return;
    if (sources.isEmpty) {
      showCustomNotification(context, 'Не удалось получить видео');
      return;
    }
    Navigator.of(context).push(
      iosPageRoute(
        context,
        fullscreenDialog: true,
        builder: (_) => PhotoViewerScreen.video(
          attachment: video!,
          initialVideoSources: sources,
          chatId: message.chatId,
          message: message,
          actions: _photoActions,
          sourceName: widget.name,
          videoUserAgentProvider: () => api.session?.userAgent(),
        ),
      ),
    );
  }

  Future<void> _openNativeFile(CachedMessage message) async {
    FileAttachment? file;
    for (final attachment in _nativeAttachments(message)) {
      if (attachment is FileAttachment) file = attachment;
    }
    final fileId = file?.fileId;
    if (file == null || fileId == null) {
      if (mounted) showCustomNotification(context, 'Не удалось определить файл');
      return;
    }
    final name = file.name?.trim();
    final title = name == null || name.isEmpty ? 'Файл' : name;
    final result = await openCachedFile(
      '${fileId}_$title',
      () => messagesModule.getFileUrl(
        messageId: message.id,
        chatId: message.chatId,
        fileId: fileId,
      ),
    );
    if (!mounted) return;
    final path = result.path;
    if (result.noAppToOpen && path != null) {
      await shareUnopenableFile(context, path);
      return;
    }
    if (!result.ok) {
      showCustomNotification(
        context,
        'Ошибка загрузки: ${result.error ?? 'не удалось открыть'}',
      );
    }
  }

  void _openNativeLocation(CachedMessage message) {
    for (final attachment in _nativeAttachments(message)) {
      if (attachment is! LocationAttachment) continue;
      final latitude = attachment.latitude;
      final longitude = attachment.longitude;
      if (latitude == null || longitude == null) return;
      unawaited(openLocationOnMap(context, latitude, longitude, zoom: attachment.zoom));
      return;
    }
  }

  Future<void> _nativeTranscribe(String id) async {
    if (TranscriptionCache.has(id)) {
      TranscriptionCache.setExpanded(id, !TranscriptionCache.isExpanded(id));
      _bumpMessageRows();
      return;
    }
    final message = _chatController.byId(id);
    AudioAttachment? audio;
    for (final attachment in message?.attachments ?? const <MessageAttachment>[]) {
      if (attachment is AudioAttachment) audio = attachment;
    }
    final audioId = audio?.audioId;
    if (audioId == null) return;
    try {
      final result = await messagesModule.requestTranscription(
        widget.chatId,
        int.tryParse(id) ?? 0,
        audioId,
      );
      TranscriptionCache.put(id, result, expanded: result.status == 1);
    } catch (error) {
      logger.w('native transcribe: $error');
    }
    if (mounted) _bumpMessageRows();
  }

  Future<void> _onNativeKeyboard(String id, int index) async {
    final message = _chatController.byId(id);
    if (message == null || !mounted) return;
    var cursor = 0;
    for (final attachment in message.attachments ?? const <MessageAttachment>[]) {
      if (attachment is! InlineKeyboardAttachment) continue;
      for (final row in attachment.rows) {
        for (final button in row) {
          if (button.text.isEmpty) continue;
          if (cursor != index) {
            cursor++;
            continue;
          }
          await _invokeNativeButton(message, attachment, button);
          return;
        }
      }
    }
  }

  Future<void> _invokeNativeButton(
    CachedMessage message,
    InlineKeyboardAttachment keyboard,
    InlineKeyboardButton button,
  ) async {
    switch (button.type) {
      case 'LINK':
        final url = button.url;
        if (url != null && url.isNotEmpty) await openExternalUrl(context, url);
        return;
      case 'CLIPBOARD':
        final payload = button.payload;
        if (payload == null || payload.isEmpty) return;
        await copyTextEntity(context, payload, 'Скопировано');
        return;
      case 'OPEN_APP':
        await _openNativeMiniApp(message, button);
        return;
      default:
        final callbackId = keyboard.callbackId;
        if (callbackId == null || callbackId.isEmpty) {
          showCustomNotification(context, 'Кнопка не поддерживается');
          return;
        }
        final answer = await messagesModule.sendButtonCallback(
          chatId: message.chatId,
          messageId: message.id,
          callbackId: callbackId,
          payload: button.payload,
        );
        if (!mounted) return;
        final url = answer?['url']?.toString();
        if (url != null && url.isNotEmpty) {
          await openExternalUrl(context, url);
          return;
        }
        final text = answer?['text']?.toString();
        if (text != null && text.isNotEmpty) {
          showCustomNotification(context, text);
        }
    }
  }

  Future<void> _openNativeMiniApp(
    CachedMessage message,
    InlineKeyboardButton button,
  ) async {
    if (!webViewSupported) {
      showCustomNotification(context, 'На вашей платформе это недоступно');
      return;
    }
    final deeplink = button.webApp != null ? Uri.tryParse(button.webApp!) : null;
    final startParam =
        button.payload ??
        deeplink?.queryParameters['startapp'] ??
        deeplink?.queryParameters['startApp'];
    final chatId =
        int.tryParse(deeplink?.queryParameters['chat_id'] ?? '') ?? message.chatId;
    final botId = button.contactId;
    if (botId == null) {
      showCustomNotification(context, 'Не удалось открыть приложение');
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      iosPageRoute(
        context,
        builder: (_) => WebAppScreen(
          title: button.text,
          entryPoint: WebAppEntryPoint.inlineButton,
          loader: () => webAppModule.fetchLaunch(
            botId,
            startParam: startParam,
            chatId: chatId,
          ),
        ),
      ),
    );
  }

  void _showNativeMessageActions(String id, Rect origin) {
    final message = _chatController.byId(id);
    if (message == null || !mounted || message.isControl) return;
    if (_selectionMode) {
      _toggleSelection(message);
      return;
    }
    final isMe = message.senderId == _myId;
    final canReport = !isMe;
    final reportTypeId = _complaintTypeId(chat?.type ?? widget.chatType);
    final controller = MessageActionsController();
    showMessageActions(
      context: context,
      originRect: origin,
      tapPoint: origin.center,
      isMe: isMe,
      bottomReservedSpace: _composerHeight.value,
      messageText: message.text,
      copyText: MessageDecryptionCache.instance.readableText(message),
      controller: controller,
      style: AppMessageActionsStyle.current.value,
      interaction: MessageActionsInteraction.tap,
      editHistory: message.editHistory,
      loadReadBy: _canShowReadBy(message) ? () => _loadReadBy(message) : null,
      onReaderTap: _openSenderProfile,
      loadReportReasons: canReport ? () => _loadReportReasons(reportTypeId) : null,
      onReport: canReport
          ? (reasonId) => _reportMessage(message, reportTypeId, reasonId)
          : null,
      onDelete: () => _confirmDeleteMessage(message.id, isMe),
      allowDelete: isMe ||
          chat?.type != 'CHANNEL' ||
          (chat?.iAmAdmin(_myId) ?? false),
      allowCopy: !(chat?.copyDisabled ?? false),
      onEdit: _canEditMessage(message) ? () => _startEditMessage(message) : null,
      onReply: _canReply ? () => _textSend.startReply(message) : null,
      onForward: (chat?.forwardDisabled ?? false)
          ? null
          : () => _forwardMessages([message]),
      onMarkUnread: () => _markMessageUnread(message),
      onPin: _canPinMessage(message) ? () => _togglePinMessage(message) : null,
      onCopyLink: _canLinkMessage(message) ? () => _copyMessageLink(message) : null,
      isPinned: chat?.pinnedMsgId == int.tryParse(message.id),
      onReact: (emoji) => _reactToMessage(message, emoji),
      selectedReaction: _reactionNotifierFor(message).value?['yourReaction']?.toString(),
      onDispose: controller.dispose,
    );
  }
}

class _ChatMessageList extends StatefulWidget {
  final _ChatScreenState host;
  const _ChatMessageList(this.host, {super.key});

  @override
  State<_ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<_ChatMessageList> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.host._messagesRev,
      builder: (context, _, _) => widget.host._buildMessagesListContent(),
    );
  }
}

