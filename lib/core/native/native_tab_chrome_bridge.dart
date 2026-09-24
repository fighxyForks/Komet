import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../config/app_ios_glass.dart';
import '../config/app_native_tab_minimize_prototype.dart';
import '../config/ios_reduce_transparency.dart';
import '../../frontend/widgets/glass/ios_glass.dart';
import 'tab_scroll_hysteresis.dart';

class NativeTabChromeBridge {
  NativeTabChromeBridge._();

  static const method = MethodChannel('ru.komet.app/native_tab_chrome');
  static const viewType = 'ru.komet.app/native_tab_chrome_view';

  static bool? debugAvailable;
  static final List<Map<String, Object?>> debugCalls = [];

  static final TabScrollHysteresis hysteresis = TabScrollHysteresis();

  static bool get isEligible {
    if (debugAvailable == false) return false;
    if (debugAvailable != true) {
      if (kIsWeb) return false;
      if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    }
    if (!AppNativeTabMinimizePrototype.enabled.value) return false;
    if (!AppIosGlass.active.value) return false;
    if (!AppIosGlass.nativeViews) return false;
    if (IosReduceTransparency.value) return false;
    return true;
  }

  static bool isEligibleWithContext(BuildContext context) {
    if (!IosGlass.of(context)) return false;
    return isEligible;
  }

  static Future<void> setMinimized(bool minimized) async {
    debugCalls.add({'method': 'setMinimized', 'value': minimized});
    try {
      await method.invokeMethod<void>('setMinimized', {'value': minimized});
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static Future<void> setCallAccessory({
    required bool visible,
    String? title,
  }) async {
    debugCalls.add({
      'method': 'setCallAccessory',
      'visible': visible,
      'title': title,
    });
    try {
      await method.invokeMethod<void>('setCallAccessory', {
        'visible': visible,
        'title': title,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static Future<void> setSelectedIndex(int index) async {
    debugCalls.add({'method': 'setSelectedIndex', 'value': index});
    try {
      await method.invokeMethod<void>('setSelectedIndex', {'index': index});
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static TabScrollDirection onScrollDelta(double dy) {
    final dir = hysteresis.addDelta(dy);
    if (dir == TabScrollDirection.down) {
      unawaited(setMinimized(true));
    } else if (dir == TabScrollDirection.up) {
      unawaited(setMinimized(false));
    }
    return dir;
  }

  @visibleForTesting
  static void debugReset() {
    debugAvailable = null;
    debugCalls.clear();
    hysteresis.reset();
  }
}
