import '../../core/utils/haptics.dart';

/// Semantic haptic map for iOS-mode interactive UI.
///
/// Prefer these named events under [IosGlass] over ad-hoc [Haptics] calls so
/// selection, thresholds, menus, and toggles stay consistent. Material /
/// Android paths keep using [Haptics] directly and must not change.
abstract final class IosHaptics {
  static void selectionChange() => Haptics.selection();

  static void swipeToReplyThreshold() => Haptics.heavy();

  static void dismissThreshold() => Haptics.medium();

  static void menuOpen() => Haptics.medium();

  static void longPress() => Haptics.medium();

  static void success() => Haptics.success();

  static void error() => Haptics.error();

  static void toggle() => Haptics.selection();

  static void itemActivate() => Haptics.tap();

  static void destructiveActivate() => Haptics.medium();
}
