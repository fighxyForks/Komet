import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/chat_menu_item.dart';
import 'package:komet/frontend/widgets/glass/glass_menu.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_metrics.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
  });

  tearDown(AppIosGlass.debugReset);

  test('GlassMenuStyle rows meet the 44pt hit target', () {
    expect(GlassMenuStyle.rowHeight, IosMetrics.minHitTarget);
    expect(GlassMenuStyle.radius, IosMetrics.menuRadius);
    expect(GlassMenuStyle.fontSize, 17);
  });

  testWidgets('showGlassMenu presents and dismisses', (tester) async {
    AppIosGlass.debugSetSupported(true);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => IosGlass(child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showGlassMenu(
                  context: context,
                  anchorRect: const Rect.fromLTWH(80, 120, 40, 40),
                  items: [
                    ChatMenuItem(
                      icon: Icons.copy,
                      label: 'Копировать',
                      onTap: () {},
                    ),
                    ChatMenuItem(
                      icon: Icons.delete,
                      label: 'Удалить',
                      destructive: true,
                      onTap: () {},
                    ),
                  ],
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Копировать'), findsOneWidget);
    expect(find.text('Удалить'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('glass-menu-barrier')));
    await tester.pumpAndSettle();
    expect(find.text('Копировать'), findsNothing);
  });
}
