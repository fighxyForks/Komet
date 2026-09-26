import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class NativeChatHeaderView extends StatefulWidget {
  final String title;
  final String subtitle;
  final String avatarUrl;
  final bool embedded;
  final bool showCall;
  final bool showScheduled;
  final VoidCallback onClose;
  final VoidCallback onInfo;
  final VoidCallback onScheduled;
  final VoidCallback onCall;
  final ValueChanged<Rect> onMenu;

  const NativeChatHeaderView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.avatarUrl,
    required this.embedded,
    required this.showCall,
    required this.showScheduled,
    required this.onClose,
    required this.onInfo,
    required this.onScheduled,
    required this.onCall,
    required this.onMenu,
  });

  @override
  State<NativeChatHeaderView> createState() => _NativeChatHeaderViewState();
}

class _NativeChatHeaderViewState extends State<NativeChatHeaderView> {
  static const _type = 'ru.komet.app/native_chat_header';
  MethodChannel? _channel;

  Map<String, Object?> get _chrome => {
    'title': widget.title,
    'subtitle': widget.subtitle,
    'avatarUrl': widget.avatarUrl,
    'embedded': widget.embedded,
    'showCall': widget.showCall,
    'showScheduled': widget.showScheduled,
  };

  void _created(int viewId) {
    final channel = MethodChannel('$_type/$viewId');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      final args = call.arguments is Map
          ? Map<String, Object?>.from(call.arguments as Map)
          : const <String, Object?>{};
      switch (call.method) {
        case 'close':
          widget.onClose();
        case 'info':
          widget.onInfo();
        case 'scheduled':
          widget.onScheduled();
        case 'call':
          widget.onCall();
        case 'menu':
          widget.onMenu(_rect(args));
      }
      return null;
    });
    _push();
  }

  Rect _rect(Map<String, Object?> args) {
    double read(String key) => (args[key] as num?)?.toDouble() ?? 0;
    return Rect.fromLTWH(read('x'), read('y'), read('width'), read('height'));
  }

  @override
  void didUpdateWidget(NativeChatHeaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(_chromeOf(oldWidget), _chrome)) _push();
  }

  Map<String, Object?> _chromeOf(NativeChatHeaderView view) => {
    'title': view.title,
    'subtitle': view.subtitle,
    'avatarUrl': view.avatarUrl,
    'embedded': view.embedded,
    'showCall': view.showCall,
    'showScheduled': view.showScheduled,
  };

  Future<void> _push() async {
    try {
      await _channel?.invokeMethod<void>('apply', _chrome);
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
      creationParams: _chrome,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _created,
    );
  }
}
