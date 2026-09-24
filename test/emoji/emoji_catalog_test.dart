import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/emoji/emoji_catalog.dart';
import 'package:komet/core/emoji/emoji_category.dart';
import 'package:komet/core/emoji/emoji_platform.dart';
import 'package:komet/core/emoji/emoji_version_filter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    EmojiCatalog.instance.debugReset();
    EmojiVersionFilter.debugReset();
    EmojiPlatform.debugReset();
  });

  tearDown(() {
    EmojiCatalog.instance.debugReset();
    EmojiVersionFilter.debugReset();
    EmojiPlatform.debugReset();
  });

  test('loads Unicode catalog with categories', () async {
    await EmojiCatalog.instance.ensureLoaded();
    expect(EmojiCatalog.instance.unicodeEmojiVersion, '16.0');
    expect(EmojiCatalog.instance.all.length, greaterThan(1800));
    expect(
      EmojiCatalog.instance.byCategory(EmojiCategory.smileysPeople),
      isNotEmpty,
    );
    expect(
      EmojiCatalog.instance.byCategory(EmojiCategory.flags),
      isNotEmpty,
    );
  });

  test('category mapping keeps smileys and people together', () async {
    await EmojiCatalog.instance.ensureLoaded();
    final smileys =
        EmojiCatalog.instance.byCategory(EmojiCategory.smileysPeople);
    expect(smileys.any((e) => e.glyph == '😀'), isTrue);
    expect(smileys.any((e) => e.glyph == '👋'), isTrue);
  });

  test('search ranks RU and EN queries', () async {
    await EmojiCatalog.instance.ensureLoaded();
    EmojiVersionFilter.debugPlatform = TargetPlatform.macOS;
    final platform = await EmojiPlatform.resolve();

    final heart = EmojiCatalog.instance.search('сердце', platform);
    expect(heart, isNotEmpty);
    expect(
      heart.take(8).any((h) => h.entry.glyph.contains('❤') || h.entry.name.contains('heart')),
      isTrue,
    );

    final cat = EmojiCatalog.instance.search('кот', platform);
    expect(cat, isNotEmpty);

    final laugh = EmojiCatalog.instance.search('смех', platform);
    expect(laugh, isNotEmpty);

    final enHeart = EmojiCatalog.instance.search('heart', platform);
    expect(enHeart, isNotEmpty);
    expect(enHeart.first.score, greaterThan(0));
  });

  test('version filter hides newer emoji on older iOS', () async {
    await EmojiCatalog.instance.ensureLoaded();
    EmojiVersionFilter.debugPlatform = TargetPlatform.iOS;
    EmojiVersionFilter.debugIosVersion = (16, 4);
    final platform = await EmojiPlatform.resolve();
    final filtered = EmojiCatalog.instance.filteredForPlatform(platform);
    expect(filtered.length, lessThan(EmojiCatalog.instance.all.length));
    expect(filtered.every((e) => e.versionTenths <= 150), isTrue);
  });
}
