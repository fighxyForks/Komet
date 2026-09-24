import 'package:flutter/material.dart';

import '../../../core/config/app_frost.dart';
import '../sheet_helpers.dart';
import 'ios_glass.dart';
import 'ios_metrics.dart';
import 'ios_palette.dart';

/// Preferred size hints for [showIosSheet] in iOS mode.
enum IosSheetDetent {
  /// Hug content (Material-style bottom sheet).
  fit,

  /// Roughly half-screen (iOS medium detent).
  medium,

  /// Near full-screen (iOS large detent).
  large,
}

/// Adaptive modal sheet: iOS 26-styled chrome in iOS mode, Material otherwise.
///
/// [LiquidGlassSheet] from `native_liquid_glass` cannot host arbitrary Flutter
/// content (its builder is unused on the native path), so this uses a Flutter
/// implementation with [IosPalette] / [IosMetrics], an optional grabber, and
/// [GlassSuppression] while the sheet is open.
Future<T?> showIosSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
  Color? barrierColor,
  ShapeBorder? shape,
  bool enableDrag = true,
  bool isDismissible = true,
  bool useSafeArea = false,
  bool? requestFocus,
  bool useRootNavigator = false,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  double? elevation,
  AnimationController? transitionAnimationController,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  bool? showDragHandle,
  bool showGrabber = false,
  IosSheetDetent? detent,
}) {
  final ios = IosGlass.of(context);

  if (!ios) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      barrierColor: barrierColor,
      shape: shape,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      useSafeArea: useSafeArea,
      requestFocus: requestFocus ?? true,
      useRootNavigator: useRootNavigator,
      clipBehavior: clipBehavior,
      constraints: constraints,
      elevation: elevation,
      transitionAnimationController: transitionAnimationController,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
      showDragHandle: showDragHandle,
    );
  }

  final cs = Theme.of(context).colorScheme;
  final effectiveDetent =
      detent ??
      (isScrollControlled ? IosSheetDetent.large : IosSheetDetent.fit);
  final iosShape =
      shape ??
      RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(IosMetrics.sheetRadius),
        ),
      );
  final iosBg = backgroundColor ?? IosPalette.grouped(cs);
  final iosBarrier = barrierColor ?? AppFrost.scrim();

  return GlassSuppression.during(
    () => showModalBottomSheet<T>(
      context: context,
      isScrollControlled:
          isScrollControlled || effectiveDetent != IosSheetDetent.fit,
      backgroundColor: iosBg,
      barrierColor: iosBarrier,
      shape: iosShape,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      useSafeArea: useSafeArea,
      requestFocus: requestFocus ?? true,
      useRootNavigator: useRootNavigator,
      clipBehavior: clipBehavior ?? Clip.antiAlias,
      constraints: constraints ?? _detentConstraints(context, effectiveDetent),
      elevation: elevation ?? 0,
      transitionAnimationController: transitionAnimationController,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
      showDragHandle: showDragHandle,
      builder: (sheetContext) {
        final child = builder(sheetContext);
        if (!showGrabber) return child;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [const SheetGrabber(), child],
        );
      },
    ),
  );
}

BoxConstraints? _detentConstraints(
  BuildContext context,
  IosSheetDetent detent,
) {
  final height = MediaQuery.sizeOf(context).height;
  return switch (detent) {
    IosSheetDetent.fit => null,
    IosSheetDetent.medium => BoxConstraints(maxHeight: height * 0.55),
    IosSheetDetent.large => BoxConstraints(maxHeight: height * 0.94),
  };
}

/// Sheet top shape using [IosMetrics.sheetRadius] in iOS mode, else [kSheetShape].
ShapeBorder iosSheetShape(BuildContext context) {
  if (!IosGlass.of(context)) return kSheetShape;
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(IosMetrics.sheetRadius),
    ),
  );
}

/// Sheet background using [IosPalette.grouped] in iOS mode.
Color iosSheetBackground(BuildContext context, {Color? material}) {
  final cs = Theme.of(context).colorScheme;
  if (IosGlass.of(context)) return IosPalette.grouped(cs);
  return material ?? cs.surfaceContainerHigh;
}
