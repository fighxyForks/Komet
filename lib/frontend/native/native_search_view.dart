import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/native/native_search_session.dart';

class NativeSearchView extends StatefulWidget {
  final List<NativeSearchHit> hits;
  final bool loading;
  final ValueChanged<String> onQuery;
  final VoidCallback onClose;
  final ValueChanged<String> onOpen;
  final VoidCallback onMore;

  const NativeSearchView({
    super.key,
    required this.hits,
    this.loading = false,
    required this.onQuery,
    required this.onClose,
    required this.onOpen,
    required this.onMore,
  });

  @override
  State<NativeSearchView> createState() => _NativeSearchViewState();
}

class _NativeSearchViewState extends State<NativeSearchView> {
  static const _type = 'ru.komet.app/native_search';
  MethodChannel? _channel;

  void _created(int viewId) {
    final channel = MethodChannel('$_type/$viewId');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      final args = call.arguments is Map
          ? Map<String, Object?>.from(call.arguments as Map)
          : const <String, Object?>{};
      switch (call.method) {
        case 'query':
          widget.onQuery(args['text'] as String? ?? '');
        case 'close':
          widget.onClose();
        case 'open':
          final id = args['id'];
          if (id is String) widget.onOpen(id);
        case 'more':
          widget.onMore();
      }
      return null;
    });
    _push(widget.hits);
  }

  @override
  void didUpdateWidget(NativeSearchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loading != widget.loading ||
        !listEquals(oldWidget.hits, widget.hits)) {
      _push(widget.hits);
    }
  }

  Future<void> _push(List<NativeSearchHit> hits) async {
    try {
      await _channel?.invokeMethod<void>('apply', {
        'hits': [for (final hit in hits) hit.toMap()],
        'loading': widget.loading,
      });
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
      onPlatformViewCreated: _created,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
