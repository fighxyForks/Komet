import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/emoji/emoji_catalog.dart';
import '../../core/emoji/emoji_category.dart';
import '../../core/emoji/emoji_entry.dart';
import '../../core/emoji/emoji_platform.dart';
import '../../core/emoji/emoji_recents.dart';

class NativeEmojiPanel extends StatefulWidget {
  final ValueChanged<String> onPick;

  const NativeEmojiPanel({super.key, required this.onPick});

  @override
  State<NativeEmojiPanel> createState() => _NativeEmojiPanelState();
}

class _NativeEmojiPanelState extends State<NativeEmojiPanel> {
  static const _type = 'ru.komet.app/native_emoji';
  static const _titles = {
    'recent': 'Недавние',
    'smileysPeople': 'Смайлы',
    'animalsNature': 'Природа',
    'foodDrink': 'Еда',
    'activity': 'Занятия',
    'travelPlaces': 'Места',
    'objects': 'Предметы',
    'symbols': 'Символы',
    'flags': 'Флаги',
  };

  MethodChannel? _channel;
  EmojiPlatformInfo? _platform;
  String _category = 'recent';

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    await EmojiCatalog.instance.ensureLoaded();
    await EmojiRecents.ensureLoaded();
    _platform = await EmojiPlatform.resolve();
    if (mounted) await _publish(_category);
  }

  bool _supported(EmojiEntry entry) =>
      _platform?.supports(entry.versionTenths) ?? true;

  List<String> _glyphs(String category) {
    if (category == 'recent') {
      return [
        for (final recent in EmojiRecents.current.value)
          if (recent is EmojiRecentGlyph) recent.glyph,
      ];
    }
    final match = EmojiCategory.values.where((item) => item.id == category);
    if (match.isEmpty) return const [];
    return [
      for (final entry in EmojiCatalog.instance.byCategory(match.first))
        if (_supported(entry)) entry.glyph,
    ];
  }

  List<String> _search(String query) {
    final platform = _platform;
    if (platform == null || query.trim().isEmpty) return _glyphs(_category);
    return [
      for (final hit in EmojiCatalog.instance.search(query, platform, limit: 80))
        hit.entry.glyph,
    ];
  }

  List<String> _skins(String glyph) {
    for (final entry in EmojiCatalog.instance.all) {
      if (entry.glyph == glyph || entry.skinToneVariants.contains(glyph)) {
        return [entry.glyph, ...entry.skinToneVariants];
      }
    }
    return const [];
  }

  Map<String, Object?> _payload(List<String> glyphs) => {
    'categories': [
      for (final entry in _titles.entries) {'id': entry.key, 'title': entry.value},
    ],
    'glyphs': glyphs,
  };

  Future<void> _publish(String category) async {
    _category = category;
    try {
      await _channel?.invokeMethod<void>('apply', _payload(_glyphs(category)));
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  void _created(int viewId) {
    final channel = MethodChannel('$_type/$viewId');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      final args = call.arguments is Map
          ? Map<String, Object?>.from(call.arguments as Map)
          : const <String, Object?>{};
      switch (call.method) {
        case 'category':
          await _publish(args['id'] as String? ?? 'recent');
        case 'search':
          final glyphs = _search(args['text'] as String? ?? '');
          await channel.invokeMethod<void>('apply', _payload(glyphs));
        case 'pick':
          final glyph = args['glyph'] as String? ?? '';
          if (glyph.isEmpty) return null;
          await EmojiRecents.noteGlyph(glyph);
          widget.onPick(glyph);
        case 'skins':
          return _skins(args['glyph'] as String? ?? '');
      }
      return null;
    });
    _publish(_category);
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: _type,
      onPlatformViewCreated: _created,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
