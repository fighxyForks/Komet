import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/haptics.dart';
import '../animated_overlay_popup.dart';
import '../chat_menu_item.dart';
import 'glass_capsule.dart';
import 'ios_glass.dart';

class GlassMenuStyle {
  static const double width = 250;
  static const double margin = 12;
  static const double gap = 8;
  static const double radius = 26;
  static const double rowHeight = 46;

  static Color tint(ColorScheme cs) => cs.brightness == Brightness.dark
      ? cs.surfaceContainerHigh.withValues(alpha: 0.82)
      : cs.surfaceContainerLowest.withValues(alpha: 0.86);

  static Color separator(ColorScheme cs) =>
      cs.onSurface.withValues(alpha: 0.08);
}

void showGlassMenu({
  required BuildContext context,
  required Rect anchorRect,
  required List<ChatMenuItem> items,
  Widget? header,
  Widget? footer,
  double width = GlassMenuStyle.width,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => GlassMenuLayer(
      anchorRect: anchorRect,
      items: items,
      header: header,
      footer: footer,
      width: width,
      onDismiss: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
  Haptics.medium();
}

class GlassMenuPlacement {
  final Offset offset;
  final Alignment origin;

  const GlassMenuPlacement(this.offset, this.origin);

  static Alignment originFor({required Size screen, required Rect anchor}) =>
      Alignment(
        anchor.center.dx > screen.width / 2 ? 1 : -1,
        anchor.center.dy < screen.height * 0.55 ? -1 : 1,
      );

  static GlassMenuPlacement resolve({
    required Size screen,
    required Size menu,
    required Rect anchor,
    required EdgeInsets safeArea,
  }) {
    const margin = GlassMenuStyle.margin;
    const gap = GlassMenuStyle.gap;
    final origin = originFor(screen: screen, anchor: anchor);
    final maxLeft = math.max(margin, screen.width - menu.width - margin);
    final left = (origin.x > 0 ? anchor.right - menu.width : anchor.left)
        .clamp(margin, maxLeft)
        .toDouble();
    final topLimit = safeArea.top + margin;
    final bottomLimit = screen.height - safeArea.bottom - margin;
    final below = anchor.bottom + gap;
    final above = anchor.top - gap - menu.height;
    final fitsBelow = below + menu.height <= bottomLimit;
    final fitsAbove = above >= topLimit;
    final double top;
    if (origin.y < 0) {
      top = fitsBelow
          ? below
          : (fitsAbove ? above : math.max(topLimit, bottomLimit - menu.height));
    } else {
      top = fitsAbove
          ? above
          : (fitsBelow ? below : math.max(topLimit, bottomLimit - menu.height));
    }
    return GlassMenuPlacement(Offset(left, top), origin);
  }
}

class _GlassMenuLayout extends SingleChildLayoutDelegate {
  final Rect anchor;
  final EdgeInsets safeArea;
  final double width;

  const _GlassMenuLayout({
    required this.anchor,
    required this.safeArea,
    required this.width,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final w = math.max(
      0.0,
      math.min(width, constraints.maxWidth - GlassMenuStyle.margin * 2),
    );
    final available =
        constraints.maxHeight - safeArea.vertical - GlassMenuStyle.margin * 2;
    return BoxConstraints(
      minWidth: w,
      maxWidth: w,
      maxHeight: math.max(120.0, available),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      GlassMenuPlacement.resolve(
        screen: size,
        menu: childSize,
        anchor: anchor,
        safeArea: safeArea,
      ).offset;

  @override
  bool shouldRelayout(_GlassMenuLayout oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.safeArea != safeArea ||
      oldDelegate.width != width;
}

class GlassMenuLayer extends StatefulWidget {
  final Rect anchorRect;
  final List<ChatMenuItem> items;
  final Widget? header;
  final Widget? footer;
  final double width;
  final VoidCallback onDismiss;

  const GlassMenuLayer({
    super.key,
    required this.anchorRect,
    required this.items,
    required this.onDismiss,
    this.header,
    this.footer,
    this.width = GlassMenuStyle.width,
  });

  @override
  State<GlassMenuLayer> createState() => _GlassMenuLayerState();
}

class _GlassMenuLayerState extends State<GlassMenuLayer>
    with SingleTickerProviderStateMixin, AnimatedOverlayPopup<GlassMenuLayer> {
  late final VoidCallback _releaseGlass;

  @override
  Duration get overlayForwardDuration => const Duration(milliseconds: 320);

  @override
  Duration get overlayReverseDuration => const Duration(milliseconds: 180);

  @override
  VoidCallback get onOverlayDismiss => widget.onDismiss;

  @override
  void initState() {
    super.initState();
    _releaseGlass = GlassSuppression.hold();
  }

  @override
  void dispose() {
    _releaseGlass();
    super.dispose();
  }

  void _onItemTap(ChatMenuItem item) {
    Haptics.tap();
    closeOverlay().then((_) => item.onTap?.call());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final safeArea = MediaQuery.paddingOf(context);
    final origin = GlassMenuPlacement.originFor(
      screen: MediaQuery.sizeOf(context),
      anchor: widget.anchorRect,
    );
    return AnimatedBuilder(
      animation: overlayAnimation,
      builder: (context, child) {
        final t = overlayAnimation.value.clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey('glass-menu-barrier'),
                onTap: closeOverlay,
                behavior: HitTestBehavior.opaque,
                child: ColoredBox(
                  color: GlassStyle.scrim(
                    cs,
                  ).withValues(alpha: GlassStyle.scrim(cs).a * t),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomSingleChildLayout(
                delegate: _GlassMenuLayout(
                  anchor: widget.anchorRect,
                  safeArea: safeArea,
                  width: widget.width,
                ),
                child: Opacity(
                  opacity: t,
                  child: Transform.scale(
                    scale: 0.3 + 0.7 * t,
                    alignment: origin,
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: _GlassMenuPanel(
        items: widget.items,
        header: widget.header,
        footer: widget.footer,
        onItemTap: _onItemTap,
      ),
    );
  }
}

class _GlassMenuPanel extends StatelessWidget {
  final List<ChatMenuItem> items;
  final Widget? header;
  final Widget? footer;
  final ValueChanged<ChatMenuItem> onItemTap;

  const _GlassMenuPanel({
    required this.items,
    required this.onItemTap,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hairline = Divider(
      height: 1,
      thickness: 0.5,
      color: GlassMenuStyle.separator(cs),
    );
    return GlassBackground(
      key: const ValueKey('glass-menu'),
      borderRadius: BorderRadius.circular(GlassMenuStyle.radius),
      tint: GlassMenuStyle.tint(cs),
      sigma: 30,
      child: Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) ...[header!, hairline],
              for (var i = 0; i < items.length; i++) ...[
                GlassMenuRow(item: items[i], onTap: () => onItemTap(items[i])),
                if (items[i].dividerAfter && i != items.length - 1)
                  Container(
                    height: 8,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: GlassMenuStyle.separator(cs),
                  ),
              ],
              if (footer != null) ...[hairline, footer!],
            ],
          ),
        ),
      ),
    );
  }
}

class GlassMenuRow extends StatelessWidget {
  final ChatMenuItem item;
  final VoidCallback onTap;

  const GlassMenuRow({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = item.destructive ? cs.error : cs.onSurface;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GlassMenuStyle.rowHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              Icon(item.icon, size: 21, weight: 450, color: fg),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (item.showChevron)
                Icon(
                  Symbols.chevron_right,
                  size: 20,
                  weight: 450,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
