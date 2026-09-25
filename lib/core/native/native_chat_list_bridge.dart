import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/app_ios_glass.dart';
import '../config/app_native_chat_list_prototype.dart';

enum NativeChatAction { markRead, pin, unpin, mute, unmute, archive, delete }

enum NativeChatStatus { sending, sent, read, error }

enum NativeChatBulkAction { readAll, read, archive, delete }

@immutable
class NativeSheetAction {
  final String id;
  final String title;
  final bool destructive;

  const NativeSheetAction({
    required this.id,
    required this.title,
    this.destructive = false,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'destructive': destructive,
  };
}

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
  final ValueChanged<Rect> onDownloads;
  final ValueChanged<Rect> onLock;
  final ValueChanged<bool> onEditing;
  final ValueChanged<List<int>> onSelection;
  final void Function(NativeChatBulkAction action, List<int> ids) onBulk;
  final ValueChanged<List<int>> onReorderPinned;

  const NativeChatListCallbacks({
    required this.onOpen,
    required this.onAction,
    required this.onCompose,
    required this.onDownloads,
    required this.onLock,
    required this.onEditing,
    required this.onSelection,
    required this.onBulk,
    required this.onReorderPinned,
  });
}

class NativeChatListCommands {
  NativeChatListController? _controller;

  bool get isAttached => _controller != null;

  void attach(NativeChatListController controller) => _controller = controller;

  void detach(NativeChatListController controller) {
    if (identical(_controller, controller)) _controller = null;
  }

  Future<void> setEditing(bool on) async => _controller?.setEditing(on);

  Future<String?> actionSheet({
    String? title,
    String? message,
    required List<NativeSheetAction> actions,
  }) async => _controller?.actionSheet(
    title: title,
    message: message,
    actions: actions,
  );
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

  Future<void> setEditing(bool on) => _invoke('setEditing', {'on': on});

  Future<String?> actionSheet({
    String? title,
    String? message,
    required List<NativeSheetAction> actions,
  }) async {
    if (_disposed) return null;
    try {
      return await channel.invokeMethod<String>('actionSheet', {
        'title': title,
        'message': message,
        'actions': [for (final action in actions) action.toMap()],
      });
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

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
      case 'downloads':
        callbacks.onDownloads(_rectOf(args));
      case 'lock':
        callbacks.onLock(_rectOf(args));
      case 'editing':
        callbacks.onEditing(args['on'] == true);
      case 'selection':
        callbacks.onSelection(_idsOf(args));
      case 'bulk':
        final action = NativeChatBulkAction.values.asNameMap()[args['action']];
        if (action != null) callbacks.onBulk(action, _idsOf(args));
      case 'reorderPinned':
        callbacks.onReorderPinned(_idsOf(args));
    }
    return null;
  }

  static List<int> _idsOf(Map<String, Object?> args) {
    final raw = args['ids'];
    if (raw is! List) return const [];
    return raw.whereType<int>().toList(growable: false);
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
