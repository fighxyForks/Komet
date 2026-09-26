import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class NativeSettingsSection {
  final String header;
  final List<NativeSettingsRow> rows;

  const NativeSettingsSection({this.header = '', required this.rows});
}

class NativeSettingsRow {
  final String id;
  final String title;
  final String symbol;
  final bool destructive;
  final bool enabled;
  final bool? switchValue;
  final String trailing;
  final List<String> keywords;

  const NativeSettingsRow({
    required this.id,
    required this.title,
    required this.symbol,
    this.destructive = false,
    this.enabled = true,
    this.switchValue,
    this.trailing = '',
    this.keywords = const [],
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'symbol': symbol,
    'destructive': destructive,
    'enabled': enabled,
    if (switchValue != null) 'switchValue': switchValue,
    if (trailing.isNotEmpty) 'trailing': trailing,
    if (keywords.isNotEmpty) 'keywords': keywords,
  };
}

class NativeSettingsView extends StatefulWidget {
  final String name;
  final String status;
  final bool online;
  final String phone;
  final String detail;
  final String bio;
  final String layout;
  final String avatarUrl;
  final bool canEditAvatar;
  final String version;
  final double topInset;
  final bool showBack;
  final bool showQr;
  final bool showEdit;
  final bool showMenu;
  final List<NativeSettingsSection> sections;
  final void Function(String id) onTap;
  final void Function(String id, bool value)? onToggle;
  final void Function(String action, Rect rect) onHeader;

  const NativeSettingsView({
    super.key,
    required this.name,
    required this.status,
    required this.online,
    required this.phone,
    this.detail = '',
    required this.bio,
    required this.avatarUrl,
    required this.canEditAvatar,
    required this.version,
    required this.topInset,
    this.showBack = false,
    this.showQr = true,
    this.showEdit = true,
    this.showMenu = true,
    this.layout = 'profile',
    required this.sections,
    required this.onTap,
    this.onToggle,
    required this.onHeader,
  });

  @override
  State<NativeSettingsView> createState() => _NativeSettingsViewState();
}

class _NativeSettingsViewState extends State<NativeSettingsView> {
  static const _type = 'ru.komet.app/native_settings';
  MethodChannel? _channel;

  Map<String, Object?> get _payload => {
    'header': {
      'name': widget.name,
      'status': widget.status,
      'online': widget.online,
      'phone': widget.phone,
      'detail': widget.detail,
      'bio': widget.bio,
      'avatarUrl': widget.avatarUrl,
      'canEditAvatar': widget.canEditAvatar,
      'topInset': widget.topInset,
      'showBack': widget.showBack,
      'showQr': widget.showQr,
      'showEdit': widget.showEdit,
      'showMenu': widget.showMenu,
    },
    'version': widget.version,
    'layout': widget.layout,
    'sections': [
      for (final section in widget.sections)
        {
          'header': section.header,
          'rows': [for (final row in section.rows) row.toMap()],
        },
    ],
  };

  void _created(int viewId) {
    final channel = MethodChannel('$_type/$viewId');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      final args = call.arguments is Map
          ? Map<String, Object?>.from(call.arguments as Map)
          : const <String, Object?>{};
      switch (call.method) {
        case 'tap':
          final id = args['id'];
          if (id is String) widget.onTap(id);
        case 'toggle':
          final id = args['id'];
          final value = args['value'];
          if (id is String && value is bool) widget.onToggle?.call(id, value);
        case 'header':
          final action = args['action'];
          if (action is String) widget.onHeader(action, _rect(args));
      }
      return null;
    });
    _push();
  }

  Rect _rect(Map<String, Object?> args) {
    double read(String key) => (args[key] as num?)?.toDouble() ?? 0;
    return Rect.fromLTWH(read('x'), read('y'), read('width'), read('height'));
  }

  Future<void> _push() async {
    try {
      await _channel?.invokeMethod<void>('apply', _payload);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  @override
  void didUpdateWidget(NativeSettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(_payloadOf(oldWidget), _payload)) _push();
  }

  Map<String, Object?> _payloadOf(NativeSettingsView view) => {
    'header': {
      'name': view.name,
      'status': view.status,
      'online': view.online,
      'phone': view.phone,
      'detail': view.detail,
      'bio': view.bio,
      'avatarUrl': view.avatarUrl,
      'canEditAvatar': view.canEditAvatar,
      'topInset': view.topInset,
      'showBack': view.showBack,
      'showQr': view.showQr,
      'showEdit': view.showEdit,
      'showMenu': view.showMenu,
    },
    'version': view.version,
    'layout': view.layout,
    'sections': [
      for (final section in view.sections)
        {
          'header': section.header,
          'rows': [for (final row in section.rows) row.toMap()],
        },
    ],
  };

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: _type,
      creationParams: _payload,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _created,
    );
  }
}
