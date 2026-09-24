import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmojiSkinPrefs {
  EmojiSkinPrefs._();

  static const prefKey = 'komet_emoji_skin_tones';

  static final ValueNotifier<Map<String, String>> current =
      ValueNotifier<Map<String, String>>(const {});

  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefKey);
    if (raw == null || raw.isEmpty) {
      current.value = const {};
      return;
    }
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      current.value = map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      current.value = const {};
    }
  }

  static String displayGlyph(String base, List<String> variants) {
    final chosen = current.value[base];
    if (chosen == null || chosen.isEmpty) return base;
    if (chosen == base) return base;
    if (variants.contains(chosen)) return chosen;
    return base;
  }

  static Future<void> save(String base, String glyph) async {
    await ensureLoaded();
    final next = Map<String, String>.from(current.value);
    if (glyph == base) {
      next.remove(base);
    } else {
      next[base] = glyph;
    }
    current.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, json.encode(next));
  }

  @visibleForTesting
  static void debugReset() {
    _loaded = false;
    current.value = const {};
  }
}
