import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../config/app_ios_glass.dart';
import '../config/ios_reduce_transparency.dart';
import '../../frontend/widgets/glass/ios_glass.dart';

class NativeSheetBridge {
  NativeSheetBridge._();

  static const method = MethodChannel('ru.komet.app/native_sheet');
  static const events = EventChannel('ru.komet.app/native_sheet_events');

  static bool? debugAvailable;
  static Future<bool> Function(Rect? source)? debugPresent;
  static Future<void> Function()? debugDismiss;

  static StreamSubscription<dynamic>? _sub;
  static Completer<Object?>? _result;

  static bool get isEligible {
    if (debugAvailable == false) return false;
    if (debugAvailable != true) {
      if (kIsWeb) return false;
      if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    }
    if (!AppIosGlass.active.value) return false;
    if (!AppIosGlass.nativeViews) return false;
    if (IosReduceTransparency.value) return false;
    return true;
  }

  static bool isEligibleWithContext(BuildContext context) {
    if (!IosGlass.of(context)) return false;
    return isEligible;
  }

  static Future<bool> present({Rect? sourceFrame}) async {
    final present = debugPresent;
    if (present != null) return present(sourceFrame);
    try {
      _listen();
      _result = Completer<Object?>();
      final ok = await method.invokeMethod<bool>('presentAttachmentSheet', {
        if (sourceFrame != null)
          'source': {
            'x': sourceFrame.left,
            'y': sourceFrame.top,
            'w': sourceFrame.width,
            'h': sourceFrame.height,
          },
      });
      return ok == true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<Object?> waitForResult() async {
    final c = _result;
    if (c == null) return null;
    return c.future.timeout(
      const Duration(minutes: 10),
      onTimeout: () => null,
    );
  }

  static Future<void> dismiss({Object? result}) async {
    final dismiss = debugDismiss;
    if (dismiss != null) {
      await dismiss();
      return;
    }
    try {
      await method.invokeMethod<void>('dismiss', {'result': result});
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static void _listen() {
    _sub ??= events.receiveBroadcastStream().listen((event) {
      if (event is Map && event['type'] == 'dismissed') {
        _result?.complete(event['result']);
        _result = null;
      }
    }, onError: (_) {});
  }

  @visibleForTesting
  static void debugReset() {
    debugAvailable = null;
    debugPresent = null;
    debugDismiss = null;
    _result = null;
    unawaited(_sub?.cancel());
    _sub = null;
  }
}
