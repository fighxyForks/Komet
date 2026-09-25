import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/app_ios_glass.dart';
import '../config/app_native_chat_list_prototype.dart';

enum NativeChatAction { markRead, pin, unpin, mute, unmute, archive, delete }

enum NativeChatStatus { sending, sent, read, error }

@immutable
class NativeChatRow {
  final int id;
  final String title;
  final String avatarUrl;
  final bool saved;
  final String? kind;
  final bool encrypted;
  final bool verified;
  final bool muted;
  final bool pinned;
  final String time;
  final String author;
  final String text;
  final String? mediaKind;
  final bool italic;
  final String? draft;
  final NativeChatStatus? status;
  final int unread;
  final bool mention;
  final bool canMarkRead;
  final bool canDelete;

  const NativeChatRow({
    required this.id,
    required this.title,
    this.avatarUrl = '',
    this.saved = false,
    this.kind,
    this.encrypted = false,
    this.verified = false,
    this.muted = false,
    this.pinned = false,
    this.time = '',
    this.author = '',
    this.text = '',
    this.mediaKind,
    this.italic = false,
    this.draft,
    this.status,
    this.unread = 0,
    this.mention = false,
    this.canMarkRead = false,
    this.canDelete = false,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'avatarUrl': avatarUrl,
    'saved': saved,
    'kind': kind,
    'encrypted': encrypted,
    'verified': verified,
    'muted': muted,
    'pinned': pinned,
    'time': time,
    'author': author,
    'text': text,
    'mediaKind': mediaKind,
    'italic': italic,
    'draft': draft,
    'status': status?.name,
    'unread': unread,
    'mention': mention,
    'canMarkRead': canMarkRead,
    'canDelete': canDelete,
  };

  @override
  bool operator ==(Object other) =>
      other is NativeChatRow && mapEquals(toMap(), other.toMap());

  @override
  int get hashCode => Object.hashAll(toMap().values);
}

@immutable
class NativeChatListUpdate {
  final List<int>? order;
  final List<NativeChatRow> rows;

  const NativeChatListUpdate({this.order, this.rows = const []});

  bool get isEmpty => order == null && rows.isEmpty;

  Map<String, Object?> toMap() => {
    if (order != null) 'order': order,
    'rows': [for (final row in rows) row.toMap()],
  };

  static NativeChatListUpdate between(
    List<NativeChatRow> previous,
    List<NativeChatRow> next,
  ) {
    final before = {for (final row in previous) row.id: row};
    final order = [for (final row in next) row.id];
    final orderChanged = !listEquals(order, [
      for (final row in previous) row.id,
    ]);
    return NativeChatListUpdate(
      order: orderChanged ? order : null,
      rows: [
        for (final row in next)
          if (before[row.id] != row) row,
      ],
    );
  }
}

class NativeChatListCallbacks {
  final ValueChanged<int> onOpen;
  final void Function(int id, NativeChatAction action) onAction;
  final ValueChanged<Rect> onCompose;
  final ValueChanged<Rect> onMenu;

  const NativeChatListCallbacks({
    required this.onOpen,
    required this.onAction,
    required this.onCompose,
    required this.onMenu,
  });
}

class NativeChatListController {
  NativeChatListController(int viewId, this.callbacks)
    : channel = MethodChannel('${NativeChatListBridge.viewType}/$viewId') {
    channel.setMethodCallHandler(_onCall);
  }

  final MethodChannel channel;
  NativeChatListCallbacks callbacks;
  List<NativeChatRow> _sent = const [];
  bool _disposed = false;

  void seed(List<NativeChatRow> rows) => _sent = rows;

  Future<void> update(List<NativeChatRow> rows) async {
    final update = NativeChatListUpdate.between(_sent, rows);
    _sent = rows;
    if (update.isEmpty) return;
    await _invoke('apply', update.toMap());
  }

  Future<void> setChrome(Map<String, Object?> chrome) =>
      _invoke('setChrome', chrome);

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
    switch (call.method) {
      case 'open':
        final id = args['id'];
        if (id is int) callbacks.onOpen(id);
      case 'action':
        final id = args['id'];
        final action = NativeChatAction.values.asNameMap()[args['action']];
        if (id is int && action != null) callbacks.onAction(id, action);
      case 'compose':
        callbacks.onCompose(_rectOf(args));
      case 'menu':
        callbacks.onMenu(_rectOf(args));
    }
    return null;
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

class NativeChatListBridge {
  NativeChatListBridge._();

  static const viewType = 'ru.komet.app/native_chat_list';

  static bool? debugAvailable;

  static bool get isEligible {
    if (debugAvailable == false) return false;
    if (debugAvailable != true) {
      if (kIsWeb) return false;
      if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    }
    return AppNativeChatListPrototype.enabled.value && AppIosGlass.active.value;
  }

  @visibleForTesting
  static void debugReset() {
    debugAvailable = null;
  }

  static Listenable get eligibility => Listenable.merge([
    AppNativeChatListPrototype.enabled,
    AppIosGlass.active,
  ]);
}
