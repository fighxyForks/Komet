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

  test('recents persist and dedupe', () async {
    await EmojiRecents.noteUsed('😀');
    await EmojiRecents.noteUsed('🎉');
    await EmojiRecents.noteUsed('😀');
    expect(EmojiRecents.current.value.first, '😀');
    expect(EmojiRecents.current.value, containsAll(['😀', '🎉']));
    EmojiRecents.debugReset();
    await EmojiRecents.ensureLoaded();
    expect(EmojiRecents.current.value.first, '😀');
  });

  test('skin tone preference persists per base glyph', () async {
    await EmojiSkinPrefs.save('👋', '👋🏽');
    expect(EmojiSkinPrefs.displayGlyph('👋', const ['👋🏻', '👋🏽']), '👋🏽');
    EmojiSkinPrefs.debugReset();
    await EmojiSkinPrefs.ensureLoaded();
    expect(EmojiSkinPrefs.displayGlyph('👋', const ['👋🏻', '👋🏽']), '👋🏽');
  });
}
