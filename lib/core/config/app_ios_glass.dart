import 'package:flutter/foundation.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import 'persisted_setting.dart';

class AppIosGlass {
  static const prefKey = 'app_ios_glass';
  static const bool defaultValue = true;

  static final _setting = PersistedSetting<bool>(
    prefKey: prefKey,
    defaultValue: defaultValue,
    read: (prefs, key) => prefs.getBool(key),
    write: (prefs, key, value) async {
      await prefs.setBool(key, value);
    },
  );

  static bool _supported = false;
  static bool _listening = false;

  static final ValueNotifier<bool> active = ValueNotifier<bool>(false);

  static bool get supported => _supported;

  static bool get nativeViews =>
      active.value && NativeLiquidGlassUtils.supportsLiquidGlass;

  static ValueNotifier<bool> get enabled => _setting.current;

  static Future<bool> load() async {
    _listen();
    _supported = NativeLiquidGlassUtils.supportsLiquidGlass;
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
    _supported = value;
    _sync();
  }

  @visibleForTesting
  static void debugReset() {
    _supported = false;
    _setting.current.value = defaultValue;
    _sync();
  }

  static void _listen() {
    if (_listening) return;
    _listening = true;
    _setting.current.addListener(_sync);
  }

  static void _sync() {
    active.value = _supported && _setting.current.value;
  }
}
