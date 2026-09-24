import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/glass/glass_capsule.dart';
import 'package:komet/frontend/widgets/glass/ios_alert.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_native_tab_bar.dart';
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
    AppIosGlass.debugIosMajorVersion = 17;
    AppIosGlass.debugNativeGlassSupported = false;
    await AppIosGlass.load();
  });

  tearDown(AppIosGlass.debugReset);

  testWidgets('iOS 17 style: GlassCapsule has no UiKitView / LiquidGlassContainer', (
    tester,
  ) async {
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
    expect(find.text('chrome'), findsOneWidget);
    expect(find.byType(GlassBackground), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('iOS 17 style: showIosAlert uses Flutter path (no native alert)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () {
              showIosAlert(
                context: context,
                title: 'Заголовок',
                message: 'Текст',
                actions: const [
                  IosAlertAction(id: 'ok', label: 'OK'),
                ],
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Заголовок'), findsOneWidget);
    expect(find.byType(UiKitView), findsNothing);
  });

  testWidgets('iOS 17 style: Flutter pill nav used instead of IosNativeTabBar', (
    tester,
  ) async {
    const items = [
      PillNavItem(icon: Symbols.forum, label: 'Чаты'),
      PillNavItem(icon: Symbols.call, label: 'Звонки'),
    ];
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            final ios = IosGlass.of(context);
            final native = AppIosGlass.nativeViews;
            if (ios && native) {
              return IosNativeTabBar(
                items: items,
                currentIndex: 0,
                onTap: (_) {},
              );
            }
            return SlidingPillNav(
              items: items,
              position: 0,
              geometry: PillNavGeometry.equal(80, 2),
              onTap: (_) {},
            );
          },
        ),
      ),
    );
    expect(find.byType(IosNativeTabBar), findsNothing);
    expect(find.byType(LiquidGlassTabBar), findsNothing);
    expect(find.byType(SlidingPillNav), findsOneWidget);
    expect(find.byType(UiKitView), findsNothing);
  });
}
