import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart' show appFlavor;

// #***! что включено в сборке, всё считается на компиляции из flavor
abstract final class BuildProfile {
  static const String storeFlavor = 'store';

  // #***! store сборка урезана, без самообновления дев инструментов и спуфа
  static const bool isStore = appFlavor == storeFlavor;

  // #***! отдельная пометка IPA для App Store, не flavor store
  static const bool isAppStoreBuild = bool.fromEnvironment(
    'KOMET_APPSTORE',
    defaultValue: false,
  );

  static const bool _publicRelease = isStore || isAppStoreBuild;

  // #***! iOS-сборка дописывает KOMET_SELF_UPDATE=false, проверки там нет
  static const bool selfUpdate =
      !_publicRelease &&
      bool.fromEnvironment('KOMET_SELF_UPDATE', defaultValue: true);
  static const bool firebasePush = appFlavor == 'oneme';
  // #***! на iOS экран подмены скрыт, хендшейк при этом как у остальных
  static bool get spoofUi =>
      !_publicRelease &&
      (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS);
  static const bool tokenLogin = false;
  static const bool qrLogin = false;
  static const bool devTools = !_publicRelease;
  static const bool insecureTransport = !_publicRelease;
  static const bool trafficCapture = !_publicRelease;
  static const bool pranks = !_publicRelease;
  static const bool hiddenContentViewers = !_publicRelease;
  static const bool digitalId = !_publicRelease;
  static const bool ipGeoLookup = !_publicRelease;
  static const bool sessionCityLookup = !_publicRelease;
}
