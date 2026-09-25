import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/emoji/emoji_version_filter.dart';

void main() {
  tearDown(EmojiVersionFilter.debugReset);

  test('iOS 16.4 supports Emoji 15.0 but not 15.1', () {
    expect(
      EmojiVersionFilter.isSupported(
        150,
        platform: TargetPlatform.iOS,
        iosVersion: (16, 4),
      ),
      isTrue,
    );
    expect(
      EmojiVersionFilter.isSupported(
        151,
        platform: TargetPlatform.iOS,
        iosVersion: (16, 4),
      ),
      isFalse,
    );
  });

  test('iOS 17.4 supports 15.1; 18.4 supports 16.0', () {
    expect(
      EmojiVersionFilter.isSupported(
        151,
        platform: TargetPlatform.iOS,
        iosVersion: (17, 4),
      ),
      isTrue,
    );
    expect(
      EmojiVersionFilter.isSupported(
        160,
        platform: TargetPlatform.iOS,
        iosVersion: (18, 3),
      ),
      isFalse,
    );
    expect(
      EmojiVersionFilter.isSupported(
        160,
        platform: TargetPlatform.iOS,
        iosVersion: (18, 4),
      ),
      isTrue,
    );
  });

  test('Android API mapping', () {
    expect(
      EmojiVersionFilter.isSupported(
        150,
        platform: TargetPlatform.android,
        androidApi: 34,
      ),
      isTrue,
    );
    expect(
      EmojiVersionFilter.isSupported(
        151,
        platform: TargetPlatform.android,
        androidApi: 34,
      ),
      isFalse,
    );
    expect(
      EmojiVersionFilter.isSupported(
        160,
        platform: TargetPlatform.android,
        androidApi: 36,
      ),
      isTrue,
    );
  });

  test('desktop caps at Emoji 15.0', () {
    expect(
      EmojiVersionFilter.isSupported(150, platform: TargetPlatform.macOS),
      isTrue,
    );
    expect(
      EmojiVersionFilter.isSupported(151, platform: TargetPlatform.macOS),
      isFalse,
    );
    expect(
      EmojiVersionFilter.isSupported(160, platform: TargetPlatform.linux),
      isFalse,
    );
  });

  test('legacy emoji always allowed', () {
    expect(
      EmojiVersionFilter.isSupported(
        10,
        platform: TargetPlatform.iOS,
        iosVersion: (12, 0),
      ),
      isTrue,
    );
  });
}
