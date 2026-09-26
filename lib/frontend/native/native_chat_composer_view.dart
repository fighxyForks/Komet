import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class NativeChatComposerView extends StatefulWidget {
  final TextEditingController text;
  final String reply;
  final bool recording;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onStickers;
  final VoidCallback onVoiceStart;
  final VoidCallback onVoiceStop;
  final VoidCallback onVoiceCancel;
  final VoidCallback onReplyCancel;

  const NativeChatComposerView({
    super.key,
    required this.text,
    required this.reply,
    required this.recording,
    required this.onSend,
    required this.onAttach,
    required this.onStickers,
    required this.onVoiceStart,
    required this.onVoiceStop,
    required this.onVoiceCancel,
    required this.onReplyCancel,
  });

  @override
  State<NativeChatComposerView> createState() => _NativeChatComposerViewState();
}

class _NativeChatComposerViewState extends State<NativeChatComposerView> {
  static const _type = 'ru.komet.app/native_chat_composer';
  MethodChannel? _channel;
  String _last = '';

  Map<String, Object?> get _chrome => {
    'text': widget.text.text,
    'reply': widget.reply,
    'recording': widget.recording,
  };

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
        case 'send':
          widget.onSend();
        case 'attach':
          widget.onAttach();
        case 'stickers':
          widget.onStickers();
        case 'voiceStart':
          widget.onVoiceStart();
        case 'voiceStop':
          widget.onVoiceStop();
        case 'voiceCancel':
          widget.onVoiceCancel();
        case 'replyCancel':
          widget.onReplyCancel();
      }
      return null;
    });
    _push();
  }

  @override
  void didUpdateWidget(NativeChatComposerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.text, widget.text)) {
      oldWidget.text.removeListener(_onText);
      widget.text.addListener(_onText);
    }
    if (!mapEquals(_chromeOf(oldWidget), _chrome)) _push();
  }

  Map<String, Object?> _chromeOf(NativeChatComposerView view) => {
    'text': view.text.text,
    'reply': view.reply,
    'recording': view.recording,
  };

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
  void dispose() {
    widget.text.removeListener(_onText);
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.reply.isEmpty ? 56 : 84,
      child: UiKitView(
        viewType: _type,
        creationParams: _chrome,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _created,
      ),
    );
  }
}
