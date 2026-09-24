import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ios_glass.dart';

/// Adaptive page route: [CupertinoPageRoute] in iOS mode, [MaterialPageRoute]
/// otherwise.
Route<T> iosPageRoute<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool fullscreenDialog = false,
  bool maintainState = true,
  bool allowSnapshotting = true,
}) {
  if (IosGlass.of(context)) {
    return CupertinoPageRoute<T>(
      builder: builder,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
      allowSnapshotting: allowSnapshotting,
    );
  }
  return MaterialPageRoute<T>(
    builder: builder,
    settings: settings,
    fullscreenDialog: fullscreenDialog,
    maintainState: maintainState,
    allowSnapshotting: allowSnapshotting,
  );
}

/// Push with [iosPageRoute].
Future<T?> iosPush<T extends Object?>(
  BuildContext context,
  WidgetBuilder builder, {
  RouteSettings? settings,
  bool fullscreenDialog = false,
  bool maintainState = true,
  bool rootNavigator = false,
}) {
  return Navigator.of(context, rootNavigator: rootNavigator).push<T>(
    iosPageRoute<T>(
      context,
      builder: builder,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
    ),
  );
}
