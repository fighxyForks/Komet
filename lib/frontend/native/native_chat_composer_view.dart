import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class NativeChatComposerView extends StatefulWidget {
  final TextEditingController text;
  final String reply;
  final String status;
  final bool recording;
  final bool videoMode;
  final bool locked;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onStickers;
  final VoidCallback onToggleVideo;
  final VoidCallback onRecordStart;
  final void Function(bool video, Offset offset) onRecordDrag;
  final void Function(bool video) onRecordEnd;
  final VoidCallback onSchedule;
  final VoidCallback onFormat;
  final VoidCallback onReplyCancel;

  const NativeChatComposerView({
    super.key,
    required this.text,
    required this.reply,
    required this.status,
    required this.recording,
    required this.videoMode,
    required this.locked,
    required this.onSend,
    required this.onAttach,
    required this.onStickers,
    required this.onToggleVideo,
    required this.onRecordStart,
    required this.onRecordDrag,
    required this.onRecordEnd,
    required this.onSchedule,
    required this.onFormat,
    required this.onReplyCancel,
  });

  @override
  State<NativeChatComposerView> createState() => _NativeChatComposerViewState();
}

class _NativeChatComposerViewState extends State<NativeChatComposerView> {
  static const _type = 'ru.komet.app/native_chat_composer';
  MethodChannel? _channel;
  String _last = '';
  bool _videoGesture = false;

  Map<String, Object?> get _chrome => {
    'text': widget.text.text,
    'reply': widget.reply,
    'status': widget.status,
    'recording': widget.recording,
    'video': widget.videoMode,
    'locked': widget.locked,
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
        case 'selection':
          final start = _int(args['start']);
          final end = _int(args['end']);
          final length = widget.text.text.length;
          if (start >= 0 && end >= start && end <= length) {
            widget.text.selection = TextSelection(
              baseOffset: start,
              extentOffset: end,
            );
          }
        case 'send':
          widget.onSend();
        case 'attach':
          widget.onAttach();
        case 'stickers':
          widget.onStickers();
        case 'toggleVideo':
          widget.onToggleVideo();
        case 'recordStart':
          _videoGesture = widget.videoMode;
          widget.onRecordStart();
        case 'recordDrag':
          widget.onRecordDrag(
            _videoGesture,
            Offset(_double(args['x']), _double(args['y'])),
          );
        case 'recordEnd':
          widget.onRecordEnd(_videoGesture);
        case 'schedule':
          widget.onSchedule();
        case 'format':
          widget.onFormat();
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
    'status': view.status,
    'recording': view.recording,
    'video': view.videoMode,
    'locked': view.locked,
  };

  int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  double _double(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return 0;
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
