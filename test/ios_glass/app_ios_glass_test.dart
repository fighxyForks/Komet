import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
  });

  tearDown(AppIosGlass.debugReset);

  group('Activation matrix', () {
    test('Android: style and native both false', () async {
      AppIosGlass.debugStyleSupported = false;
      AppIosGlass.debugNativeGlassSupported = false;
      await AppIosGlass.load();
      expect(AppIosGlass.styleSupported, isFalse);
      expect(AppIosGlass.nativeGlassSupported, isFalse);
      expect(AppIosGlass.active.value, isFalse);
      expect(AppIosGlass.nativeViews, isFalse);
    });

    test('iOS 15: style true, nativeViews false', () async {
      AppIosGlass.debugStyleSupported = true;
      AppIosGlass.debugIosMajorVersion = 15;
      AppIosGlass.debugNativeGlassSupported = false;
      await AppIosGlass.load();
      expect(AppIosGlass.styleSupported, isTrue);
      expect(AppIosGlass.nativeGlassSupported, isFalse);
      expect(AppIosGlass.active.value, isTrue);
      expect(AppIosGlass.nativeViews, isFalse);
    });

    test('iOS 17: style true, nativeViews false', () async {
      AppIosGlass.debugStyleSupported = true;
      AppIosGlass.debugIosMajorVersion = 17;
      AppIosGlass.debugNativeGlassSupported = false;
      await AppIosGlass.load();
      expect(AppIosGlass.styleSupported, isTrue);
      expect(AppIosGlass.nativeGlassSupported, isFalse);
      expect(AppIosGlass.active.value, isTrue);
      expect(AppIosGlass.nativeViews, isFalse);
    });

    test('iOS 25: style true, nativeViews false', () async {
      AppIosGlass.debugStyleSupported = true;
      AppIosGlass.debugIosMajorVersion = 25;
      AppIosGlass.debugNativeGlassSupported = false;
      await AppIosGlass.load();
      expect(AppIosGlass.styleSupported, isTrue);
      expect(AppIosGlass.nativeGlassSupported, isFalse);
      expect(AppIosGlass.active.value, isTrue);
      expect(AppIosGlass.nativeViews, isFalse);
    });

    test('iOS 26: style and nativeViews both true', () async {
      AppIosGlass.debugStyleSupported = true;
      AppIosGlass.debugIosMajorVersion = 26;
      AppIosGlass.debugNativeGlassSupported = true;
      await AppIosGlass.load();
      expect(AppIosGlass.styleSupported, isTrue);
      expect(AppIosGlass.nativeGlassSupported, isTrue);
      expect(AppIosGlass.active.value, isTrue);
      expect(AppIosGlass.nativeViews, isTrue);
    });

    test('toggle off: both active and nativeViews false', () async {
      AppIosGlass.debugStyleSupported = true;
      AppIosGlass.debugIosMajorVersion = 26;
      AppIosGlass.debugNativeGlassSupported = true;
      await AppIosGlass.load();
      await AppIosGlass.save(false);
      expect(AppIosGlass.styleSupported, isTrue);
      expect(AppIosGlass.nativeGlassSupported, isTrue);
      expect(AppIosGlass.active.value, isFalse);
      expect(AppIosGlass.nativeViews, isFalse);
    });
  });

  group('Toggle persistence', () {
    test('saved off is respected on load', () async {
      SharedPreferences.setMockInitialValues({AppIosGlass.prefKey: false});
      AppIosGlass.debugStyleSupported = true;
      AppIosGlass.debugIosMajorVersion = 26;
      AppIosGlass.debugNativeGlassSupported = true;
      await AppIosGlass.load();
      expect(AppIosGlass.enabled.value, isFalse);
      expect(AppIosGlass.active.value, isFalse);
      expect(AppIosGlass.nativeViews, isFalse);
    });

    test('save flips active and prefs', () async {
      AppIosGlass.debugStyleSupported = true;
      AppIosGlass.debugIosMajorVersion = 18;
      await AppIosGlass.load();
      await AppIosGlass.save(false);
      expect(AppIosGlass.active.value, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppIosGlass.prefKey), isFalse);
      await AppIosGlass.save(true);
      expect(AppIosGlass.active.value, isTrue);
    });
  });

  group('Legacy debugSetSupported', () {
    test('forces style on non-iOS host', () async {
      await AppIosGlass.load();
      expect(AppIosGlass.active.value, isFalse);
      AppIosGlass.debugSetSupported(true);
      expect(AppIosGlass.styleSupported, isTrue);
      expect(AppIosGlass.active.value, isTrue);
    });
  });
}
