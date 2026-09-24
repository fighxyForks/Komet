import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/haptics.dart';
import '../animated_overlay_popup.dart';
import '../chat_menu_item.dart';
import 'glass_capsule.dart';
import 'ios_metrics.dart';
import 'ios_palette.dart';
import 'ios_typography.dart';
import 'ios_symbols.dart';
import 'ios_glass.dart';
import 'ios_tappable.dart';

class GlassMenuStyle {
  static const double width = 240;
  static const double margin = 12;
  static const double gap = 8;
  static const double radius = IosMetrics.menuRadius;
  static const double rowHeight = IosMetrics.minHitTarget;
  static const double fontSize = 17;
  static const double iconSize = 19;

  static Color tint(ColorScheme cs) => cs.brightness == Brightness.dark
      ? cs.surfaceContainerHigh.withValues(alpha: 0.62)
      : cs.surfaceContainerLowest.withValues(alpha: 0.66);

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
  @override
  Duration get overlayForwardDuration => const Duration(milliseconds: 380);

  @override
  Duration get overlayReverseDuration => const Duration(milliseconds: 200);

  @override
  Curve get overlayForwardCurve => Curves.easeOutBack;

  @override
  Curve get overlayReverseCurve => Curves.easeInCubic;

  @override
  VoidCallback get onOverlayDismiss => widget.onDismiss;

  void _onItemTap(ChatMenuItem item) {
    if (item.isSectionHeader || item.onTap == null) return;
    if (item.destructive) {
      Haptics.medium();
    } else {
      Haptics.tap();
    }
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
                    scale: 0.82 + 0.18 * t,
                    alignment: origin,
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: GlassMenuPanel(
        items: widget.items,
        header: widget.header,
        footer: widget.footer,
        onItemTap: _onItemTap,
      ),
    );
  }
}

class GlassMenuPanel extends StatelessWidget {
  final List<ChatMenuItem> items;
  final Widget? header;
  final Widget? footer;
  final ValueChanged<ChatMenuItem> onItemTap;

  const GlassMenuPanel({
    super.key,
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
    return GlassCapsule(
      key: const ValueKey('glass-menu'),
      borderRadius: BorderRadius.circular(GlassMenuStyle.radius),
      fallbackTint: GlassMenuStyle.tint(cs),
      fallbackSigma: 36,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(GlassMenuStyle.radius),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) ...[header!, hairline],
              for (var i = 0; i < items.length; i++) ...[
                GlassMenuRow(item: items[i], onTap: () => onItemTap(items[i])),
                if (items[i].dividerAfter && i != items.length - 1)
                  Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(vertical: 3),
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
    final ios = IosGlass.of(context);
    if (item.isSectionHeader) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ios ? IosPalette.secondaryLabel(cs) : cs.onSurfaceVariant,
            fontSize: ios ? IosTypography.footnote : 12,
            fontWeight: ios ? IosTypography.semibold : FontWeight.w600,
            letterSpacing: ios
                ? IosTypography.letterSpacing(IosTypography.footnote)
                : null,
          ),
        ),
      );
    }
    final fg = item.destructive
        ? (ios ? const Color(0xFFFF3B30) : cs.error)
        : (ios ? IosPalette.label(cs) : cs.onSurface);
    return IosTappable(
      onTap: item.enabled ? onTap : null,
      child: SizedBox(
        height: GlassMenuStyle.rowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: GlassMenuStyle.iconSize,
                  color: fg,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: GlassMenuStyle.fontSize,
                    fontWeight: ios ? IosTypography.regular : FontWeight.w400,
                    letterSpacing: ios
                        ? IosTypography.letterSpacing(GlassMenuStyle.fontSize)
                        : null,
                  ),
                ),
              ),
              if (item.showChevron)
                Icon(
                  IosSymbols.chevronRight(context),
                  size: 18,
                  color: (ios ? IosPalette.secondaryLabel(cs) : cs.onSurface)
                      .withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
