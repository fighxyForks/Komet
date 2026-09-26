import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class NativeProfileAction {
  final String id;
  final String title;
  final String symbol;
  final bool destructive;

  const NativeProfileAction({
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

  @override
  bool operator ==(Object other) =>
      other is NativeProfileAction &&
      other.id == id &&
      other.title == title &&
      other.symbol == symbol &&
      other.destructive == destructive;

  @override
  int get hashCode => Object.hash(id, title, symbol, destructive);
}

class NativeProfileActions extends StatefulWidget {
  final List<NativeProfileAction> rows;
  final ValueChanged<String> onTap;

  const NativeProfileActions({
    super.key,
    required this.rows,
    required this.onTap,
  });

  @override
  State<NativeProfileActions> createState() => _NativeProfileActionsState();
}

class _NativeProfileActionsState extends State<NativeProfileActions> {
  static const _type = 'ru.komet.app/native_profile_actions';
  MethodChannel? _channel;

  Map<String, Object?> get _payload => {
    'rows': [for (final row in widget.rows) row.toMap()],
  };

  void _created(int viewId) {
    final channel = MethodChannel('$_type/$viewId');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'tap') {
        final args = call.arguments is Map
            ? Map<String, Object?>.from(call.arguments as Map)
            : const <String, Object?>{};
        final id = args['id'];
        if (id is String) widget.onTap(id);
      }
      return null;
    });
    _push();
  }

  @override
  void didUpdateWidget(NativeProfileActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.rows, widget.rows)) _push();
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
