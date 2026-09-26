import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/utils/format.dart';
import '../screens/chats/chat/chat_search_controller.dart';
import '../screens/chats/chat/message_search_result.dart';

class NativeChatSearchBar extends StatefulWidget {
  final TextEditingController text;
  final VoidCallback onClose;
  final void Function(String query) onSubmit;

  const NativeChatSearchBar({
    super.key,
    required this.text,
    required this.onClose,
    required this.onSubmit,
  });

  @override
  State<NativeChatSearchBar> createState() => _NativeChatSearchBarState();
}

class _NativeChatSearchBarState extends State<NativeChatSearchBar> {
  static const _type = 'ru.komet.app/native_chat_search_bar';
  MethodChannel? _channel;
  String _last = '';

  Map<String, Object?> get _chrome => {'text': widget.text.text};

  @override
  void initState() {
    super.initState();
    widget.text.addListener(_onText);
  }

  void _onText() {
    if (widget.text.text == _last) return;
    _push();
  }

  void _created(int viewId) {
    final channel = MethodChannel('$_type/$viewId');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      final args = call.arguments is Map
          ? Map<String, Object?>.from(call.arguments as Map)
          : const <String, Object?>{};
      switch (call.method) {
        case 'text':
          final text = args['text'] as String? ?? '';
          if (text != widget.text.text) {
            _last = text;
            widget.text.value = TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: text.length),
            );
          }
        case 'submit':
          widget.onSubmit(args['text'] as String? ?? widget.text.text);
        case 'close':
          widget.onClose();
      }
      return null;
    });
    _push();
  }

  Future<void> _push() async {
    _last = widget.text.text;
    try {
      await _channel?.invokeMethod<void>('apply', _chrome);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  @override
  void didUpdateWidget(NativeChatSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.text, widget.text)) {
      oldWidget.text.removeListener(_onText);
      widget.text.addListener(_onText);
    }
    if (oldWidget.text.text != widget.text.text) _push();
  }

  @override
  void dispose() {
    widget.text.removeListener(_onText);
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

class NativeChatSearchResults extends StatefulWidget {
  final ChatSearchController search;
  final String Function(int senderId) senderName;
  final String? Function(int senderId) senderAvatar;
  final void Function(MessageSearchResult result) onOpen;

  const NativeChatSearchResults({
    super.key,
    required this.search,
    required this.senderName,
    required this.senderAvatar,
    required this.onOpen,
  });

  @override
  State<NativeChatSearchResults> createState() => _NativeChatSearchResultsState();
}

class _NativeChatSearchResultsState extends State<NativeChatSearchResults> {
  static const _type = 'ru.komet.app/native_chat_search_results';
  MethodChannel? _channel;

  Map<String, Object?> get _payload => {
    'loading': widget.search.loading.value,
    'performed': widget.search.performed.value,
    'items': [
      for (final result in widget.search.results.value)
        {
          'id': result.id,
          'name': widget.senderName(result.senderId),
          'avatar': widget.senderAvatar(result.senderId) ?? '',
          'date': formatDateWords(
            DateTime.fromMillisecondsSinceEpoch(result.time),
          ),
          'text': result.text,
          'highlights': result.highlights,
        },
    ],
  };

  @override
  void initState() {
    super.initState();
    widget.search.results.addListener(_push);
    widget.search.loading.addListener(_push);
    widget.search.performed.addListener(_push);
  }

  void _created(int viewId) {
    final channel = MethodChannel('$_type/$viewId');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'open') {
        final args = call.arguments is Map
            ? Map<String, Object?>.from(call.arguments as Map)
            : const <String, Object?>{};
        final id = args['id'] as String?;
        MessageSearchResult? hit;
        for (final result in widget.search.results.value) {
          if (result.id == id) hit = result;
        }
        if (hit != null) widget.onOpen(hit);
      }
      return null;
    });
    _push();
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
    widget.search.results.removeListener(_push);
    widget.search.loading.removeListener(_push);
    widget.search.performed.removeListener(_push);
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

class NativePinnedBanner extends StatefulWidget {
  final String title;
  final String text;
  final bool canUnpin;
  final VoidCallback onTap;
  final VoidCallback? onUnpin;

  const NativePinnedBanner({
    super.key,
    required this.title,
    required this.text,
    required this.canUnpin,
    required this.onTap,
    this.onUnpin,
  });

  @override
  State<NativePinnedBanner> createState() => _NativePinnedBannerState();
}

class _NativePinnedBannerState extends State<NativePinnedBanner> {
  static const _type = 'ru.komet.app/native_chat_pinned';
  MethodChannel? _channel;

  Map<String, Object?> get _chrome => {
    'title': widget.title,
    'text': widget.text,
    'canUnpin': widget.canUnpin,
  };

  void _created(int viewId) {
    final channel = MethodChannel('$_type/$viewId');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'open':
          widget.onTap();
        case 'unpin':
          widget.onUnpin?.call();
      }
      return null;
    });
    _push();
  }

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
  void didUpdateWidget(NativePinnedBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(_chromeOf(oldWidget), _chrome)) _push();
  }

  Map<String, Object?> _chromeOf(NativePinnedBanner view) => {
    'title': view.title,
    'text': view.text,
    'canUnpin': view.canUnpin,
  };

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: UiKitView(
        viewType: _type,
        creationParams: _chrome,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _created,
      ),
    );
  }
}
