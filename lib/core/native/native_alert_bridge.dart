import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
class NativePromptResult {
  final String? text;

  const NativePromptResult(this.text);
}

class NativeAlertBridge {
  NativeAlertBridge._();

  static const channel = MethodChannel('ru.komet.app/native_alert');

  static bool? debugAvailable;

  static bool get isAvailable {
    if (debugAvailable != null) return debugAvailable!;
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<NativePromptResult?> prompt({
    String? title,
    String? message,
    String? placeholder,
    String? text,
    required String confirm,
    required String cancel,
    bool secure = false,
    TextInputType? keyboardType,
  }) async {
    if (!isAvailable) return null;
    try {
      final value = await channel.invokeMethod<String>('prompt', {
        'title': title,
        'message': message,
        'placeholder': placeholder,
        'text': text,
        'confirm': confirm,
        'cancel': cancel,
        'secure': secure,
        'keyboard': keyboardName(keyboardType),
      });
      return NativePromptResult(value);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @visibleForTesting
  static String keyboardName(TextInputType? type) => switch (type) {
    TextInputType.url => 'url',
    TextInputType.emailAddress => 'email',
    TextInputType.number || TextInputType.phone => 'number',
    _ => 'text',
  };

  @visibleForTesting
  static void debugReset() {
    debugAvailable = null;
  }
}
