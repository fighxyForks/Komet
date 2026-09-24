import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/core/config/app_native_sheet_prototype.dart';
import 'package:komet/core/config/app_native_tab_minimize_prototype.dart';
import 'package:komet/core/config/ios_reduce_transparency.dart';
import 'package:komet/core/native/native_sheet_bridge.dart';
import 'package:komet/core/native/native_tab_chrome_bridge.dart';
import 'package:komet/core/native/tab_scroll_hysteresis.dart';
import 'package:komet/frontend/widgets/attachment/attachment_sheet.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _enableIos26Glass() async {
  AppIosGlass.debugStyleSupported = true;
  AppIosGlass.debugNativeGlassSupported = true;
  AppIosGlass.debugIosMajorVersion = 26;
  await AppIosGlass.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    AppNativeSheetPrototype.debugReset();
    AppNativeTabMinimizePrototype.debugReset();
    IosReduceTransparency.debugReset();
    NativeSheetBridge.debugReset();
    NativeTabChromeBridge.debugReset();
  });

  tearDown(() {
    AppIosGlass.debugReset();
    AppNativeSheetPrototype.debugReset();
    AppNativeTabMinimizePrototype.debugReset();
    IosReduceTransparency.debugReset();
    NativeSheetBridge.debugReset();
    NativeTabChromeBridge.debugReset();
  });

  group('flags', () {
    test('sheet prototype defaults off and persists', () async {
      expect(AppNativeSheetPrototype.enabled.value, isFalse);
      await AppNativeSheetPrototype.save(true);
      expect(AppNativeSheetPrototype.enabled.value, isTrue);
    });

    test('tab minimize prototype defaults off and persists', () async {
      expect(AppNativeTabMinimizePrototype.enabled.value, isFalse);
      await AppNativeTabMinimizePrototype.save(true);
      expect(AppNativeTabMinimizePrototype.enabled.value, isTrue);
    });
  });

  group('eligibility', () {
    test('sheet requires flag + style + nativeViews + no RT', () async {
      await _enableIos26Glass();
      NativeSheetBridge.debugAvailable = true;
      expect(NativeSheetBridge.isEligible, isFalse);
      await AppNativeSheetPrototype.save(true);
      expect(NativeSheetBridge.isEligible, isTrue);
      IosReduceTransparency.debugOverride = true;
      expect(NativeSheetBridge.isEligible, isFalse);
    });

    test('tab chrome requires flag + nativeViews', () async {
      await _enableIos26Glass();
      NativeTabChromeBridge.debugAvailable = true;
      await AppNativeTabMinimizePrototype.save(true);
      expect(NativeTabChromeBridge.isEligible, isTrue);
      AppIosGlass.debugNativeGlassSupported = false;
      expect(AppIosGlass.nativeViews, isFalse);
      expect(NativeTabChromeBridge.isEligible, isFalse);
    });
  });

  group('hysteresis', () {
    test('engages minimize after enough downward scroll', () {
      final h = TabScrollHysteresis(engagePixels: 24);
      expect(h.addDelta(10), TabScrollDirection.idle);
      expect(h.addDelta(10), TabScrollDirection.idle);
      expect(h.addDelta(10), TabScrollDirection.down);
    });

    test('engages expand after enough upward scroll', () {
      final h = TabScrollHysteresis(engagePixels: 24);
      h.addDelta(30);
      expect(h.direction, TabScrollDirection.down);
      expect(h.addDelta(-10), TabScrollDirection.down);
      expect(h.addDelta(-20), TabScrollDirection.up);
    });

    test('bridge forwards minimize/expand calls', () {
      NativeTabChromeBridge.debugAvailable = true;
      NativeTabChromeBridge.onScrollDelta(40);
      expect(
        NativeTabChromeBridge.debugCalls.any(
          (c) => c['method'] == 'setMinimized' && c['value'] == true,
        ),
        isTrue,
      );
      NativeTabChromeBridge.hysteresis.reset();
      NativeTabChromeBridge.onScrollDelta(-40);
      expect(
        NativeTabChromeBridge.debugCalls.any(
          (c) => c['method'] == 'setMinimized' && c['value'] == false,
        ),
        isTrue,
      );
    });
  });

  group('attachment fallback', () {
    test('present failure returns false so showAttachmentSheet can fall back',
        () async {
      await _enableIos26Glass();
      await AppNativeSheetPrototype.save(true);
      NativeSheetBridge.debugAvailable = true;
      var called = false;
      NativeSheetBridge.debugPresent = (_) async {
        called = true;
        return false;
      };
      expect(NativeSheetBridge.isEligible, isTrue);
      expect(await NativeSheetBridge.present(), isFalse);
      expect(called, isTrue);
    });

    testWidgets('uses native path when present succeeds', (tester) async {
      await _enableIos26Glass();
      await AppNativeSheetPrototype.save(true);
      NativeSheetBridge.debugAvailable = true;
      var presented = false;
      NativeSheetBridge.debugPresent = (_) async {
        presented = true;
        return true;
      };
      NativeSheetBridge.debugDismiss = () async {};

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => IosGlass(child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  showAttachmentSheet(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      expect(presented, isTrue);
      expect(find.byType(AttachmentSheet), findsNothing);
    });
  });
}
