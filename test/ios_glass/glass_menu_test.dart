import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/chat_menu_overlay.dart';
import 'package:komet/frontend/widgets/glass/glass_capsule.dart';
import 'package:komet/frontend/widgets/glass/glass_menu.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(void Function(BuildContext context) open) => MaterialApp(
  builder: (context, child) => IosGlass(child: child!),
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => open(context),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

List<ChatMenuItem> _items(List<String> taps) => [
  ChatMenuItem(
    icon: Symbols.bookmark,
    label: 'Избранное',
    onTap: () => taps.add('saved'),
    dividerAfter: true,
  ),
  ChatMenuItem(
    icon: Symbols.delete,
    label: 'Удалить',
    destructive: true,
    onTap: () => taps.add('delete'),
  ),
];

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
  });

  tearDown(AppIosGlass.debugReset);

  group('Меню iOS', () {
    testWidgets('showChatMenu открывает стеклянное меню при активном iOS', (
      tester,
    ) async {
      AppIosGlass.debugSetSupported(true);
      final taps = <String>[];
      await tester.pumpWidget(
        _host(
          (context) => showChatMenu(
            context: context,
            anchorRect: const Rect.fromLTWH(700, 40, 44, 44),
            items: _items(taps),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('glass-menu')), findsOneWidget);
      expect(find.byType(GlassMenuRow), findsNWidgets(2));
      expect(GlassSuppression.count.value, 0);
      final panel = tester.widget(find.byKey(const ValueKey('glass-menu')));
      expect(panel, isA<GlassCapsule>());
      expect((panel as GlassCapsule).allowNative, isTrue);
      expect(
        tester.getSize(find.byType(GlassMenuRow).first).height,
        GlassMenuStyle.rowHeight,
      );
      expect(
        tester.widget<Text>(find.text('Избранное')).style?.fontSize,
        GlassMenuStyle.fontSize,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('glass-menu'))).width,
        GlassMenuStyle.width,
      );

      await tester.tap(find.text('Избранное'));
      await tester.pumpAndSettle();
      expect(taps, ['saved']);
      expect(find.byKey(const ValueKey('glass-menu')), findsNothing);
      expect(GlassSuppression.count.value, 0);
    });

    testWidgets('тап мимо меню закрывает его без действий', (tester) async {
      AppIosGlass.debugSetSupported(true);
      final taps = <String>[];
      await tester.pumpWidget(
        _host(
          (context) => showChatMenu(
            context: context,
            anchorRect: const Rect.fromLTWH(20, 40, 44, 44),
            items: _items(taps),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(780, 580));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('glass-menu')), findsNothing);
      expect(taps, isEmpty);
    });

    testWidgets('деструктивный пункт окрашен цветом ошибки', (tester) async {
      AppIosGlass.debugSetSupported(true);
      await tester.pumpWidget(
        _host(
          (context) => showChatMenu(
            context: context,
            anchorRect: const Rect.fromLTWH(700, 40, 44, 44),
            items: _items([]),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final context = tester.element(find.text('Удалить'));
      final text = tester.widget<Text>(find.text('Удалить'));
      expect(text.style?.color, Theme.of(context).colorScheme.error);
    });

    testWidgets('без iOS остаётся прежнее меню', (tester) async {
      await tester.pumpWidget(
        _host(
          (context) => showChatMenu(
            context: context,
            anchorRect: const Rect.fromLTWH(700, 40, 44, 44),
            items: _items([]),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Избранное'), findsOneWidget);
      expect(find.byKey(const ValueKey('glass-menu')), findsNothing);
      expect(find.byType(GlassMenuRow), findsNothing);
    });
  });

  group('Позиция меню', () {
    const screen = Size(400, 800);
    const menu = Size(250, 200);

    test('кнопка справа сверху: меню под ней, прижато к правому краю', () {
      final placement = GlassMenuPlacement.resolve(
        screen: screen,
        menu: menu,
        anchor: const Rect.fromLTWH(340, 50, 44, 44),
        safeArea: EdgeInsets.zero,
      );
      expect(placement.offset.dx, 384 - 250);
      expect(placement.offset.dy, 94 + GlassMenuStyle.gap);
      expect(placement.origin, Alignment.topRight);
    });

    test('кнопка снизу слева: меню над ней от левого края', () {
      final placement = GlassMenuPlacement.resolve(
        screen: screen,
        menu: menu,
        anchor: const Rect.fromLTWH(16, 700, 56, 56),
        safeArea: EdgeInsets.zero,
      );
      expect(placement.offset.dx, 16);
      expect(placement.offset.dy, 700 - GlassMenuStyle.gap - 200);
      expect(placement.origin, Alignment.bottomLeft);
    });

    test('меню не вылезает за экран', () {
      final placement = GlassMenuPlacement.resolve(
        screen: screen,
        menu: const Size(250, 780),
        anchor: const Rect.fromLTWH(340, 50, 44, 44),
        safeArea: const EdgeInsets.only(top: 40, bottom: 30),
      );
      expect(placement.offset.dy, greaterThanOrEqualTo(40));
    });
  });
}
