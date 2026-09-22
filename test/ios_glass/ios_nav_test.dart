import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/glass/glass_capsule.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/sliding_pill_nav.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _items = [
  PillNavItem(icon: Symbols.chat, label: 'Чаты'),
  PillNavItem(icon: Symbols.person, label: 'Контакты'),
  PillNavItem(icon: Symbols.call, label: 'Звонки'),
  PillNavItem(icon: Symbols.settings, label: 'Настройки'),
];

void main() {
  group('Ширина нижней панели iOS', () {
    test('на телефоне заметно уже прежней панели во всю ширину', () {
      const available = 390.0 - 20;
      final width = PillNavGeometry.iosInnerWidth(available, 4);
      expect(width, lessThan(available * 0.9));
      expect(width, greaterThanOrEqualTo(4 * 56.0));
    });

    test('на широком экране не растягивается', () {
      expect(PillNavGeometry.iosInnerWidth(1200, 4), 320);
    });

    test('на узком экране не вылезает за доступное место', () {
      expect(PillNavGeometry.iosInnerWidth(200, 4), 200);
    });
  });

  testWidgets('в iOS-режиме панель рисуется на стеклянной капсуле', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    addTearDown(AppIosGlass.debugReset);
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
    final taps = <int>[];
    final geometry = PillNavGeometry.fromInnerWidth(
      PillNavGeometry.iosInnerWidth(370, 4),
      4,
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => IosGlass(child: child!),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: geometry.navInnerW + 4,
              child: SlidingPillNav(
                items: _items,
                position: 0,
                geometry: geometry,
                onTap: taps.add,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('ios-tab-bar')), findsOneWidget);
    expect(find.byType(GlassCapsule), findsOneWidget);
    await tester.tap(find.byIcon(Symbols.call));
    expect(taps, [2]);
  });
}
