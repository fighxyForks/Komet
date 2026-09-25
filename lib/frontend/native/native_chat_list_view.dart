import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/native/native_chat_list_bridge.dart';

class NativeChatListView extends StatefulWidget {
  final List<NativeChatRow> rows;
  final Map<String, Object?> chrome;
  final NativeChatListCallbacks callbacks;

  const NativeChatListView({
    super.key,
    required this.rows,
    required this.chrome,
    required this.callbacks,
  });

  @override
  State<NativeChatListView> createState() => _NativeChatListViewState();
}

class _NativeChatListViewState extends State<NativeChatListView> {
  NativeChatListController? _controller;
  late final List<NativeChatRow> _createdRows = widget.rows;
  late final Map<String, Object?> _createdChrome = widget.chrome;

  void _onCreated(int viewId) {
    final controller = NativeChatListController(viewId, widget.callbacks)
      ..seed(_createdRows);
    _controller = controller;
    controller.update(widget.rows);
    if (!mapEquals(_createdChrome, widget.chrome)) {
      controller.setChrome(widget.chrome);
    }
  }

  @override
  void didUpdateWidget(NativeChatListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller == null) return;
    controller.callbacks = widget.callbacks;
    controller.update(widget.rows);
    if (!mapEquals(oldWidget.chrome, widget.chrome)) {
      controller.setChrome(widget.chrome);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: NativeChatListBridge.viewType,
      creationParams: <String, Object?>{
        'rows': [for (final row in _createdRows) row.toMap()],
        'chrome': _createdChrome,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onCreated,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
    );
  }
}
