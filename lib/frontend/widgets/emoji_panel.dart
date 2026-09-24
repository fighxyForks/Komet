import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/emoji/emoji_catalog.dart';
import '../../core/emoji/emoji_category.dart';
import '../../core/emoji/emoji_entry.dart';
import '../../core/emoji/emoji_platform.dart';
import '../../core/emoji/emoji_recents.dart';
import '../../core/emoji/emoji_skin_prefs.dart';
import '../../core/emoji/emoji_version_filter.dart';
import '../../frontend/motion/ios_haptics.dart';
import '../../l10n/app_localizations.dart';
import '../../core/emoji/emoji_animoji_source.dart';
import '../../models/animoji.dart';
import 'glass/ios_glass.dart';
import 'glass/ios_metrics.dart';
import 'glass/ios_palette.dart';
import 'glass/ios_symbols.dart';
import 'glass/ios_tappable.dart';
import 'glass/ios_typography.dart';
import 'lottie_image.dart';
import 'small_spinner.dart';

class _DragScrollBehavior extends MaterialScrollBehavior {
  const _DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
}

enum _PanelTabKind { recent, category, animoji }

class _PanelTab {
  final _PanelTabKind kind;
  final EmojiCategory? category;
  final String title;
  final IconData Function(BuildContext context) icon;

  const _PanelTab({
    required this.kind,
    required this.title,
    required this.icon,
    this.category,
  });
}

class EmojiPanel extends StatefulWidget {
  final void Function(Animoji animoji) onEmojiTap;
  final void Function(String emoji)? onPlainEmojiTap;

  const EmojiPanel({
    super.key,
    required this.onEmojiTap,
    this.onPlainEmojiTap,
  });

  @override
  State<EmojiPanel> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel> {
  static const double _tabBarHeight = 48;
  static const double _headerHeight = 28;
  static const double _searchHeight = 48;

  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  final ValueNotifier<bool> _scrolling = ValueNotifier(false);
  final Map<String, GlobalKey> _sectionKeys = {};

  bool _loading = true;
  Object? _error;
  int _selectedTab = 0;
  bool _jumping = false;
  EmojiPlatformInfo? _platform;
  List<_PanelTab> _tabs = const [];
  List<EmojiSearchHit> _searchHits = const [];
  List<Animoji> _animojis = const [];
  OverlayEntry? _skinOverlay;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _search.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _dismissSkinPicker();
    _scroll.removeListener(_onScroll);
    _search.removeListener(_onSearchChanged);
    _scroll.dispose();
    _search.dispose();
    _scrolling.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await EmojiCatalog.instance.ensureLoaded();
      unawaited(EmojiRecents.ensureLoaded());
      unawaited(EmojiSkinPrefs.ensureLoaded());
      _platform = EmojiPlatformInfo(
        platform: EmojiVersionFilter.debugPlatform ?? defaultTargetPlatform,
        iosVersion: EmojiVersionFilter.debugIosVersion,
        androidApi: EmojiVersionFilter.debugAndroidApi,
      );
      if (EmojiVersionFilter.debugPlatform == null &&
          EmojiVersionFilter.debugIosVersion == null &&
          EmojiVersionFilter.debugAndroidApi == null) {
        _platform = await EmojiPlatform.resolve();
      }
      if (!mounted) return;
      _rebuildTabs();
      setState(() => _loading = false);
      unawaited(_loadAnimoji());
    } catch (e, st) {
      assert(() {
        debugPrint('EmojiPanel load failed: $e\n$st');
        return true;
      }());
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _loadAnimoji() async {
    try {
      final list = await EmojiAnimojiSource.load().timeout(const Duration(seconds: 8));
      if (!mounted) return;
      _animojis = list;
      _rebuildTabs();
      setState(() {});
    } catch (_) {}
  }

  void _rebuildTabs() {
    final l10n = AppLocalizations.of(context)!;
    final tabs = <_PanelTab>[];
    if (EmojiRecents.current.value.isNotEmpty) {
      tabs.add(
        _PanelTab(
          kind: _PanelTabKind.recent,
          title: l10n.emojiPanelRecent,
          icon: (c) => IosSymbols.schedule(c),
        ),
      );
    }
    for (final category in EmojiCategory.values) {
      tabs.add(
        _PanelTab(
          kind: _PanelTabKind.category,
          category: category,
          title: _categoryTitle(l10n, category),
          icon: (c) => _categoryIcon(c, category),
        ),
      );
    }
    if (_animojis.isNotEmpty) {
      tabs.add(
        _PanelTab(
          kind: _PanelTabKind.animoji,
          title: l10n.emojiPanelAnimated,
          icon: (c) => IosSymbols.animation(c),
        ),
      );
    }
    _tabs = tabs;
    for (final tab in tabs) {
      _sectionKeys.putIfAbsent(_sectionId(tab), GlobalKey.new);
    }
  }

  String _sectionId(_PanelTab tab) {
    switch (tab.kind) {
      case _PanelTabKind.recent:
        return 'recent';
      case _PanelTabKind.animoji:
        return 'animoji';
      case _PanelTabKind.category:
        return tab.category!.id;
    }
  }

  String _categoryTitle(AppLocalizations l10n, EmojiCategory category) {
    switch (category) {
      case EmojiCategory.smileysPeople:
        return l10n.emojiPanelSmileysPeople;
      case EmojiCategory.animalsNature:
        return l10n.emojiPanelAnimalsNature;
      case EmojiCategory.foodDrink:
        return l10n.emojiPanelFoodDrink;
      case EmojiCategory.activity:
        return l10n.emojiPanelActivity;
      case EmojiCategory.travelPlaces:
        return l10n.emojiPanelTravelPlaces;
      case EmojiCategory.objects:
        return l10n.emojiPanelObjects;
      case EmojiCategory.symbols:
        return l10n.emojiPanelSymbols;
      case EmojiCategory.flags:
        return l10n.emojiPanelFlags;
    }
  }

  IconData _categoryIcon(BuildContext context, EmojiCategory category) {
    switch (category) {
      case EmojiCategory.smileysPeople:
        return IosSymbols.emojiEmotions(context);
      case EmojiCategory.animalsNature:
        return IosSymbols.adapt(context, Symbols.pets);
      case EmojiCategory.foodDrink:
        return IosSymbols.adapt(context, Symbols.restaurant);
      case EmojiCategory.activity:
        return IosSymbols.adapt(context, Symbols.sports_soccer);
      case EmojiCategory.travelPlaces:
        return IosSymbols.adapt(context, Symbols.flight);
      case EmojiCategory.objects:
        return IosSymbols.adapt(context, Symbols.lightbulb);
      case EmojiCategory.symbols:
        return IosSymbols.adapt(context, Symbols.favorite);
      case EmojiCategory.flags:
        return IosSymbols.flag(context);
    }
  }

  void _onSearchChanged() {
    final platform = _platform;
    if (platform == null) return;
    final q = _search.text;
    setState(() {
      _searchHits = q.trim().isEmpty
          ? const []
          : EmojiCatalog.instance.search(q, platform);
      if (q.trim().isNotEmpty) _selectedTab = 0;
    });
  }

  void _onScroll() {
    if (_jumping || _search.text.trim().isNotEmpty || _tabs.isEmpty) return;
    final positions = <int, double>{};
    for (var i = 0; i < _tabs.length; i++) {
      final ctx = _sectionKeys[_sectionId(_tabs[i])]?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final offset = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject()).dy;
      positions[i] = offset;
    }
    if (positions.isEmpty) return;
    var best = _selectedTab;
    var bestDy = double.infinity;
    positions.forEach((i, dy) {
      final score = dy.abs();
      if (dy <= 8 && score < bestDy) {
        bestDy = score;
        best = i;
      }
    });
    if (best != _selectedTab) setState(() => _selectedTab = best);
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n is ScrollStartNotification || n is ScrollUpdateNotification) {
      if (!_scrolling.value) _scrolling.value = true;
    } else if (n is ScrollEndNotification) {
      if (_scrolling.value) _scrolling.value = false;
    }
    return false;
  }

  Future<void> _jumpTo(int index) async {
    if (!mounted || index < 0 || index >= _tabs.length) return;
    if (IosGlass.of(context)) IosHaptics.selectionChange();
    setState(() => _selectedTab = index);
    final key = _sectionKeys[_sectionId(_tabs[index])];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    _jumping = true;
    await Scrollable.ensureVisible(
      ctx,
      alignment: 0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    _jumping = false;
  }

  void _insertPlain(String emoji) {
    widget.onPlainEmojiTap?.call(emoji);
    unawaited(EmojiRecents.noteUsed(EmojiCatalog.normalize(emoji)).then((_) {
      if (!mounted) return;
      final hadRecent = _tabs.any((t) => t.kind == _PanelTabKind.recent);
      _rebuildTabs();
      if (!hadRecent && _tabs.any((t) => t.kind == _PanelTabKind.recent)) {
        setState(() {});
      } else if (mounted) {
        setState(() {});
      }
    }));
    if (IosGlass.of(context)) IosHaptics.selectionChange();
  }

  void _insertAnimoji(Animoji animoji) {
    widget.onEmojiTap(animoji);
    if (IosGlass.of(context)) IosHaptics.selectionChange();
  }

  void _dismissSkinPicker() {
    _skinOverlay?.remove();
    _skinOverlay = null;
  }

  void _showSkinPicker(BuildContext cellContext, EmojiEntry entry) {
    _dismissSkinPicker();
    final overlay = Overlay.of(context);
    final box = cellContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset.zero);
    final size = box.size;
    final ios = IosGlass.of(context);
    final cs = Theme.of(context).colorScheme;
    final options = <String>[entry.glyph, ...entry.skinToneVariants];
    if (IosGlass.of(context)) IosHaptics.selectionChange();
    _skinOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismissSkinPicker,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: (origin.dx - 20).clamp(8.0, MediaQuery.sizeOf(context).width - 220),
              top: origin.dy - 56,
              child: Material(
                elevation: 8,
                color: ios ? IosPalette.grouped(cs) : cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(ios ? 14 : 12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final glyph in options)
                        IosTappable(
                          onTap: () {
                            unawaited(EmojiSkinPrefs.save(entry.glyph, glyph));
                            _dismissSkinPicker();
                            _insertPlain(glyph);
                            setState(() {});
                          },
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: Text(glyph, style: const TextStyle(fontSize: 26)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: origin.dx,
              top: origin.dy,
              width: size.width,
              height: size.height,
              child: const IgnorePointer(child: SizedBox.expand()),
            ),
          ],
        );
      },
    );
    overlay.insert(_skinOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final ios = IosGlass.of(context);
    if (_loading) return const Center(child: SmallSpinner());
    if (_error != null) {
      return Center(
        child: Text(
          'Не удалось загрузить эмодзи',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        ),
      );
    }
    final searching = _search.text.trim().isNotEmpty;

    return ScrollConfiguration(
      behavior: const _DragScrollBehavior(),
      child: Column(
        children: [
          _buildSearch(cs, l10n, ios),
          if (!searching) ...[
            _buildTabBar(cs, ios),
            Divider(
              height: 1,
              thickness: 1,
              color: ios
                  ? IosPalette.separator(cs)
                  : cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ],
          Expanded(
            child: searching ? _buildSearchResults(cs, l10n) : _buildSections(cs),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(ColorScheme cs, AppLocalizations l10n, bool ios) {
    return SizedBox(
      height: _searchHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: ios
            ? CupertinoSearchTextField(
                controller: _search,
                placeholder: l10n.emojiPanelSearchHint,
                style: TextStyle(
                  color: IosPalette.label(cs),
                  fontSize: IosTypography.callout,
                ),
                placeholderStyle: TextStyle(
                  color: IosPalette.secondaryLabel(cs),
                  fontSize: IosTypography.callout,
                ),
                backgroundColor: IosPalette.searchFill(cs),
                borderRadius: BorderRadius.circular(10),
              )
            : TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: l10n.emojiPanelSearchHint,
                  prefixIcon: Icon(Symbols.search, color: cs.onSurfaceVariant),
                  isDense: true,
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs, bool ios) {
    return SizedBox(
      height: _tabBarHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        itemCount: _tabs.length,
        itemBuilder: (context, i) {
          final tab = _tabs[i];
          final selected = i == _selectedTab;
          final child = Container(
            width: ios ? IosMetrics.minHitTarget : 40,
            height: ios ? IosMetrics.minHitTarget : 40,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(
              color: selected
                  ? (ios
                      ? IosPalette.selectedTab(cs)
                      : cs.surfaceContainerHighest)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              tab.icon(context),
              size: 22,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
          );
          return IosTappable(
            onTap: () => _jumpTo(i),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(ColorScheme cs, AppLocalizations l10n) {
    if (_searchHits.isEmpty) {
      return Center(
        child: Text(
          l10n.emojiPanelNoResults,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 44).floor().clamp(6, 10);
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
          ),
          itemCount: _searchHits.length,
          itemBuilder: (context, i) {
            final entry = _searchHits[i].entry;
            return _EmojiTextCell(
              key: ValueKey('search-${entry.glyph}'),
              entry: entry,
              onTap: _insertPlain,
              onLongPress: entry.skinToneCapable
                  ? (ctx) => _showSkinPicker(ctx, entry)
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildSections(ColorScheme cs) {
    final platform = _platform!;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: LottieScrollScope(
        isScrolling: _scrolling,
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            for (final tab in _tabs) ..._sliversFor(tab, platform, cs),
          ],
        ),
      ),
    );
  }

  List<Widget> _sliversFor(
    _PanelTab tab,
    EmojiPlatformInfo platform,
    ColorScheme cs,
  ) {
    final id = _sectionId(tab);
    final header = SliverToBoxAdapter(
      key: _sectionKeys[id],
      child: SizedBox(
        height: _headerHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              tab.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );

    if (tab.kind == _PanelTabKind.animoji) {
      return [
        header,
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final columns =
                (constraints.crossAxisExtent / 44).floor().clamp(6, 10);
            return SliverGrid(
              gridDelegate: SliverGridFixed(columns),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final animoji = _animojis[i];
                  return _AnimojiCell(
                    key: ValueKey('animoji-${animoji.id}'),
                    animoji: animoji,
                    onTap: _insertAnimoji,
                  );
                },
                childCount: _animojis.length,
              ),
            );
          },
        ),
      ];
    }

    final List<String> glyphs;
    final List<EmojiEntry?> entries;
    if (tab.kind == _PanelTabKind.recent) {
      glyphs = EmojiRecents.current.value;
      entries = List<EmojiEntry?>.filled(glyphs.length, null);
    } else {
      final list =
          EmojiCatalog.instance.categoryForPlatform(tab.category!, platform);
      glyphs = [
        for (final e in list)
          EmojiSkinPrefs.displayGlyph(e.glyph, e.skinToneVariants),
      ];
      entries = list;
    }

    return [
      header,
      SliverLayoutBuilder(
        builder: (context, constraints) {
          final columns =
              (constraints.crossAxisExtent / 44).floor().clamp(6, 10);
          return SliverGrid(
            gridDelegate: SliverGridFixed(columns),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final entry = tab.kind == _PanelTabKind.recent
                    ? null
                    : entries[i];
                final glyph = glyphs[i];
                if (entry != null) {
                  return _EmojiTextCell(
                    key: ValueKey('e-${entry.glyph}'),
                    entry: entry,
                    onTap: _insertPlain,
                    onLongPress: entry.skinToneCapable
                        ? (ctx) => _showSkinPicker(ctx, entry)
                        : null,
                  );
                }
                return _PlainEmojiCell(
                  key: ValueKey('r-$glyph'),
                  glyph: glyph,
                  onTap: () => _insertPlain(glyph),
                );
              },
              childCount: glyphs.length,
            ),
          );
        },
      ),
    ];
  }
}

class SliverGridFixed extends SliverGridDelegateWithFixedCrossAxisCount {
  SliverGridFixed(int columns)
      : super(crossAxisCount: columns, childAspectRatio: 1);
}

class _EmojiTextCell extends StatelessWidget {
  final EmojiEntry entry;
  final void Function(String emoji) onTap;
  final void Function(BuildContext context)? onLongPress;

  const _EmojiTextCell({
    super.key,
    required this.entry,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final glyph =
        EmojiSkinPrefs.displayGlyph(entry.glyph, entry.skinToneVariants);
    return Builder(
      builder: (cellContext) {
        return IosTappable(
          onTap: () => onTap(glyph),
          onLongPress:
              onLongPress == null ? null : () => onLongPress!(cellContext),
          child: Center(
            child: Text(
              glyph,
              style: const TextStyle(fontSize: 28, height: 1),
            ),
          ),
        );
      },
    );
  }
}

class _PlainEmojiCell extends StatelessWidget {
  final String glyph;
  final VoidCallback onTap;

  const _PlainEmojiCell({super.key, required this.glyph, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IosTappable(
      onTap: onTap,
      child: Center(
        child: Text(glyph, style: const TextStyle(fontSize: 28, height: 1)),
      ),
    );
  }
}

class _AnimojiCell extends StatelessWidget {
  final Animoji animoji;
  final void Function(Animoji animoji) onTap;

  const _AnimojiCell({super.key, required this.animoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IosTappable(
      onTap: () => onTap(animoji),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: LottieImage(
          url: animoji.iconUrl,
          lottieUrl: animoji.lottieUrl,
          memCacheWidth: 120,
        ),
      ),
    );
  }
}
