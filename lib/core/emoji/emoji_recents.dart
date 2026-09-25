import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
sealed class EmojiRecent {
  const EmojiRecent();

  String get storageKey;

  static EmojiRecent? parse(String raw) {
    if (raw.startsWith(EmojiRecentGlyph.prefix)) {
      final glyph = raw.substring(EmojiRecentGlyph.prefix.length);
      return glyph.isEmpty ? null : EmojiRecentGlyph(glyph);
    }
    if (raw.startsWith(EmojiRecentAnimoji.prefix)) {
      final id = int.tryParse(raw.substring(EmojiRecentAnimoji.prefix.length));
      return id == null ? null : EmojiRecentAnimoji(id);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is EmojiRecent && other.storageKey == storageKey;

  @override
  int get hashCode => storageKey.hashCode;
}

final class EmojiRecentGlyph extends EmojiRecent {
  static const prefix = 'e:';

  final String glyph;

  const EmojiRecentGlyph(this.glyph);

  @override
  String get storageKey => '$prefix$glyph';
}

final class EmojiRecentAnimoji extends EmojiRecent {
  static const prefix = 'a:';

  final int id;

  const EmojiRecentAnimoji(this.id);

  @override
  String get storageKey => '$prefix$id';
}

class EmojiRecents {
  EmojiRecents._();

  static const prefKey = 'komet_recent_emoji';
  static const legacyPrefKey = 'komet_recent_standard_emoji';
  static const legacyAnimojiPrefKey = 'komet_recent_animoji';
  static const maxItems = 40;

  static final ValueNotifier<List<EmojiRecent>> current =
      ValueNotifier<List<EmojiRecent>>(const []);

  static Future<void>? _loading;

  static Future<void> ensureLoaded() => _loading ??= _load();

  static Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(prefKey);
    if (stored != null) {
      current.value = _dedupe(stored.map(EmojiRecent.parse).nonNulls);
      return;
    }
    final glyphs = prefs.getStringList(legacyPrefKey) ?? const [];
    final animojiIds = prefs.getStringList(legacyAnimojiPrefKey) ?? const [];
    current.value = _dedupe([
      for (final glyph in glyphs)
        if (glyph.isNotEmpty) EmojiRecentGlyph(glyph),
      for (final id in animojiIds.map(int.tryParse).nonNulls)
        EmojiRecentAnimoji(id),
    ]);
    await _save(prefs);
    await prefs.remove(legacyPrefKey);
  }

  static Future<void> noteGlyph(String glyph) => _note(EmojiRecentGlyph(glyph));

  static Future<void> noteAnimoji(int id) => _note(EmojiRecentAnimoji(id));

  static Future<void> _note(EmojiRecent entry) async {
    await ensureLoaded();
    current.value = _dedupe([entry, ...current.value]);
    await _save(await SharedPreferences.getInstance());
  }

  static List<EmojiRecent> _dedupe(Iterable<EmojiRecent> entries) {
    final seen = <EmojiRecent>{};
    final result = <EmojiRecent>[];
    for (final entry in entries) {
      if (result.length >= maxItems) break;
      if (seen.add(entry)) result.add(entry);
    }
    return List.unmodifiable(result);
  }

  static Future<void> _save(SharedPreferences prefs) => prefs.setStringList(
    prefKey,
    [for (final e in current.value) e.storageKey],
  );

  @visibleForTesting
  static void debugReset() {
    _loading = null;
    current.value = const [];
  }
}
