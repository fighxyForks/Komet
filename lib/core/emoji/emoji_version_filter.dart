import 'package:flutter/foundation.dart';

/// Maps Unicode emoji versions to the earliest OS release that ships them.
///
/// Values are conservative (known Apple/Google ship dates). Desktop hosts are
/// capped at Emoji 15.0 because font coverage varies widely.
///
/// | Emoji | iOS (major.minor) | Android API |
/// |-------|-------------------|-------------|
/// | ≤11.x | any               | any         |
/// | 12.0  | 13.2              | 29          |
/// | 12.1  | 13.2              | 29          |
/// | 13.0  | 14.5              | 30          |
/// | 13.1  | 14.5              | 30          |
/// | 14.0  | 15.4              | 31          |
/// | 15.0  | 16.4              | 34          |
/// | 15.1  | 17.4              | 35          |
/// | 16.0  | 18.4              | 36          |
class EmojiVersionFilter {
  EmojiVersionFilter._();

  static const int desktopMaxTenths = 150;

  static (int, int)? debugIosVersion;
  static int? debugAndroidApi;
  static TargetPlatform? debugPlatform;

  static const Map<int, (int, int)> iosMinByEmojiTenths = {
    120: (13, 2),
    121: (13, 2),
    130: (14, 5),
    131: (14, 5),
    140: (15, 4),
    150: (16, 4),
    151: (17, 4),
    160: (18, 4),
  };

  static const Map<int, int> androidApiByEmojiTenths = {
    120: 29,
    121: 29,
    130: 30,
    131: 30,
    140: 31,
    150: 34,
    151: 35,
    160: 36,
  };

  static void debugReset() {
    debugIosVersion = null;
    debugAndroidApi = null;
    debugPlatform = null;
  }

  static bool isSupported(
    int emojiVersionTenths, {
    required TargetPlatform platform,
    (int, int)? iosVersion,
    int? androidApi,
  }) {
    if (emojiVersionTenths < 120) return true;
    switch (platform) {
      case TargetPlatform.iOS:
        final host = iosVersion;
        if (host == null) return emojiVersionTenths <= desktopMaxTenths;
        final required = _iosRequirement(emojiVersionTenths);
        if (required == null) return false;
        return _compareVersion(host, required) >= 0;
      case TargetPlatform.android:
        final api = androidApi;
        if (api == null) return emojiVersionTenths <= desktopMaxTenths;
        final required = _androidRequirement(emojiVersionTenths);
        if (required == null) return false;
        return api >= required;
      default:
        return emojiVersionTenths <= desktopMaxTenths;
    }
  }

  static int _compareVersion((int, int) a, (int, int) b) {
    if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
    return a.$2.compareTo(b.$2);
  }

  static (int, int)? _iosRequirement(int emojiTenths) {
    final exact = iosMinByEmojiTenths[emojiTenths];
    if (exact != null) return exact;
    (int, int)? next;
    var nextKey = 1 << 30;
    for (final entry in iosMinByEmojiTenths.entries) {
      if (entry.key >= emojiTenths && entry.key < nextKey) {
        nextKey = entry.key;
        next = entry.value;
      }
    }
    return next;
  }

  static int? _androidRequirement(int emojiTenths) {
    final exact = androidApiByEmojiTenths[emojiTenths];
    if (exact != null) return exact;
    int? next;
    var nextKey = 1 << 30;
    for (final entry in androidApiByEmojiTenths.entries) {
      if (entry.key >= emojiTenths && entry.key < nextKey) {
        nextKey = entry.key;
        next = entry.value;
      }
    }
    return next;
  }
}
