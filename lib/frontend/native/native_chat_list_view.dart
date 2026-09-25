import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/native/native_chat_list_bridge.dart';

class NativeChatListView extends StatefulWidget {
  final List<NativeChatRow> rows;
  final Map<String, Object?> chrome;
  final NativeChatListCallbacks callbacks;
  final NativeChatListCommands? commands;
  final NativeStories stories;
  final NativeArchiveEntry? archive;
  final NativeFolders folders;

  const NativeChatListView({
    super.key,
    required this.rows,
    required this.chrome,
    required this.callbacks,
    this.commands,
    this.stories = const NativeStories(),
    this.archive,
    this.folders = const NativeFolders(),
  });

  @override
  State<NativeChatListView> createState() => _NativeChatListViewState();
}

class _NativeChatListViewState extends State<NativeChatListView> {
  NativeChatListController? _controller;
  late final List<NativeChatRow> _createdRows = widget.rows;
  late final Map<String, Object?> _createdChrome = widget.chrome;
  late final NativeStories _createdStories = widget.stories;
  late final NativeArchiveEntry? _createdArchive = widget.archive;
  late final NativeFolders _createdFolders = widget.folders;

  void _onCreated(int viewId) {
    final controller = NativeChatListController(viewId, widget.callbacks)
      ..seed(_createdRows);
    _controller = controller;
    widget.commands?.attach(controller);
    controller.update(widget.rows);
    if (!mapEquals(_createdChrome, widget.chrome)) {
      controller.setChrome(widget.chrome);
    }
    if (_createdStories != widget.stories) {
      controller.setStories(widget.stories);
    }
    if (_createdArchive != widget.archive) {
      controller.setArchive(widget.archive);
    }
    if (_createdFolders != widget.folders) {
      controller.setFolders(widget.folders);
    }
  }

  @override
  void didUpdateWidget(NativeChatListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller == null) return;
    controller.callbacks = widget.callbacks;
    if (!identical(oldWidget.commands, widget.commands)) {
      oldWidget.commands?.detach(controller);
      widget.commands?.attach(controller);
    }
    controller.update(widget.rows);
    if (!mapEquals(oldWidget.chrome, widget.chrome)) {
      controller.setChrome(widget.chrome);
    }
    if (oldWidget.stories != widget.stories) {
      controller.setStories(widget.stories);
    }
    if (oldWidget.archive != widget.archive) {
      controller.setArchive(widget.archive);
    }
    if (oldWidget.folders != widget.folders) {
      controller.setFolders(widget.folders);
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
      viewType: NativeChatListBridge.viewType,
      creationParams: <String, Object?>{
        'rows': [for (final row in _createdRows) row.toMap()],
        'chrome': _createdChrome,
        'stories': _createdStories.toMap(),
        'archive': _createdArchive?.toMap(),
        'folders': _createdFolders.toMap(),
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onCreated,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
    );
  }
}
