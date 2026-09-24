import 'package:flutter/foundation.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import 'ios_low_power_mode.dart';
import 'ios_reduce_transparency.dart';
import 'persisted_setting.dart';

/// Two-tier iOS chrome:
///
/// * **Style tier** ([styleSupported] / [IosGlass.of]): Flutter iOS look
///   (typography, SF symbols, metrics, Cupertino sheets/alerts, opaque
///   surfaces). Available on every iOS version (deployment target 13+).
/// * **Native glass tier** ([nativeGlassSupported] / [nativeViews]):
///   `native_liquid_glass` UiKitViews. Only on iOS 26+, and never when
///   Reduce Transparency is on.
///
/// Material / Android / desktop never activate either tier.
class AppIosGlass {
  static const prefKey = 'app_ios_glass';
  static const bool defaultValue = true;

  /// Deployment-target floor for the style tier (documented only; any iOS
  /// device that runs the app is style-capable).
  static const int minIosStyleMajorVersion = 13;

  /// Native Liquid Glass requires iOS 26+.
  static const int minNativeGlassMajorVersion = 26;

  static final _setting = PersistedSetting<bool>(
    prefKey: prefKey,
    defaultValue: defaultValue,
    read: (prefs, key) => prefs.getBool(key),
    write: (prefs, key, value) async {
      await prefs.setBool(key, value);
    },
  );

  static bool _listening = false;

  static final ValueNotifier<bool> active = ValueNotifier<bool>(false);

  @visibleForTesting
  static bool? debugStyleSupported;

  @visibleForTesting
  static bool? debugNativeGlassSupported;

  @visibleForTesting
  static int? debugIosMajorVersion;

  static int? get iosMajorVersion =>
      debugIosMajorVersion ?? NativeLiquidGlassUtils.iosVersion;

  /// True on iOS (any major ≥ [minIosStyleMajorVersion] / deployment target).
  /// False on Android, desktop, and web.
  static bool get styleSupported {
    if (debugStyleSupported != null) return debugStyleSupported!;
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    final major = iosMajorVersion;
    if (major != null) return major >= minIosStyleMajorVersion;
    return true;
  }

  /// True only where `native_liquid_glass` can create UiKitViews (iOS 26+).
  static bool get nativeGlassSupported {
    if (debugNativeGlassSupported != null) return debugNativeGlassSupported!;
    final major = iosMajorVersion;
    if (major != null) return major >= minNativeGlassMajorVersion;
    return NativeLiquidGlassUtils.supportsLiquidGlass;
  }

  /// Alias for [styleSupported] — used by the appearance toggle visibility.
  static bool get supported => styleSupported;

  /// Native platform views may be created only when style is on, the OS
  /// supports Liquid Glass, and Reduce Transparency is off.
  static bool get nativeViews =>
      active.value && nativeGlassSupported && !IosReduceTransparency.value;

  static ValueNotifier<bool> get enabled => _setting.current;

  static Listenable get chromeListenable => Listenable.merge([
    active,
    IosReduceTransparency.enabled,
    IosLowPowerMode.enabled,
  ]);

  static Future<bool> load() async {
    _listen();
    await IosReduceTransparency.start();
    await IosLowPowerMode.start();
    await _setting.load();
    _sync();
    return active.value;
  }

  static Future<void> save(bool value) async {
    _listen();
    await _setting.save(value);
    _sync();
  }

  @visibleForTesting
  static void debugSetSupported(bool value) {
    _listen();
    debugStyleSupported = value;
    _sync();
  }

  @visibleForTesting
  static void debugReset() {
    debugStyleSupported = null;
    debugNativeGlassSupported = null;
    debugIosMajorVersion = null;
    IosReduceTransparency.debugOverride = null;
    IosReduceTransparency.enabled.value = false;
    IosLowPowerMode.debugOverride = null;
    IosLowPowerMode.enabled.value = false;
    _setting.current.value = defaultValue;
    _sync();
  }

  static void _listen() {
    if (_listening) return;
    _listening = true;
    _setting.current.addListener(_sync);
  }

  static void _sync() {
    active.value = styleSupported && _setting.current.value;
  }
}
