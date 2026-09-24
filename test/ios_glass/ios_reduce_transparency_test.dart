import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/core/config/ios_reduce_transparency.dart';
import 'package:komet/frontend/widgets/glass/glass_capsule.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/sliding_pill_nav.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget body) => MaterialApp(
  builder: (context, child) => IosGlass(child: child!),
  home: Scaffold(body: body),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    AppIosGlass.debugStyleSupported = true;
    AppIosGlass.debugIosMajorVersion = 26;
    AppIosGlass.debugNativeGlassSupported = true;
    await AppIosGlass.load();
  });

  tearDown(AppIosGlass.debugReset);

  test('Reduce Transparency clears nativeViews on iOS 26', () {
    expect(AppIosGlass.nativeViews, isTrue);
    IosReduceTransparency.debugOverride = true;
    expect(AppIosGlass.nativeViews, isFalse);
    IosReduceTransparency.debugOverride = false;
    expect(AppIosGlass.nativeViews, isTrue);
  });

  testWidgets('Reduce Transparency: GlassCapsule opaque, no UiKitView', (
    tester,
  ) async {
    IosReduceTransparency.debugOverride = true;
    await tester.pumpWidget(
      _host(
        const GlassCapsule(
          width: 120,
          height: 44,
          child: Text('chrome'),
        ),
      ),
    );
    expect(AppIosGlass.nativeViews, isFalse);
    expect(find.byType(LiquidGlassContainer), findsNothing);
    expect(find.byType(UiKitView), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(GlassBackground), findsOneWidget);
  });

  testWidgets('Reduce Motion: iOS 26 capsule stays opaque', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: IosGlass(child: child!),
        ),
        home: const Scaffold(
          body: GlassCapsule(width: 120, height: 44, child: Text('chrome')),
        ),
      ),
    );
    expect(AppIosGlass.nativeViews, isTrue);
    expect(find.byType(LiquidGlassContainer), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('style-tier SlidingPillNav has no BackdropFilter', (
    tester,
  ) async {
    AppIosGlass.debugIosMajorVersion = 17;
    AppIosGlass.debugNativeGlassSupported = false;
    IosReduceTransparency.debugOverride = false;
    await AppIosGlass.load();
    const items = [
      PillNavItem(icon: Symbols.forum, label: 'Чаты'),
      PillNavItem(icon: Symbols.call, label: 'Звонки'),
    ];
    await tester.pumpWidget(
      _host(
        SlidingPillNav(
          items: items,
          position: 0,
          geometry: PillNavGeometry.equal(80, 2),
          onTap: (_) {},
        ),
      ),
    );
    expect(find.byType(SlidingPillNav), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(UiKitView), findsNothing);
  });
}
