import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmojiRecents {
  EmojiRecents._();

  static const prefKey = 'komet_recent_standard_emoji';
  static const maxItems = 32;

  static final ValueNotifier<List<String>> current =
      ValueNotifier<List<String>>(const []);

  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    current.value = prefs.getStringList(prefKey) ?? const [];
  }

  static Future<void> noteUsed(String emoji) async {
    await ensureLoaded();
    final next = <String>[emoji, ...current.value.where((e) => e != emoji)];
    if (next.length > maxItems) {
      current.value = next.sublist(0, maxItems);
    } else {
      current.value = next;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(prefKey, current.value);
  }

  @visibleForTesting
  static void debugReset() {
    _loaded = false;
    current.value = const [];
  }
}
