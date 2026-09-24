import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/confirm_dialog.dart';
import 'package:komet/frontend/widgets/glass/ios_alert.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_route.dart';
import 'package:komet/frontend/widgets/glass/ios_sheet.dart';
import 'package:komet/frontend/widgets/glass/ios_tappable.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host({required Widget home, required bool ios}) {
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

  group('showIosAlert', () {
    testWidgets('в iOS-режиме открывает CupertinoAlertDialog', (tester) async {
      await _enableIos();
      await tester.pumpWidget(
        _host(
          ios: true,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showIosAlert<bool>(
                  context: context,
                  title: 'Удалить?',
                  message: 'Точно?',
                  actions: const [
                    IosAlertAction(
                      id: 'cancel',
                      label: 'Отмена',
                      result: false,
                      isCancel: true,
                    ),
                    IosAlertAction(
                      id: 'ok',
                      label: 'Удалить',
                      result: true,
                      isDestructive: true,
                    ),
                  ],
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog), findsNothing);
    });

    testWidgets('вне iOS-режима открывает Material AlertDialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ios: false,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showConfirmDialog(
                  context,
                  message: 'Точно?',
                  confirmLabel: 'OK',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(CupertinoAlertDialog), findsNothing);
    });
  });

  group('showIosSheet', () {
    testWidgets('в iOS-режиме подавляет glass и рисует шит', (tester) async {
      await _enableIos();
      await tester.pumpWidget(
        _host(
          ios: true,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showIosSheet<void>(
                  context: context,
                  builder: (_) => const SizedBox(
                    height: 120,
                    child: Center(child: Text('sheet-body')),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('sheet-body'), findsOneWidget);
      expect(GlassSuppression.count.value, greaterThan(0));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(GlassSuppression.count.value, 0);
    });
  });

  group('iosPageRoute', () {
    testWidgets('в iOS-режиме это CupertinoPageRoute', (tester) async {
      await _enableIos();
      late Route<void> route;
      await tester.pumpWidget(
        _host(
          ios: true,
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
      );
      expect(route, isA<CupertinoPageRoute<void>>());
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('pushed'), findsOneWidget);
    });

    testWidgets('вне iOS-режима это MaterialPageRoute', (tester) async {
      late Route<void> route;
      await tester.pumpWidget(
        _host(
          ios: false,
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
      );
      expect(route, isA<MaterialPageRoute<void>>());
    });
  });

  group('IosTappable', () {
    testWidgets('в iOS-режиме без InkWell', (tester) async {
      await _enableIos();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ios: true,
          home: Scaffold(
            body: IosTappable(
              onTap: () => taps++,
              child: const SizedBox(
                width: 80,
                height: 48,
                child: Center(child: Text('row')),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(InkWell), findsNothing);
      expect(
        tester.getSize(find.byType(IosTappable)).height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(find.text('row'));
      expect(taps, 1);
    });

    testWidgets('вне iOS-режима использует InkWell', (tester) async {
      await tester.pumpWidget(
        _host(
          ios: false,
          home: Scaffold(
            body: IosTappable(
              onTap: () {},
              child: const SizedBox(
                width: 80,
                height: 48,
                child: Center(child: Text('row')),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
