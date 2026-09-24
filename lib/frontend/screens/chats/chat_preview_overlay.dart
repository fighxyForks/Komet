import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/haptics.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/chat_menu_item.dart';
import '../../widgets/glass/glass_menu.dart';
import '../../widgets/glass/ios_glass.dart';
import 'chat_screen.dart';

Future<void> showIosChatPreview(
  BuildContext context, {
  required Rect sourceRect,
  required int chatId,
  required String name,
  required String imageUrl,
  required String chatType,
  required List<ChatMenuItem> actions,
  required VoidCallback onOpen,
}) {
  Haptics.medium();
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => ChatPreviewOverlay(
        sourceRect: sourceRect,
        chatId: chatId,
        name: name,
        imageUrl: imageUrl,
        chatType: chatType,
        actions: actions,
        onOpen: onOpen,
      ),
    ),
  );
}

class ChatPreviewOverlay extends StatefulWidget {
  static const double sideInset = 12;
  static const double maxCardHeight = 460;
  static const double cardRadius = 30;
  static const double menuGap = 7;
  static const double menuWidth = 250;
  static const double blurSigma = 20;
  static const Duration fadeDuration = Duration(milliseconds: 200);
  static const Duration dismissDuration = Duration(milliseconds: 200);
  static const Duration expandDuration = Duration(milliseconds: 260);
  static final SpringDescription spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 230,
    ratio: 1,
  );

  final Rect sourceRect;
  final int chatId;
  final String name;
  final String imageUrl;
  final String chatType;
  final List<ChatMenuItem> actions;
  final VoidCallback onOpen;

  const ChatPreviewOverlay({
    super.key,
    required this.sourceRect,
    required this.chatId,
    required this.name,
    required this.imageUrl,
    required this.chatType,
    required this.actions,
    required this.onOpen,
  });

  @override
  State<ChatPreviewOverlay> createState() => _ChatPreviewOverlayState();
}

class _ChatPreviewOverlayState extends State<ChatPreviewOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _grow = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: ChatPreviewOverlay.fadeDuration,
  );
  late final AnimationController _expand = AnimationController(
    vsync: this,
    duration: ChatPreviewOverlay.expandDuration,
  );
  late final VoidCallback _releaseGlass;
  bool _contentReady = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _releaseGlass = GlassSuppression.hold();
    unawaited(_fade.forward());
    unawaited(
      _grow
          .animateWith(SpringSimulation(ChatPreviewOverlay.spring, 0, 1, 0))
          .then((_) {
            if (mounted) setState(() => _contentReady = true);
          }),
    );
  }

  @override
  void dispose() {
    _grow.dispose();
    _fade.dispose();
    _expand.dispose();
    _releaseGlass();
    super.dispose();
  }

  Future<void> _dismiss({VoidCallback? then}) async {
    if (_closing) return;
    _closing = true;
    _grow.stop();
    await Future.wait([
      _fade.reverse(),
      _grow.animateTo(
        0,
        duration: ChatPreviewOverlay.dismissDuration,
        curve: Curves.easeInOut,
      ),
    ]);
    if (!mounted) return;
    Navigator.of(context).pop();
    then?.call();
  }

  Future<void> _open() async {
    if (_closing) return;
    _closing = true;
    Haptics.tap();
    _grow.stop();
    _grow.value = 1;
    await _expand.animateTo(1, curve: Curves.easeOutCubic);
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final route = ModalRoute.of(context);
    widget.onOpen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (route != null && route.isActive) navigator.removeRoute(route);
    });
  }

  void _onItemTap(ChatMenuItem item) {
    Haptics.tap();
    unawaited(_dismiss(then: item.onTap));
  }

  List<ChatMenuItem> _items(AppLocalizations l10n) => [
    ChatMenuItem(
      icon: Symbols.chat,
      label: l10n.chatPreviewOpen,
      onTap: () => unawaited(_open()),
    ),
    ...widget.actions,
  ];

  double _menuHeight(List<ChatMenuItem> items) =>
      items.length * GlassMenuStyle.rowHeight +
      items.where((i) => i.dividerAfter).length * 12 +
      10;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);
    final items = _items(l10n);
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = constraints.biggest;
        const inset = ChatPreviewOverlay.sideInset;
        final menuHeight = _menuHeight(items);
        final available =
            screen.height - padding.vertical - inset * 2 - menuHeight;
        final cardHeight = math.max(
          120.0,
          math.min(
            ChatPreviewOverlay.maxCardHeight,
            available - ChatPreviewOverlay.menuGap,
          ),
        );
        final total = cardHeight + ChatPreviewOverlay.menuGap + menuHeight;
        final top =
            padding.top +
            math.max(inset, (screen.height - padding.vertical - total) / 2);
        final card = Rect.fromLTWH(
          inset,
          top,
          screen.width - inset * 2,
          cardHeight,
        );
        final menu = Rect.fromLTWH(
          inset,
          card.bottom + ChatPreviewOverlay.menuGap,
          math.min(ChatPreviewOverlay.menuWidth, card.width),
          menuHeight,
        );
        return AnimatedBuilder(
          animation: Listenable.merge([_grow, _fade, _expand]),
          builder: (context, _) => _buildFrame(cs, screen, card, menu, items),
        );
      },
    );
  }

  Widget _buildFrame(
    ColorScheme cs,
    Size screen,
    Rect card,
    Rect menu,
    List<ChatMenuItem> items,
  ) {
    final fade = _fade.value;
    final grow = _grow.value;
    final expand = _expand.value;
    final scale = ui.lerpDouble(0.01, 1, grow)!;
    final dy = ui.lerpDouble(
      widget.sourceRect.center.dy - card.center.dy,
      0,
      grow,
    )!;
    final cardRect = Rect.lerp(card, Offset.zero & screen, expand)!;
    final radius = ui.lerpDouble(ChatPreviewOverlay.cardRadius, 0, expand)!;
    final dark = cs.brightness == Brightness.dark;
    final opacity = (fade * 1.3).clamp(0.0, 1.0);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            key: const ValueKey('chat-preview-barrier'),
            behavior: HitTestBehavior.opaque,
            onTap: () => unawaited(_dismiss()),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: ChatPreviewOverlay.blurSigma * fade,
                sigmaY: ChatPreviewOverlay.blurSigma * fade,
              ),
              child: ColoredBox(
                color: Colors.black.withValues(
                  alpha: (dark ? 0.35 : 0.18) * fade,
                ),
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: menu,
          child: Opacity(
            opacity: (opacity * (1 - expand)).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topLeft,
                child: IgnorePointer(
                  ignoring: _closing,
                  child: GlassMenuPanel(items: items, onItemTap: _onItemTap),
                ),
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: cardRect,
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, dy * (1 - expand)),
              child: Transform.scale(
                scale: ui.lerpDouble(scale, 1, expand)!,
                child: GestureDetector(
                  key: const ValueKey('chat-preview-card'),
                  onTap: () => unawaited(_open()),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: ColoredBox(
                      color: cs.surface,
                      child: _buildContent(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return AnimatedOpacity(
      opacity: _contentReady ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: _contentReady
          ? MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              child: ChatScreen(
                chatId: widget.chatId,
                name: widget.name,
                imageUrl: widget.imageUrl,
                chatType: widget.chatType,
                embedded: true,
                preview: true,
                onClose: () => unawaited(_dismiss()),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
