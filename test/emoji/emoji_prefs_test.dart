import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/emoji/emoji_recents.dart';
import 'package:komet/core/emoji/emoji_skin_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EmojiRecents.debugReset();
    EmojiSkinPrefs.debugReset();
  });

  tearDown(() {
    EmojiRecents.debugReset();
    EmojiSkinPrefs.debugReset();
  });

  test('recents keep glyphs and animoji in one ordered list', () async {
    await EmojiRecents.noteGlyph('😀');
    await EmojiRecents.noteAnimoji(7);
    await EmojiRecents.noteGlyph('🎉');
    await EmojiRecents.noteGlyph('😀');
    expect(EmojiRecents.current.value, const [
      EmojiRecentGlyph('😀'),
      EmojiRecentGlyph('🎉'),
      EmojiRecentAnimoji(7),
    ]);
    EmojiRecents.debugReset();
    await EmojiRecents.ensureLoaded();
    expect(EmojiRecents.current.value, const [
      EmojiRecentGlyph('😀'),
      EmojiRecentGlyph('🎉'),
      EmojiRecentAnimoji(7),
    ]);
  });

  test('recents are capped', () async {
    for (var i = 0; i < EmojiRecents.maxItems + 5; i++) {
      await EmojiRecents.noteAnimoji(i);
    }
    expect(EmojiRecents.current.value, hasLength(EmojiRecents.maxItems));
    expect(
      EmojiRecents.current.value.first,
      const EmojiRecentAnimoji(EmojiRecents.maxItems + 4),
    );
  });

  test('legacy recents migrate on first load', () async {
    SharedPreferences.setMockInitialValues({
      EmojiRecents.legacyPrefKey: ['🎉', '😀'],
      EmojiRecents.legacyAnimojiPrefKey: ['3', 'bad', '5'],
    });
    await EmojiRecents.ensureLoaded();
    expect(EmojiRecents.current.value, const [
      EmojiRecentGlyph('🎉'),
      EmojiRecentGlyph('😀'),
      EmojiRecentAnimoji(3),
      EmojiRecentAnimoji(5),
    ]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(EmojiRecents.legacyPrefKey), isNull);
    expect(prefs.getStringList(EmojiRecents.prefKey), [
      'e:🎉',
      'e:😀',
      'a:3',
      'a:5',
    ]);
  });

  test('stored recents win over legacy ones', () async {
    SharedPreferences.setMockInitialValues({
      EmojiRecents.prefKey: ['a:9', 'e:🔥', 'junk'],
      EmojiRecents.legacyPrefKey: ['😀'],
    });
    await EmojiRecents.ensureLoaded();
    expect(EmojiRecents.current.value, const [
      EmojiRecentAnimoji(9),
      EmojiRecentGlyph('🔥'),
    ]);
  });

  test('skin tone preference persists per base glyph', () async {
    await EmojiSkinPrefs.save('👋', '👋🏽');
    expect(EmojiSkinPrefs.displayGlyph('👋', const ['👋🏻', '👋🏽']), '👋🏽');
    EmojiSkinPrefs.debugReset();
    await EmojiSkinPrefs.ensureLoaded();
    expect(EmojiSkinPrefs.displayGlyph('👋', const ['👋🏻', '👋🏽']), '👋🏽');
  });
}
