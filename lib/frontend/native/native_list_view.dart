import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/native/native_list_bridge.dart';

class NativeListView extends StatefulWidget {
  final List<NativeListSection> sections;
  final Map<String, Object?> chrome;
  final NativeListCallbacks callbacks;

  const NativeListView({
    super.key,
    required this.sections,
    required this.chrome,
    required this.callbacks,
  });

  @override
  State<NativeListView> createState() => _NativeListViewState();
}

class _NativeListViewState extends State<NativeListView> {
  NativeListController? _controller;
  late final List<NativeListSection> _createdSections = widget.sections;
  late final Map<String, Object?> _createdChrome = widget.chrome;

  void _onCreated(int viewId) {
    final controller = NativeListController(viewId, widget.callbacks)
      ..seed(_createdSections);
    _controller = controller;
    controller.update(widget.sections);
    if (jsonEncode(_createdChrome) != jsonEncode(widget.chrome)) {
      controller.setChrome(widget.chrome);
    }
  }

  @override
  void didUpdateWidget(NativeListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller == null) return;
    controller.callbacks = widget.callbacks;
    controller.update(widget.sections);
    if (jsonEncode(oldWidget.chrome) != jsonEncode(widget.chrome)) {
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
      viewType: NativeListBridge.viewType,
      creationParams: <String, Object?>{
        'sections': [for (final section in _createdSections) section.layout()],
        'rows': [
          for (final section in _createdSections)
            for (final row in section.rows) row.toMap(),
        ],
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
