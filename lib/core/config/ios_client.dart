import 'dart:ffi' show Abi;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

abstract final class IosClient {
  static const String appVersion = '26.33.1';
  static const String deviceType = 'IOS';

  static bool get reportsRealDevice => !kIsWeb && Platform.isIOS;

  static String get architecture => switch (Abi.current()) {
    Abi.iosX64 => 'x86_64',
    _ => 'arm64',
  };

  static String deviceTitle({
    required String modelName,
    required String model,
    required String machine,
  }) {
    final known = modelName.trim();
    if (known.isNotEmpty && known != 'Unknown device') return known;
    final hardware = machine.trim();
    if (hardware.isNotEmpty) return hardware;
    final generic = model.trim();
    if (generic.isNotEmpty) return generic;
    return 'iPhone';
  }

  static String osLabel({
    required String systemName,
    required String systemVersion,
  }) {
    final name = systemName.trim();
    final version = systemVersion.trim();
    if (name.isEmpty) return version;
    if (version.isEmpty) return name;
    return '$name $version';
  }

  static String screenLabel({
    required double width,
    required double height,
    required double scale,
  }) {
    if (width <= 0 || height <= 0 || scale <= 0) return '';
    return '${width.round()}x${height.round()} ${scale.toStringAsFixed(1)}x';
  }

  static String currentScreen() {
    final views = PlatformDispatcher.instance.views;
    if (views.isEmpty) return '';
    final view = views.first;
    return screenLabel(
      width: view.physicalSize.width,
      height: view.physicalSize.height,
      scale: view.devicePixelRatio,
    );
  }
}
