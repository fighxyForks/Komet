import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/motion/ios_motion.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host({required Widget home}) {
  return MaterialApp(
    builder: (context, child) => IosGlass(child: child!),
    home: home,
  );
}

Future<void> _enableIos() async {
  SharedPreferences.setMockInitialValues({});
  AppIosGlass.debugReset();
  await AppIosGlass.load();
  AppIosGlass.debugSetSupported(true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
  });

  tearDown(AppIosGlass.debugReset);

  testWidgets('iOS reduce motion: short cross-fade route, no slide duration', (
    tester,
  ) async {
    await _enableIos();
    late Route<void> route;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _host(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                route = iosPageRoute<void>(
                  context,
                  builder: (_) => const Scaffold(body: Text('pushed')),
                );
                return TextButton(
                  onPressed: () => Navigator.of(context).push(route),
                  child: const Text('go'),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(route, isA<IosCupertinoPageRoute<void>>());
    final iosRoute = route as IosCupertinoPageRoute<void>;
    expect(iosRoute.reduceMotion, isTrue);
    expect(iosRoute.transitionDuration, IosMotion.pageCrossFade);
    expect(iosRoute.reverseTransitionDuration, IosMotion.pageCrossFade);

    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.byType(FadeTransition), findsWidgets);
    await tester.pump(IosMotion.pageCrossFade);
    await tester.pumpAndSettle();
    expect(find.text('pushed'), findsOneWidget);
  });

  testWidgets('iOS reduce motion off: standard Cupertino duration', (
    tester,
  ) async {
    await _enableIos();
    late Route<void> route;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: false),
        child: _host(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                route = iosPageRoute<void>(
                  context,
                  builder: (_) => const Scaffold(body: Text('pushed')),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    expect(route, isA<IosCupertinoPageRoute<void>>());
    final iosRoute = route as IosCupertinoPageRoute<void>;
    expect(iosRoute.reduceMotion, isFalse);
    expect(
      iosRoute.transitionDuration,
      CupertinoRouteTransitionMixin.kTransitionDuration,
    );
  });

  testWidgets('Material mode ignores reduce motion for route type', (
    tester,
  ) async {
    late Route<void> route;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _host(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                route = iosPageRoute<void>(
                  context,
                  builder: (_) => const Scaffold(body: Text('pushed')),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    expect(route, isA<MaterialPageRoute<void>>());
    expect(route, isNot(isA<IosCupertinoPageRoute<void>>()));
  });
}
