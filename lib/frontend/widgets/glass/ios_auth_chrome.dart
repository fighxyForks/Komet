
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ios_glass.dart';
import 'ios_metrics.dart';
import 'ios_palette.dart';
import 'ios_symbols.dart';
import 'ios_typography.dart';
import 'ios_settings_scaffold.dart';

/// Auth/onboarding primary CTA height (iOS HIG-ish filled button).
const double kIosAuthPrimaryHeight = 50;

Color iosAuthBackground(BuildContext context, {Color? material}) {
  final cs = Theme.of(context).colorScheme;
  if (IosGlass.of(context)) return IosPalette.grouped(cs);
  return material ?? cs.surface;
}

/// Nested auth screen chrome: Cupertino nav in iOS mode, Material AppBar else.
class IosAuthScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBack;

  const IosAuthScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.automaticallyImplyLeading = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ios = IosGlass.of(context);
    final bg = iosAuthBackground(context);

    if (!ios) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: title == null ? null : Text(title!),
          centerTitle: true,
          automaticallyImplyLeading: automaticallyImplyLeading,
          actions: actions,
        ),
        floatingActionButton: floatingActionButton,
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: floatingActionButton,
      appBar: CupertinoNavigationBar(
        backgroundColor: bg.withValues(alpha: 0.94),
        border: null,
        middle: title == null
            ? null
            : Text(
                title!,
                style: TextStyle(
                  color: IosPalette.label(cs),
                  fontSize: IosTypography.headerTitle,
                  fontWeight: IosTypography.semibold,
                ),
              ),
        leading: automaticallyImplyLeading
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                child: Icon(
                  IosSymbols.chevronBack(context),
                  color: cs.primary,
                  size: 22,
                ),
              )
            : null,
        trailing: actions == null || actions!.isEmpty
            ? null
            : Row(mainAxisSize: MainAxisSize.min, children: actions!),
      ),
      body: body,
    );
  }
}

/// Rounded filled auth field decoration (17pt in iOS mode).
InputDecoration iosAuthFieldDecoration(
  BuildContext context, {
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? labelText,
}) {
  final cs = Theme.of(context).colorScheme;
  final ios = IosGlass.of(context);
  if (!ios) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }
  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: IosPalette.searchFill(cs),
    hintStyle: TextStyle(
      color: IosPalette.secondaryLabel(cs),
      fontSize: IosTypography.body,
    ),
    labelStyle: TextStyle(
      color: IosPalette.secondaryLabel(cs),
      fontSize: IosTypography.callout,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.35)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

TextStyle iosAuthFieldStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final ios = IosGlass.of(context);
  return TextStyle(
    color: ios ? IosPalette.label(cs) : cs.onSurface,
    fontSize: ios ? IosTypography.body : 15,
    fontWeight: FontWeight.w400,
    letterSpacing: ios ? IosTypography.letterSpacing(IosTypography.body) : null,
  );
}

Widget iosAuthPrimaryButton({
  required BuildContext context,
  required String label,
  required VoidCallback? onPressed,
  IconData? icon,
}) {
  return IosSettingsButton(
    label: label,
    onPressed: onPressed,
    icon: icon,
    minHeight: kIosAuthPrimaryHeight,
  );
}

/// Flutter translucent glass circle for dark viewer chrome (no platform view).
class IosViewerGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  const IosViewerGlassButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = IosMetrics.minHitTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 0.6,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
