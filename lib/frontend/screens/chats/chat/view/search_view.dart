import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:komet/core/config/app_animations.dart';
import 'package:komet/core/config/app_chat_chrome.dart';
import 'package:komet/core/utils/format.dart';
import 'package:komet/frontend/widgets/animated_lottie_icon.dart';
import 'package:komet/frontend/widgets/glass/glass_capsule.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_tappable.dart';
import 'package:komet/frontend/widgets/glass/ios_typography.dart';
import 'package:komet/frontend/widgets/glass/ios_symbols.dart';
import 'package:komet/frontend/widgets/glass/ios_palette.dart';
import 'package:komet/frontend/widgets/glass/ios_metrics.dart';
import 'package:komet/frontend/widgets/glossy_pill.dart';
import 'package:komet/frontend/widgets/komet_avatar.dart';
import 'package:komet/frontend/widgets/small_spinner.dart';
import 'package:komet/frontend/screens/chats/chat/chat_search_controller.dart';
import 'package:komet/frontend/native/native_chat_search.dart';
import 'package:komet/frontend/screens/chats/chat/message_search_result.dart';
import '../../../../../core/config/app_fonts.dart';

class SearchTopBar extends StatelessWidget {
  const SearchTopBar({
    super.key,
    required this.cs,
    required this.glossy,
    required this.search,
    required this.focusNode,
    required this.onClose,
  });

  final ColorScheme cs;
  final bool glossy;
  final ChatSearchController search;
  final FocusNode focusNode;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ios = IosGlass.of(context);
    final fieldSize = ios ? IosTypography.composer : 16.0;
    final field = TextField(
      controller: search.searchController,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      onSubmitted: search.submit,
      cursorColor: cs.primary,
      style: TextStyle(
        color: ios ? IosPalette.label(cs) : cs.onSurface,
        fontSize: fieldSize,
        fontFamily: displayFontOf(context),
        letterSpacing: ios ? IosTypography.letterSpacing(fieldSize) : null,
      ),
      decoration: InputDecoration(
        hintText: 'Поиск…',
        hintStyle: TextStyle(
          color: ios ? IosPalette.secondaryLabel(cs) : cs.onSurfaceVariant,
          fontSize: fieldSize,
          fontFamily: displayFontOf(context),
          letterSpacing: ios ? IosTypography.letterSpacing(fieldSize) : null,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );

    final backBtn = IconButton(
      icon: Icon(IosSymbols.back(context),
        weight: glossy ? 500 : 400,
        color: cs.onSurface,
      ),
      onPressed: onClose,
    );
    final searchBtn = IconButton(
      icon: AnimatedLottieIcon(
        asset: AppAnimations.search,
        color: cs.onSurface,
        size: 24,
        active: true,
        animateOnMount: true,
      ),
      onPressed: () => search.submit(search.searchController.text),
    );

    if (IosGlass.of(context)) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 3, 12, 7),
        child: Row(
          children: [
            GlassIconButton(
              key: const ValueKey('ios-search-back'),
              icon: IosSymbols.back(context),
              iconSize: 20,
              size: IosMetrics.minHitTarget,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onClose,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassCapsule(
                key: const ValueKey('ios-search-field'),
                height: IosMetrics.searchBarHeight,
                padding: const EdgeInsets.only(left: 14, right: 2),
                child: Row(
                  children: [
                    Icon(
                      IosSymbols.search(context),
                      size: 18,
                      color: IosPalette.secondaryLabel(cs),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: field),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: search.searchController,
                      builder: (context, value, _) => value.text.isEmpty
                          ? const SizedBox(width: 12)
                          : IconButton(
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).deleteButtonTooltip,
                              icon: Icon(
                                IosSymbols.clearFill(context),
                                size: 20,
                                color: cs.onSurfaceVariant,
                              ),
                              onPressed: search.searchController.clear,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!glossy) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            backBtn,
            Expanded(child: field),
            searchBtn,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
      child: GlossyPill(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              backBtn,
              Expanded(child: field),
              searchBtn,
            ],
          ),
        ),
      ),
    );
  }
}

class SearchOverlay extends StatelessWidget {
  const SearchOverlay({
    super.key,
    required this.cs,
    required this.searchAnim,
    required this.search,
    required this.onOpenResult,
    required this.senderName,
    required this.senderAvatar,
    this.useNative = false,
  });

  final ColorScheme cs;
  final Animation<double> searchAnim;
  final ChatSearchController search;
  final void Function(MessageSearchResult) onOpenResult;
  final String Function(int) senderName;
  final String? Function(int) senderAvatar;
  final bool useNative;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: searchAnim,
      builder: (context, _) {
        final s = Curves.easeOut.transform(searchAnim.value.clamp(0.0, 1.0));
        if (s == 0) return const SizedBox.shrink();
        final chrome = AppChatChrome.current.value;
        final topPad = chrome == ChatChromeStyle.color
            ? 0.0
            : MediaQuery.paddingOf(context).top;
        return Positioned.fill(
          child: IgnorePointer(
            ignoring: s < 0.5,
            child: Opacity(
              opacity: s,
              child: Container(
                color: cs.surface,
                padding: EdgeInsets.only(top: topPad),
                child: _resultsContent(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _resultsContent(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: search.loading,
      builder: (context, loading, _) =>
          ValueListenableBuilder<List<MessageSearchResult>>(
            valueListenable: search.results,
            builder: (context, results, _) {
              if (useNative) {
                return NativeChatSearchResults(
                  search: search,
                  senderName: senderName,
                  senderAvatar: senderAvatar,
                  onOpen: onOpenResult,
                );
              }
              if (results.isNotEmpty) {
                return ListView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    top: 4,
                    bottom: MediaQuery.paddingOf(context).bottom + 16,
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, index) =>
                      _tile(context, results[index]),
                );
              }
              if (loading) {
                return Center(
                  child: SmallSpinner(size: 26, color: cs.onSurfaceVariant),
                );
              }
              return ValueListenableBuilder<bool>(
                valueListenable: search.performed,
                builder: (context, performed, _) {
                  if (!performed) return const SizedBox.shrink();
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Поиск ничего не вернул…',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: IosGlass.of(context)
                              ? IosPalette.secondaryLabel(cs)
                              : cs.onSurfaceVariant,
                          fontSize: IosGlass.of(context)
                              ? IosTypography.listSubtitle
                              : 16,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
    );
  }

  Widget _tile(BuildContext context, MessageSearchResult r) {
    final name = senderName(r.senderId);
    final date = formatDateWords(DateTime.fromMillisecondsSinceEpoch(r.time));
    final ios = IosGlass.of(context);
    return IosTappable(
      onTap: () => onOpenResult(r),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KometAvatar(
              name: name,
              imageUrl: senderAvatar(r.senderId),
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: ios
                                ? IosTypography.listTitle
                                : 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: displayFontOf(context),
                            letterSpacing: ios
                                ? IosTypography.letterSpacing(
                                    IosTypography.listTitle,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: TextStyle(
                          color: ios
                              ? IosPalette.secondaryLabel(cs)
                              : cs.onSurfaceVariant,
                          fontSize: ios ? IosTypography.callLabel : 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  _highlighted(context, r.text, r.highlights),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlighted(
    BuildContext context,
    String text,
    List<String> highlights,
  ) {
    final ios = IosGlass.of(context);
    final baseStyle = TextStyle(
      color: ios ? IosPalette.label(cs) : cs.onSurface,
      fontSize: ios ? IosTypography.listSubtitle : 15,
      letterSpacing: ios
          ? IosTypography.letterSpacing(IosTypography.listSubtitle)
          : null,
    );
    final terms = highlights
        .where((h) => h.trim().isNotEmpty)
        .map((h) => h.toLowerCase())
        .toSet();
    if (text.isEmpty || terms.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final lower = text.toLowerCase();
    final ranges = <List<int>>[];
    for (final term in terms) {
      var start = 0;
      while (true) {
        final idx = lower.indexOf(term, start);
        if (idx < 0) break;
        ranges.add([idx, idx + term.length]);
        start = idx + term.length;
      }
    }
    if (ranges.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    ranges.sort((a, b) => a[0].compareTo(b[0]));
    final merged = <List<int>>[];
    for (final r in ranges) {
      if (merged.isNotEmpty && r[0] <= merged.last[1]) {
        merged.last[1] = math.max(merged.last[1], r[1]);
      } else {
        merged.add([r[0], r[1]]);
      }
    }

    final highlightStyle = baseStyle.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w600,
      backgroundColor: cs.primary.withValues(alpha: 0.18),
    );
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final r in merged) {
      if (r[0] > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, r[0])));
      }
      spans.add(
        TextSpan(text: text.substring(r[0], r[1]), style: highlightStyle),
      );
      cursor = r[1];
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
