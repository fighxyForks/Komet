import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/native/native_chat_bridge.dart';

class NativeChatView extends StatefulWidget {
  final List<NativeChatItem> items;
  final Map<String, Object?> chrome;
  final NativeChatCallbacks callbacks;
  final NativeChatCommands? commands;
  final String? highlightId;

  const NativeChatView({
    super.key,
    required this.items,
    required this.chrome,
    required this.callbacks,
    this.commands,
    this.highlightId,
  });

  @override
  State<NativeChatView> createState() => _NativeChatViewState();
}

class _NativeChatViewState extends State<NativeChatView> {
  NativeChatController? _controller;
  late final List<NativeChatItem> _createdItems = widget.items;
  late final Map<String, Object?> _createdChrome = widget.chrome;
  String? _highlightId;

  void _onCreated(int viewId) {
    final controller = NativeChatController(viewId, widget.callbacks)
      ..seed(_createdItems);
    _controller = controller;
    widget.commands?.attach(controller);
    controller.update(widget.items);
    if (!mapEquals(_createdChrome, widget.chrome)) {
      controller.setChrome(widget.chrome);
    }
    _highlightId = widget.highlightId;
    if (_highlightId != null) controller.highlight(_highlightId);
  }

  @override
  void didUpdateWidget(NativeChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller == null) return;
    controller.callbacks = widget.callbacks;
    if (!identical(oldWidget.commands, widget.commands)) {
      oldWidget.commands?.detach(controller);
      widget.commands?.attach(controller);
    }
    controller.update(widget.items);
    if (!mapEquals(oldWidget.chrome, widget.chrome)) {
      controller.setChrome(widget.chrome);
    }
    if (oldWidget.highlightId != widget.highlightId) {
      _highlightId = widget.highlightId;
      controller.highlight(widget.highlightId);
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      widget.commands?.detach(controller);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: NativeChatBridge.viewType,
      creationParams: <String, Object?>{
        'order': [for (final item in _createdItems) item.id],
        'items': [for (final item in _createdItems) item.toMap()],
        'chrome': _createdChrome,
        'highlight': widget.highlightId,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onCreated,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
    );
  }
}
