import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:komet/frontend/widgets/glass/ios_symbols.dart';

import '../connection_status.dart';
import 'ios_glass.dart';
import 'ios_metrics.dart';
import 'ios_palette.dart';
import 'ios_typography.dart';

/// Nested-settings chrome for iOS mode: grouped background + collapsing large
/// title with scroll-edge opacity. Off iOS mode keeps a Material [Scaffold] +
/// [AppBar] / [ConnectionTitleBar].
///
/// Native [LiquidGlassNavigationBar] is intentionally not used here: nested
/// settings need arbitrary Flutter trailing actions.
class IosSettingsScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? trailing;
  final bool automaticallyImplyLeading;
  final bool useConnectionTitle;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const IosSettingsScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.trailing,
    this.automaticallyImplyLeading = true,
    this.useConnectionTitle = true,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ios = IosGlass.of(context);
    final bg = backgroundColor ?? (ios ? IosPalette.grouped(cs) : cs.surface);

    if (!ios) {
      return Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        appBar: useConnectionTitle
            ? ConnectionTitleBar(titleText: title, backgroundColor: bg)
            : AppBar(
                backgroundColor: bg,
                elevation: 0,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: automaticallyImplyLeading,
                leading: leading,
                title: Text(title),
                centerTitle: true,
                actions: [...?actions, ?trailing],
              ),
        body: body,
      );
    }

    final middle = useConnectionTitle
        ? ConnectionStatusBuilder(
            builder: (context, label) => Text(
              label ?? title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: IosPalette.label(cs),
                fontSize: IosTypography.headerTitle,
                fontWeight: IosTypography.semibold,
                letterSpacing: IosTypography.letterSpacing(
                  IosTypography.headerTitle,
                ),
              ),
            ),
          )
        : Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: IosPalette.label(cs),
              fontSize: IosTypography.headerTitle,
              fontWeight: IosTypography.semibold,
              letterSpacing: IosTypography.letterSpacing(
                IosTypography.headerTitle,
              ),
            ),
          );

    Widget? barTrailing = trailing;
    if (barTrailing == null && actions != null && actions!.isNotEmpty) {
      barTrailing = Row(mainAxisSize: MainAxisSize.min, children: actions!);
    }

    final barLeading =
        leading ??
        (automaticallyImplyLeading && Navigator.of(context).canPop()
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(
                  IosMetrics.minHitTarget,
                  IosMetrics.minHitTarget,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
                child: Icon(
                  IosSymbols.chevronLeft(context),
                  size: 28,
                  weight: 400,
                  color: cs.primary,
                ),
              )
            : null);

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 52,
              child: NavigationToolbar(
                leading: barLeading == null
                    ? null
                    : _GlassBack(child: barLeading),
                middle: middle,
                trailing: barTrailing,
                centerMiddle: true,
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _GlassBack extends StatelessWidget {
  final Widget child;

  const _GlassBack({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: IosPalette.searchFill(Theme.of(context).colorScheme),
          shape: BoxShape.circle,
        ),
        child: SizedBox(
          width: IosMetrics.minHitTarget,
          height: IosMetrics.minHitTarget,
          child: child,
        ),
      ),
    );
  }
}

class _CollapsingIosSettings extends StatefulWidget {
  final Color background;
  final Color separator;
  final Widget largeTitle;
  final Widget? middle;
  final Widget? leading;
  final Widget? trailing;
  final Widget body;

  const _CollapsingIosSettings({
    required this.background,
    required this.separator,
    required this.largeTitle,
    required this.middle,
    required this.leading,
    required this.trailing,
    required this.body,
  });

  @override
  State<_CollapsingIosSettings> createState() => _CollapsingIosSettingsState();
}

class _CollapsingIosSettingsState extends State<_CollapsingIosSettings> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final scrolled = notification.metrics.pixels > 0.5;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bar = _scrolled
        ? widget.background.withValues(alpha: 0.94)
        : widget.background.withValues(alpha: 0);
    final hairline = _scrolled
        ? widget.separator.withValues(alpha: 0.45)
        : const Color(0x00000000);
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          final covered = _scrolled || innerBoxIsScrolled;
          final coveredBar = covered
              ? widget.background.withValues(alpha: 0.94)
              : bar;
          final coveredLine = covered
              ? widget.separator.withValues(alpha: 0.45)
              : hairline;
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: CupertinoSliverNavigationBar(
                largeTitle: widget.largeTitle,
                middle: widget.middle,
                alwaysShowMiddle: false,
                automaticBackgroundVisibility: false,
                enableBackgroundFilterBlur: false,
                backgroundColor: coveredBar,
                border: Border(
                  bottom: BorderSide(color: coveredLine, width: 0.5),
                ),
                automaticallyImplyLeading: false,
                leading: widget.leading,
                trailing: widget.trailing,
              ),
            ),
          ];
        },
        body: Builder(
          builder: (context) {
            final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(
              context,
            );
            return _OverlapPadding(handle: handle, child: widget.body);
          },
        ),
      ),
    );
  }
}

class _OverlapPadding extends StatefulWidget {
  final SliverOverlapAbsorberHandle handle;
  final Widget child;

  const _OverlapPadding({required this.handle, required this.child});

  @override
  State<_OverlapPadding> createState() => _OverlapPaddingState();
}

class _OverlapPaddingState extends State<_OverlapPadding> {
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    widget.handle.addListener(_onExtentChanged);
  }

  @override
  void didUpdateWidget(_OverlapPadding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handle == widget.handle) return;
    oldWidget.handle.removeListener(_onExtentChanged);
    widget.handle.addListener(_onExtentChanged);
  }

  @override
  void dispose() {
    widget.handle.removeListener(_onExtentChanged);
    super.dispose();
  }

  void _onExtentChanged() {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) setState(() {});
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: widget.handle.layoutExtent ?? 0),
      child: widget.child,
    );
  }
}

/// Primary / tonal / destructive button that looks Cupertino in iOS mode.
class IosSettingsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool destructive;
  final IconData? icon;
  final double? minHeight;

  const IosSettingsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.destructive = false,
    this.icon,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!IosGlass.of(context)) {
      if (!filled) {
        return TextButton(onPressed: onPressed, child: Text(label));
      }
      final style = destructive
          ? FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            )
          : null;
      ButtonStyle? sizeStyle = style;
      if (minHeight != null) {
        sizeStyle = (style ?? const ButtonStyle()).merge(
          FilledButton.styleFrom(minimumSize: Size.fromHeight(minHeight!)),
        );
      }
      if (icon != null) {
        return FilledButton.icon(
          onPressed: onPressed,
          style: sizeStyle,
          icon: Icon(IosSymbols.adapt(context, icon!), size: 20),
          label: Text(label),
        );
      }
      return FilledButton(
        onPressed: onPressed,
        style: sizeStyle,
        child: Text(label),
      );
    }

    final bg = !filled
        ? Colors.transparent
        : (destructive ? const Color(0xFFFF3B30) : cs.primary);
    final fg = !filled
        ? (destructive ? const Color(0xFFFF3B30) : cs.primary)
        : Colors.white;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        constraints: BoxConstraints(
          minHeight: minHeight ?? IosMetrics.minHitTarget,
        ),
        width: minHeight != null ? double.infinity : null,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(
            minHeight != null ? 14 : IosMetrics.controlRadius,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                IosSymbols.adapt(context, icon!),
                size: 18,
                color: fg,
                weight: 500,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: IosTypography.body,
                fontWeight: IosTypography.semibold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact top bar used inside CustomScrollView bodies (security, blacklist).
class IosSettingsInlineBar extends StatelessWidget {
  final String title;
  final List<Widget>? trailing;
  final VoidCallback? onBack;

  const IosSettingsInlineBar({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ios = IosGlass.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              ios ? IosSymbols.chevronLeft(context) : IosSymbols.back(context),
              color: ios ? cs.primary : cs.onSurface,
              size: ios ? 28 : 24,
              weight: 400,
            ),
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ConnectionTitleText(
              title,
              style: TextStyle(
                color: ios ? IosPalette.label(cs) : cs.onSurface,
                fontSize: ios ? IosTypography.headerTitle : 20,
                fontWeight: ios ? IosTypography.semibold : FontWeight.w700,
              ),
            ),
          ),
          ...?trailing,
        ],
      ),
    );
  }
}

Color iosSettingsBackground(BuildContext context, {Color? material}) {
  final cs = Theme.of(context).colorScheme;
  if (IosGlass.of(context)) return IosPalette.grouped(cs);
  return material ?? cs.surface;
}
