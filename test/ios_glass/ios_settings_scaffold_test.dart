import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_palette.dart';
import 'package:komet/frontend/widgets/glass/ios_settings_scaffold.dart';
import 'package:komet/frontend/widgets/glass/ios_typography.dart';
import 'package:komet/frontend/widgets/glass/glass_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
  });

  tearDown(AppIosGlass.debugReset);

  testWidgets('в iOS-режиме рисует компактный заголовок и grouped фон', (
    tester,
  ) async {
    AppIosGlass.debugSetSupported(true);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => IosGlass(child: child!),
        home: IosSettingsScaffold(
          title: 'Устройства',
          useConnectionTitle: false,
          body: ListView(children: const [Text('body')]),
        ),
      ),
    );
    expect(find.byType(CupertinoSliverNavigationBar), findsNothing);
    expect(find.byType(NavigationToolbar), findsOneWidget);
    expect(find.text('Устройства'), findsOneWidget);
    final title = tester.widget<Text>(find.text('Устройства'));
    expect(title.style?.fontSize, IosTypography.headerTitle);
    expect(title.style?.fontWeight, IosTypography.semibold);
    expect(find.text('body'), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final cs = ThemeData(brightness: Brightness.light).colorScheme;
    expect(scaffold.backgroundColor, IosPalette.grouped(cs));
  });

  testWidgets('вне iOS-режима рисует Material AppBar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => IosGlass(child: child!),
        home: const IosSettingsScaffold(
          title: 'Устройства',
          useConnectionTitle: false,
          body: Center(child: Text('body')),
        ),
      ),
    );
    expect(find.byType(CupertinoNavigationBar), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('GlassSwitch в iOS остаётся CupertinoSwitch', (tester) async {
    AppIosGlass.debugSetSupported(true);
    var value = false;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => IosGlass(child: child!),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => GlassSwitch(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(CupertinoSwitch), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('IosSegmentedControl в iOS — CupertinoSlidingSegmentedControl', (
    tester,
  ) async {
    AppIosGlass.debugSetSupported(true);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => IosGlass(child: child!),
        home: Scaffold(
          body: IosSegmentedControl<int>(
            groupValue: 0,
            children: const {0: Text('A'), 1: Text('B')},
            onValueChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(CupertinoSlidingSegmentedControl<int>), findsOneWidget);
  });
}
