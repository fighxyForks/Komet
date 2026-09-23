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
    test('на телефоне отступает от краёв экрана на 21 pt', () {
      const page = 390.0;
      final inner = PillNavGeometry.iosInnerWidth(page, 4);
      final bar = inner + SlidingPillNav.iosPadding * 2;
      expect((page - bar) / 2, PillNavGeometry.iosMargin);
    });

    test('на широком экране не растягивается', () {
      expect(
        PillNavGeometry.iosInnerWidth(1200, 4),
        4 * PillNavGeometry.iosMaxItemWidth,
      );
    });

    test('на узком экране не уходит в минус', () {
      expect(PillNavGeometry.iosInnerWidth(40, 4), 0);
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
    final inner = PillNavGeometry.iosInnerWidth(390, 4);
    final geometry = PillNavGeometry.equal(inner / 4, 4);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => IosGlass(child: child!),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: geometry.navInnerW + SlidingPillNav.iosPadding * 2,
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
