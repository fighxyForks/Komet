import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IosLowPowerMode {
  IosLowPowerMode._();

  static const _method = MethodChannel('ru.komet.app/power');
  static const _events = EventChannel('ru.komet.app/power_events');

  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  static bool? debugOverride;

  static bool _started = false;

  static bool get value => debugOverride ?? enabled.value;

  static Future<void> start() async {
    if (_started) return;
    _started = true;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final current = await _method.invokeMethod<bool>('isLowPowerModeEnabled');
      enabled.value = current ?? false;
    } on MissingPluginException {
      enabled.value = false;
    } on PlatformException {
      enabled.value = false;
    }
    try {
      _events.receiveBroadcastStream().listen((event) {
        enabled.value = event == true;
      }, onError: (_) {});
    } on MissingPluginException {
      enabled.value = false;
    } on PlatformException {
      enabled.value = false;
    }
  }

  static void debugReset() {
    debugOverride = null;
    enabled.value = false;
  }
}
