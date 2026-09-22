import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_native_glass.dart';
import 'package:komet/core/config/app_visual_style.dart';
import 'package:komet/frontend/widgets/native_glass.dart';

void main() {
  test('native glass stays off when visual style is not liquid glass', () {
    AppVisualStyle.current.value = VisualStyle.glossy;
    AppNativeGlass.current.value = true;
    expect(AppNativeGlass.enabled, isFalse);
  });

  test('native glass stays off when the user toggle is off', () {
    AppVisualStyle.current.value = VisualStyle.liquidGlass;
    AppNativeGlass.current.value = false;
    expect(AppNativeGlass.enabled, isFalse);
  });

  testWidgets('NativeGlassSurface keeps Flutter children above the fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NativeGlassSurface(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            fallback: SizedBox.expand(),
            child: Text('chrome'),
          ),
        ),
      ),
    );
    expect(find.text('chrome'), findsOneWidget);
  });
}
