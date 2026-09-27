import 'package:flutter/foundation.dart';

@immutable
class ChatUiState {
  final Set<String> selection;
  final bool searching;
  final String query;
  final String? highlightId;
  final double composerHeight;
  final double pinnedHeight;
  final String? replyId;
  final int forwardCount;
  final String? panel;
  final bool encryption;
  final bool hasWallpaper;

  const ChatUiState({
    this.selection = const {},
    this.searching = false,
    this.query = '',
    this.highlightId,
    this.composerHeight = 0,
    this.pinnedHeight = 0,
    this.replyId,
    this.forwardCount = 0,
    this.panel,
    this.encryption = false,
    this.hasWallpaper = false,
  });

  ChatUiState copyWith({
    Set<String>? selection,
    bool? searching,
    String? query,
    String? highlightId,
    bool clearHighlight = false,
    double? composerHeight,
    double? pinnedHeight,
    String? replyId,
    bool clearReply = false,
    int? forwardCount,
    String? panel,
    bool clearPanel = false,
    bool? encryption,
    bool? hasWallpaper,
  }) {
    return ChatUiState(
      selection: selection ?? this.selection,
      searching: searching ?? this.searching,
      query: query ?? this.query,
      highlightId: clearHighlight ? null : (highlightId ?? this.highlightId),
      composerHeight: composerHeight ?? this.composerHeight,
      pinnedHeight: pinnedHeight ?? this.pinnedHeight,
      replyId: clearReply ? null : (replyId ?? this.replyId),
      forwardCount: forwardCount ?? this.forwardCount,
      panel: clearPanel ? null : (panel ?? this.panel),
      encryption: encryption ?? this.encryption,
      hasWallpaper: hasWallpaper ?? this.hasWallpaper,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChatUiState &&
      setEquals(other.selection, selection) &&
      other.searching == searching &&
      other.query == query &&
      other.highlightId == highlightId &&
      other.composerHeight == composerHeight &&
      other.pinnedHeight == pinnedHeight &&
      other.replyId == replyId &&
      other.forwardCount == forwardCount &&
      other.panel == panel &&
      other.encryption == encryption &&
      other.hasWallpaper == hasWallpaper;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(selection),
    searching,
    query,
    highlightId,
    composerHeight,
    pinnedHeight,
    replyId,
    forwardCount,
    panel,
    encryption,
    hasWallpaper,
  );
}

/// Notifies only when the selected slice changes.
class ChatUiSelector<T> extends ValueNotifier<T> {
  ChatUiSelector(this._select, ChatUiState state) : super(_select(state));

  final T Function(ChatUiState state) _select;

  void apply(ChatUiState state) {
    final next = _select(state);
    if (next == value) return;
    value = next;
  }
}
