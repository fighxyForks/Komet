import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/glass/glass_segment_track.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_native_tab_bar.dart';
import 'package:komet/frontend/widgets/sliding_pill_nav.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _items = [
  PillNavItem(icon: Symbols.forum, label: 'Чаты', sfSymbol: 'phone.fill'),
  PillNavItem(icon: Symbols.call, label: 'Звонки'),
  PillNavItem(icon: Symbols.account_circle, label: 'Контакты'),
  PillNavItem(icon: Symbols.settings, label: 'Настройки'),
];

Widget _nav(double position) {
  final inner = PillNavGeometry.iosInnerWidth(390, 4);
  return MaterialApp(
    builder: (context, child) => IosGlass(child: child!),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: inner + SlidingPillNav.iosPadding * 2,
          child: SlidingPillNav(
            items: _items,
            position: position,
            animationDuration: const Duration(milliseconds: 350),
            geometry: PillNavGeometry.equal(inner / 4, 4),
            onTap: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  group('Геометрия бегунка', () {
    test('между ячейками равной ширины движется линейно', () {
      final rect = GlassSegmentTrack.thumbRect(
        widths: const [80, 80, 80, 80],
        position: 1.5,
        height: 62,
        contentPadding: const EdgeInsets.symmetric(horizontal: 11),
        thumbInset: 4,
        thumbOutset: 7,
      );
      expect(rect, const Rect.fromLTWH(11 + 120 - 7, 4, 94, 54));
    });

    test('между ячейками разной ширины меняет и ширину', () {
      final rect = GlassSegmentTrack.thumbRect(
        widths: const [40, 100],
        position: 0.5,
        height: 34,
      );
      expect(rect.left, 20);
      expect(rect.width, 70);
    });
  });

  testWidgets('бегунок доезжает до выбранной вкладки', (tester) async {
    await tester.pumpWidget(_nav(0));
    await tester.pumpWidget(_nav(2));
    await tester.pump(const Duration(milliseconds: 100));
    final cell = tester.getRect(find.byKey(const ValueKey('ios-tab-2')));
    var thumb = tester.getRect(find.byKey(const ValueKey('ios-tab-thumb')));
    expect(thumb.center.dx, lessThan(cell.center.dx));
    await tester.pumpAndSettle();
    thumb = tester.getRect(find.byKey(const ValueKey('ios-tab-thumb')));
    expect(thumb.center.dx, closeTo(cell.center.dx, 0.01));
  });

  group('Нативная панель вкладок', () {
    test('SF Symbol важнее значка Flutter, бейдж попадает в свою вкладку', () {
      final tabs = IosNativeTabBar.tabItems(_items, const ['5']);
      expect(tabs.map((t) => t.label), _items.map((i) => i.label));
      expect(tabs[0].icon.isSfSymbol, isTrue);
      expect(tabs[0].icon.sfSymbolName, 'phone.fill');
      expect(tabs[1].icon.isIconData, isTrue);
      expect(tabs[0].iosBadgeValue, '5');
      expect(tabs[1].iosBadgeValue, isNull);
    });

    testWidgets('поверх системной панели нет Flutter-жестов, глотающих тап', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IosNativeTabBar(items: _items, currentIndex: 0, onTap: (_) {}),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(IosNativeTabBar),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
    });
  });
}
