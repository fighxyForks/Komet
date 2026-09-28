import 'package:flutter/foundation.dart';

/// What the iOS build leaves out or does differently.
///
/// Runtime checks on [defaultTargetPlatform] so Android and desktop keep
/// their behavior and tests can switch platforms with
/// `debugDefaultTargetPlatformOverride`.
abstract final class IosRelease {
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
