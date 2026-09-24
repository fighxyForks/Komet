import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'emoji_category.dart';
import 'emoji_entry.dart';
import 'emoji_platform.dart';

class EmojiSearchHit {
  final EmojiEntry entry;
  final int score;

  const EmojiSearchHit(this.entry, this.score);
}

class EmojiCatalog {
  EmojiCatalog._();

  static final EmojiCatalog instance = EmojiCatalog._();

  static const assetPath = 'assets/emoji_data.json';
  static const _variationSelector = '️';
  static final _wordPattern = RegExp(r'[0-9a-zа-яё\-]{2,}', unicode: true);

  final List<EmojiEntry> _all = [];
  final Map<EmojiCategory, List<EmojiEntry>> _byCategory = {
    for (final c in EmojiCategory.values) c: <EmojiEntry>[],
  };
  Future<void>? _loading;
  String? unicodeEmojiVersion;

  List<EmojiEntry> get all => List.unmodifiable(_all);

  List<EmojiEntry> byCategory(EmojiCategory category) =>
      List.unmodifiable(_byCategory[category] ?? const []);

  Future<void> ensureLoaded() async {
    if (_all.isNotEmpty) return;
    _loading ??= _load();
    await _loading;
    if (_all.isEmpty) {
      _loading = null;
      _loading ??= _load();
      await _loading;
    }
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString(assetPath);
    final map = json.decode(raw) as Map<String, dynamic>;
    unicodeEmojiVersion = map['unicodeEmojiVersion'] as String?;
    final items = map['items'] as List<dynamic>;
    for (final row in items) {
      final list = row as List<dynamic>;
      final glyph = list[0] as String;
      final name = list[1] as String;
      final category = EmojiCategoryCodec.fromIndex(list[2] as int);
      final versionTenths = list[3] as int;
      final skinCapable = (list[4] as int) == 1;
      final keywords = (list[5] as String)
          .split(' ')
          .where((t) => t.isNotEmpty)
          .toList(growable: false);
      final skins = list.length > 6
          ? (list[6] as List<dynamic>).cast<String>()
          : const <String>[];
      final entry = EmojiEntry(
        glyph: glyph,
        name: name,
        category: category,
        versionTenths: versionTenths,
        skinToneCapable: skinCapable,
        skinToneVariants: skins,
        keywords: keywords,
      );
      _all.add(entry);
      _byCategory[category]!.add(entry);
    }
  }

  List<EmojiEntry> filteredForPlatform(EmojiPlatformInfo platform) {
    return [
      for (final e in _all)
        if (platform.supports(e.versionTenths)) e,
    ];
  }

  List<EmojiEntry> categoryForPlatform(
    EmojiCategory category,
    EmojiPlatformInfo platform,
  ) {
    return [
      for (final e in _byCategory[category]!)
        if (platform.supports(e.versionTenths)) e,
    ];
  }

  List<EmojiSearchHit> search(
    String query,
    EmojiPlatformInfo platform, {
    int limit = 200,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final words = _wordPattern
        .allMatches(q)
        .map((m) => m.group(0)!)
        .toList(growable: false);
    final normalizedQuery = normalize(q);
    final hits = <EmojiSearchHit>[];
    for (final entry in _all) {
      if (!platform.supports(entry.versionTenths)) continue;
      final score = _score(entry, normalizedQuery, words);
      if (score > 0) hits.add(EmojiSearchHit(entry, score));
    }
    hits.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.entry.name.compareTo(b.entry.name);
    });
    if (hits.length <= limit) return hits;
    return hits.sublist(0, limit);
  }

  int _score(EmojiEntry entry, String query, List<String> words) {
    var score = 0;
    final glyphKey = normalize(entry.glyph);
    if (query.contains(glyphKey) || glyphKey == query) score += 1000;
    final name = entry.name.toLowerCase();
    if (name == query) score += 800;
    if (name.startsWith(query)) score += 400;
    for (final word in words) {
      var best = 0;
      if (name.startsWith(word)) best = 300;
      for (final token in entry.keywords) {
        if (token == word) {
          best = best < 500 ? 500 : best;
        } else if (token.startsWith(word)) {
          best = best < 200 ? 200 : best;
        } else if (token.contains(word) && word.length >= 3) {
          best = best < 50 ? 50 : best;
        }
      }
      score += best;
    }
    return score;
  }

  static String normalize(String emoji) =>
      emoji.replaceAll(_variationSelector, '');

  @visibleForTesting
  void debugReset() {
    _all.clear();
    for (final list in _byCategory.values) {
      list.clear();
    }
    _loading = null;
    unicodeEmojiVersion = null;
  }

  @visibleForTesting
  void debugLoadItems(List<EmojiEntry> items) {
    debugReset();
    _loading = Future.value();
    for (final entry in items) {
      _all.add(entry);
      _byCategory[entry.category]!.add(entry);
    }
  }
}
