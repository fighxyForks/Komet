import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
/// settings need arbitrary Flutter trailing actions, and one platform view per
/// settings push would burn the glass budget next to the tab bar.
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

    final barLeading = leading ??
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CupertinoSliverNavigationBar(
              largeTitle: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: IosPalette.label(cs),
                  fontSize: IosTypography.largeTitle,
                  fontWeight: IosType.largeTitle,
                  letterSpacing: IosTypography.letterSpacing(
                    IosTypography.largeTitle,
                  ),
                ),
              ),
              middle: middle,
              alwaysShowMiddle: false,
              backgroundColor: innerBoxIsScrolled
                  ? bg.withValues(alpha: 0.94)
                  : bg.withValues(alpha: 0),
              border: Border(
                bottom: BorderSide(
                  color: innerBoxIsScrolled
                      ? IosPalette.separator(cs).withValues(alpha: 0.45)
                      : Colors.transparent,
                  width: 0.5,
                ),
              ),
              automaticallyImplyLeading: false,
              leading: barLeading,
              trailing: barTrailing,
            ),
          ];
        },
        body: body,
      ),
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
              Icon(IosSymbols.adapt(context, icon!), size: 18, color: fg, weight: 500),
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
