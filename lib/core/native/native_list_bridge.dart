import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/app_ios_glass.dart';

enum NativeListRowStyle { item, action }

@immutable
class NativeListAction {
  final String id;
  final String title;
  final String symbol;
  final bool destructive;

  const NativeListAction({
    required this.id,
    required this.title,
    required this.symbol,
    this.destructive = false,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'symbol': symbol,
    'destructive': destructive,
  };
}

@immutable
class NativeListRow {
  final String id;
  final NativeListRowStyle style;
  final String title;
  final bool alert;
  final bool verified;
  final String subtitle;
  final String? subtitleSymbol;
  final String trailing;
  final String avatarUrl;
  final int avatarSeed;
  final String? avatarSymbol;
  final String? symbol;
  final List<NativeListAction> menu;
  final bool menuOnTap;

  const NativeListRow({
    required this.id,
    required this.title,
    this.style = NativeListRowStyle.item,
    this.alert = false,
    this.verified = false,
    this.subtitle = '',
    this.subtitleSymbol,
    this.trailing = '',
    this.avatarUrl = '',
    this.avatarSeed = 0,
    this.avatarSymbol,
    this.symbol,
    this.menu = const [],
    this.menuOnTap = false,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'style': style.name,
    'title': title,
    'alert': alert,
    'verified': verified,
    'subtitle': subtitle,
    'subtitleSymbol': subtitleSymbol,
    'trailing': trailing,
    'avatarUrl': avatarUrl,
    'avatarSeed': avatarSeed,
    'avatarSymbol': avatarSymbol,
    'symbol': symbol,
    'menu': [for (final action in menu) action.toMap()],
    'menuOnTap': menuOnTap,
  };

  String get _key => jsonEncode(toMap());

  @override
  bool operator ==(Object other) =>
      other is NativeListRow && other._key == _key;

  @override
  int get hashCode => _key.hashCode;
}

@immutable
class NativeListSection {
  final String id;
  final String title;
  final List<NativeListRow> rows;

  const NativeListSection({
    required this.id,
    this.title = '',
    required this.rows,
  });

  Map<String, Object?> layout() => {
    'id': id,
    'title': title,
    'rows': [for (final row in rows) row.id],
  };
}

@immutable
class NativeListUpdate {
  final List<Map<String, Object?>>? sections;
  final List<NativeListRow> rows;

  const NativeListUpdate({this.sections, this.rows = const []});

  bool get isEmpty => sections == null && rows.isEmpty;

  Map<String, Object?> toMap() => {
    if (sections != null) 'sections': sections,
    'rows': [for (final row in rows) row.toMap()],
  };

  static NativeListUpdate between(
    List<NativeListSection> previous,
    List<NativeListSection> next,
  ) {
    final before = {
      for (final section in previous)
        for (final row in section.rows) row.id: row,
    };
    final layout = [for (final section in next) section.layout()];
    final layoutChanged =
        jsonEncode(layout) !=
        jsonEncode([for (final section in previous) section.layout()]);
    return NativeListUpdate(
      sections: layoutChanged ? layout : null,
      rows: [
        for (final section in next)
          for (final row in section.rows)
            if (before[row.id] != row) row,
      ],
    );
  }
}

class NativeListCallbacks {
  final ValueChanged<String> onTap;
  final void Function(String rowId, String actionId) onMenu;
  final void Function(String buttonId, Rect anchor) onButton;
  final ValueChanged<int> onSegment;

  const NativeListCallbacks({
    required this.onTap,
    this.onMenu = _ignoreMenu,
    this.onButton = _ignoreButton,
    this.onSegment = _ignoreSegment,
  });

  static void _ignoreMenu(String rowId, String actionId) {}
  static void _ignoreButton(String buttonId, Rect anchor) {}
  static void _ignoreSegment(int index) {}
}

class NativeListController {
  NativeListController(int viewId, this.callbacks)
    : channel = MethodChannel('${NativeListBridge.viewType}/$viewId') {
    channel.setMethodCallHandler(_onCall);
  }

  final MethodChannel channel;
  NativeListCallbacks callbacks;
  List<NativeListSection> _sent = const [];
  bool _disposed = false;

  void seed(List<NativeListSection> sections) => _sent = sections;

  Future<void> update(List<NativeListSection> sections) async {
    final update = NativeListUpdate.between(_sent, sections);
    _sent = sections;
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
      case 'tap':
        final id = args['id'];
        if (id is String) callbacks.onTap(id);
      case 'menu':
        final id = args['id'];
        final action = args['action'];
        if (id is String && action is String) callbacks.onMenu(id, action);
      case 'button':
        final id = args['id'];
        if (id is String) callbacks.onButton(id, _rectOf(args));
      case 'segment':
        final index = args['index'];
        if (index is int) callbacks.onSegment(index);
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

class NativeListBridge {
  NativeListBridge._();

  static const viewType = 'ru.komet.app/native_list';

  static bool? debugAvailable;

  static bool get isEligible {
    if (debugAvailable == false) return false;
    if (debugAvailable != true) {
      if (kIsWeb) return false;
      if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    }
    return AppIosGlass.active.value;
  }

  static Listenable get eligibility => AppIosGlass.active;

  @visibleForTesting
  static void debugReset() {
    debugAvailable = null;
  }
}
