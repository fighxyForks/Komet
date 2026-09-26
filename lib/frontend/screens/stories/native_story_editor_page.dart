import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/haptics.dart';
import '../../../main.dart' show fileUploader, messagesModule, storiesModule;
import '../../widgets/custom_notification.dart';

const int _storyExpiration = 86400000;

class NativeStoryEditorPage extends StatefulWidget {
  final File file;
  final bool isVideo;
  final int? durationMs;

  const NativeStoryEditorPage({
    super.key,
    required this.file,
    required this.isVideo,
    this.durationMs,
  });

  @override
  State<NativeStoryEditorPage> createState() => _NativeStoryEditorPageState();
}

class _NativeStoryEditorPageState extends State<NativeStoryEditorPage> {
  static const _type = 'ru.komet.app/native_story_editor';
  MethodChannel? _channel;
  int _audience = 1;
  bool _publishing = false;
  int? _durationMs;

  Map<String, Object?> get _chrome => {
    'path': widget.file.path,
    'video': widget.isVideo,
    'audience': _audience,
    'publishing': _publishing,
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
  void initState() {
    super.initState();
    _durationMs = widget.durationMs;
  }

  void _created(int viewId) {
    final channel = MethodChannel('$_type/$viewId');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      final args = call.arguments is Map
          ? Map<String, Object?>.from(call.arguments as Map)
          : const <String, Object?>{};
      switch (call.method) {
        case 'close':
          if (mounted) Navigator.of(context).pop();
        case 'duration':
          final ms = args['ms'];
          if (ms is int && ms > 0) _durationMs = ms;
        case 'audience':
          setState(() => _audience = args['value'] as int? ?? 1);
          await _push();
        case 'publish':
          await _publish();
      }
      return null;
    });
    _push();
  }

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    await _push();
    try {
      if (widget.isVideo) {
        await _publishVideo();
      } else {
        await _publishPhoto();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _publishing = false);
      await _push();
      if (!mounted) return;
      Haptics.error();
      showCustomNotification(context, error.toString());
    }
  }

  Future<void> _publishPhoto() async {
    final url = await messagesModule.requestPhotoUploadUrl(type: 1);
    if (url == null || url.isEmpty) {
      throw Exception('Не удалось получить адрес загрузки');
    }
    final segments = widget.file.uri.pathSegments;
    final filename = segments.isNotEmpty ? segments.last : 'story.jpg';
    final token = await fileUploader.uploadPhoto(
      Uri.parse(url),
      widget.file,
      filename: filename.isEmpty ? 'story.jpg' : filename,
    );
    if (token == null || token.isEmpty) {
      throw Exception('Не удалось загрузить фото');
    }
    await storiesModule.publishPhoto(
      photoToken: token,
      settings: _audience,
      expiration: _storyExpiration,
    );
    _done();
  }

  Future<void> _publishVideo() async {
    final info = await messagesModule.requestVideoUploadUrl(type: 3);
    if (info == null || info.url.isEmpty) {
      throw Exception('Не удалось получить адрес загрузки');
    }
    final upload = await fileUploader.uploadVideoWithToken(
      Uri.parse(info.url),
      widget.file,
    );
    if (!upload.ok) throw Exception('Не удалось загрузить видео');
    final uploaded = upload.token;
    final token = (uploaded != null && uploaded.isNotEmpty) ? uploaded : info.token;
    if (token.isEmpty) throw Exception('Не удалось загрузить видео');
    await storiesModule.publishVideo(
      videoToken: token,
      durationMs: _durationMs,
      settings: _audience,
      expiration: _storyExpiration,
    );
    _done();
  }

  void _done() {
    if (!mounted) return;
    Haptics.success();
    Navigator.of(context).pop();
    showCustomNotification(context, 'История опубликована');
    storiesModule.loadFeed();
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: UiKitView(
        viewType: _type,
        creationParams: _chrome,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _created,
      ),
    );
  }
}
