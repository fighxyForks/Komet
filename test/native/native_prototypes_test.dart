import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/core/config/ios_reduce_transparency.dart';
import 'package:komet/core/native/native_sheet_bridge.dart';
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
    IosReduceTransparency.debugReset();
    NativeSheetBridge.debugReset();
  });

  tearDown(() {
    AppIosGlass.debugReset();
    IosReduceTransparency.debugReset();
    NativeSheetBridge.debugReset();
  });

  group('eligibility', () {
    test('sheet requires style + nativeViews + no RT', () async {
      await _enableIos26Glass();
      NativeSheetBridge.debugAvailable = true;
      expect(NativeSheetBridge.isEligible, isTrue);
      IosReduceTransparency.debugOverride = true;
      expect(NativeSheetBridge.isEligible, isFalse);
    });
  });

  group('attachment fallback', () {
    test('present failure returns false so showAttachmentSheet can fall back',
        () async {
      await _enableIos26Glass();
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
