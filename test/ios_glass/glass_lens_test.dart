import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/glass/glass_lens_track.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/sliding_pill_nav.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _items = [
  PillNavItem(icon: Symbols.forum, label: 'Чаты'),
  PillNavItem(icon: Symbols.call, label: 'Звонки'),
  PillNavItem(icon: Symbols.account_circle, label: 'Контакты'),
  PillNavItem(icon: Symbols.settings, label: 'Настройки'),
];

const _lens = ValueKey('glass-lens');

Widget _nav(
  double position, {
  Duration duration = const Duration(milliseconds: 350),
  bool reduceMotion = false,
}) {
  final inner = PillNavGeometry.iosInnerWidth(390, 4);
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: IosGlass(child: child!),
    ),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: inner + SlidingPillNav.iosPadding * 2,
          child: SlidingPillNav(
            items: _items,
            position: position,
            animationDuration: duration,
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
      final rect = GlassLensTrack.thumbRect(
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
      final rect = GlassLensTrack.thumbRect(
        widths: const [40, 100],
        position: 0.5,
        height: 34,
      );
      expect(rect.left, 20);
      expect(rect.width, 70);
    });

    test('линза выходит за края бегунка пропорционально подъёму', () {
      const thumb = Rect.fromLTWH(10, 4, 90, 54);
      expect(GlassLensTrack.lensRect(thumb, 0), thumb);
      final lifted = GlassLensTrack.lensRect(thumb, 1);
      expect(lifted.width, 90 + GlassLensStyle.liftX * 2);
      expect(lifted.height, 54 + GlassLensStyle.liftY * 2);
      expect(lifted.center, thumb.center);
    });
  });

  testWidgets('при смене вкладки появляется линза и исчезает после остановки', (
    tester,
  ) async {
    await tester.pumpWidget(_nav(0));
    expect(find.byKey(_lens), findsNothing);

    await tester.pumpWidget(_nav(2));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(_lens), findsOneWidget);
    final bar = tester.getRect(find.byKey(const ValueKey('ios-tab-bar')));
    final lens = tester.getRect(find.byKey(_lens));
    expect(lens.height, greaterThan(bar.height));
    expect(
      find.descendant(
        of: find.byKey(_lens),
        matching: find.byType(ColorFiltered),
      ),
      findsNWidgets(2),
    );

    await tester.pumpAndSettle();
    expect(find.byKey(_lens), findsNothing);
    final cell = tester.getRect(find.byKey(const ValueKey('ios-tab-2')));
    final thumb = tester.getRect(find.byKey(const ValueKey('ios-tab-thumb')));
    expect(thumb.center.dx, closeTo(cell.center.dx, 0.01));
  });

  testWidgets(
    'при перетаскивании линза держится, пока бегунок между вкладками',
    (tester) async {
      await tester.pumpWidget(_nav(0, duration: Duration.zero));
      await tester.pumpWidget(_nav(1.4, duration: Duration.zero));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(_lens), findsOneWidget);

      await tester.pumpWidget(_nav(2, duration: Duration.zero));
      await tester.pumpAndSettle();
      expect(find.byKey(_lens), findsNothing);
    },
  );

  testWidgets('с «уменьшением движения» линза не появляется', (tester) async {
    await tester.pumpWidget(_nav(0, reduceMotion: true));
    await tester.pumpWidget(_nav(3, reduceMotion: true));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.byKey(_lens), findsNothing);
    }
    await tester.pumpAndSettle();
  });
}
