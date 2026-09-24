import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'emoji_version_filter.dart';

class EmojiPlatformInfo {
  final TargetPlatform platform;
  final (int, int)? iosVersion;
  final int? androidApi;

  const EmojiPlatformInfo({
    required this.platform,
    this.iosVersion,
    this.androidApi,
  });

  bool supports(int emojiVersionTenths) => EmojiVersionFilter.isSupported(
        emojiVersionTenths,
        platform: platform,
        iosVersion: iosVersion,
        androidApi: androidApi,
      );
}

class EmojiPlatform {
  EmojiPlatform._();

  static EmojiPlatformInfo? _cached;
  static Future<EmojiPlatformInfo>? _loading;

  static Future<EmojiPlatformInfo> resolve() {
    if (EmojiVersionFilter.debugPlatform != null ||
        EmojiVersionFilter.debugIosVersion != null ||
        EmojiVersionFilter.debugAndroidApi != null) {
      return Future.value(
        EmojiPlatformInfo(
          platform:
              EmojiVersionFilter.debugPlatform ?? defaultTargetPlatform,
          iosVersion: EmojiVersionFilter.debugIosVersion,
          androidApi: EmojiVersionFilter.debugAndroidApi,
        ),
      );
    }
    return _loading ??= _load();
  }

  static Future<EmojiPlatformInfo> _load() async {
    final platform = defaultTargetPlatform;
    try {
      final plugin = DeviceInfoPlugin();
      if (platform == TargetPlatform.iOS) {
        final info = await plugin.iosInfo;
        final parsed = _parseIos(info.systemVersion);
        _cached = EmojiPlatformInfo(platform: platform, iosVersion: parsed);
      } else if (platform == TargetPlatform.android) {
        final info = await plugin.androidInfo;
        _cached = EmojiPlatformInfo(
          platform: platform,
          androidApi: info.version.sdkInt,
        );
      } else {
        _cached = EmojiPlatformInfo(platform: platform);
      }
    } catch (_) {
      _cached = EmojiPlatformInfo(platform: platform);
    }
    return _cached!;
  }

  static (int, int)? _parseIos(String systemVersion) {
    final parts = systemVersion.split('.');
    if (parts.isEmpty) return null;
    final major = int.tryParse(parts[0]);
    if (major == null) return null;
    final minor = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return (major, minor);
  }

  @visibleForTesting
  static void debugReset() {
    _cached = null;
    _loading = null;
  }
}
