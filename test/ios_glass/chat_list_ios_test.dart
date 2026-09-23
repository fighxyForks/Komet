import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_animations.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/screens/chats/chat/view/ios_chat_row.dart';
import 'package:komet/frontend/widgets/animated_lottie_icon.dart';
import 'package:komet/frontend/widgets/glass/glass_controls.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_palette.dart';
import 'package:komet/frontend/widgets/sliding_pill_nav.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget body, {ThemeData? theme}) => MaterialApp(
  theme: theme,
  builder: (context, child) => IosGlass(child: child!),
  home: Scaffold(body: body),
);

Widget _row({
  bool pinned = false,
  bool muted = false,
  int unread = 0,
  String sender = '',
  Widget? status,
}) => IosChatRow(
  avatar: const CircleAvatar(radius: 30),
  name: 'Синтетический чат',
  time: '00:28',
  sender: sender,
  isPinned: pinned,
  isMuted: muted,
  unreadCount: unread,
  statusIcon: status,
  body: const Text('последнее сообщение', maxLines: 1),
);

const _items = [
  PillNavItem(icon: Symbols.forum, label: 'Чаты'),
  PillNavItem(icon: Symbols.call, label: 'Звонки'),
  PillNavItem(icon: Symbols.account_circle, label: 'Контакты'),
  PillNavItem(icon: Symbols.settings, label: 'Настройки'),
];

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  group('Строка чата', () {
    testWidgets('высота 78, аватар 60, три строки для группы', (tester) async {
      await tester.pumpWidget(_app(_row(sender: 'Отправитель', unread: 16)));
      expect(tester.getSize(find.byType(IosChatRow)).height, 78);
      expect(tester.getSize(find.byType(CircleAvatar)), const Size(60, 60));
      expect(find.byKey(const ValueKey('ios-chat-sender')), findsOneWidget);
      expect(find.byKey(const ValueKey('ios-chat-badge-16')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('статус отправки по центру линии даты', (tester) async {
      await tester.pumpWidget(
        _app(_row(status: const Icon(Symbols.done_all, size: 14))),
      );
      final status = tester.getCenter(
        find.byKey(const ValueKey('ios-chat-status')),
      );
      final time = tester.getCenter(
        find.byKey(const ValueKey('ios-chat-time')),
      );
      expect(status.dy, closeTo(time.dy, 0.5));
      expect(status.dx, lessThan(time.dx));
    });

    testWidgets('закреп — серый фон и крупная скрепка под датой', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_row(pinned: true)));
      final pin = find.byKey(const ValueKey('ios-chat-pin'));
      expect(pin, findsOneWidget);
      expect(tester.getSize(pin).height, 20);
      final time = tester.getRect(find.byKey(const ValueKey('ios-chat-time')));
      final pinRect = tester.getRect(pin);
      expect(pinRect.top, greaterThan(time.bottom));
      expect(pinRect.right, closeTo(time.right, 1));
      final box = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(IosChatRow),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final color = (box.decoration as BoxDecoration?)?.color;
      final context = tester.element(find.byType(IosChatRow));
      expect(color, IosPalette.grouped(Theme.of(context).colorScheme));
    });

    testWidgets('счётчик заглушённого чата серый', (tester) async {
      await tester.pumpWidget(_app(_row(muted: true, unread: 3)));
      final badge = tester.widget<Container>(
        find.byKey(const ValueKey('ios-chat-badge-3')),
      );
      final context = tester.element(find.byType(IosChatRow));
      expect(
        (badge.decoration as BoxDecoration).color,
        IosPalette.mutedBadge(Theme.of(context).colorScheme),
      );
    });

    test('большие счётчики сокращаются', () {
      expect(IosChatRow.compactCount(16), '16');
      expect(IosChatRow.compactCount(65900), '65.9K');
      expect(IosChatRow.compactCount(7000), '7K');
      expect(IosChatRow.compactCount(250400), '250K');
    });
  });

  testWidgets('поиск на списке плоский, без стекла', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(IosFlatSearchBar(hint: 'Поиск', onTap: () => taps++)),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    await tester.tap(find.text('Поиск'));
    expect(taps, 1);
  });

  group('Капсула папок', () {
    test('помещающиеся подписи делят свободное место поровну', () {
      final widths = SegmentFit.widths([40, 90, 50, 80, 60], 350)!;
      expect(widths.fold<double>(0, (a, b) => a + b), closeTo(350, 1e-9));
      final extras = [
        for (final (i, w) in [40.0, 90.0, 50.0, 80.0, 60.0].indexed)
          widths[i] - w,
      ];
      expect(extras.toSet().length, 1);
      expect(extras.first, 6);
    });

    test('не помещающиеся подписи оставляют прокрутке', () {
      expect(SegmentFit.widths([120, 120, 120], 300), isNull);
    });

    testWidgets('ширина подписи учитывает поля', (tester) async {
      late double plain;
      late double padded;
      const style = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              plain = SegmentFit.labelWidth(context, 'Каналы', style);
              padded = SegmentFit.labelWidth(
                context,
                'Каналы',
                style,
                padding: 28,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      expect(plain, greaterThan(0));
      expect(padded, plain + 28);
    });
  });

  group('Панель вкладок', () {
    Future<void> pumpNav(
      WidgetTester tester, {
      double position = 0,
      List<String?> badges = const [],
      void Function(int)? onTap,
    }) async {
      final width = PillNavGeometry.iosInnerWidth(390, 4);
      await tester.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: width + SlidingPillNav.iosPadding * 2,
              child: SlidingPillNav(
                items: _items,
                position: position,
                geometry: PillNavGeometry.equal(width / 4, 4),
                badges: badges,
                onTap: onTap ?? (_) {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('все подписи видны всегда, ячейки одинаковые', (tester) async {
      await pumpNav(tester);
      for (final item in _items) {
        expect(find.text(item.label), findsOneWidget);
      }
      final first = tester.getSize(find.byKey(const ValueKey('ios-tab-0')));
      final last = tester.getSize(find.byKey(const ValueKey('ios-tab-3')));
      expect(first, last);
      expect(
        tester.getSize(find.byKey(const ValueKey('ios-tab-bar'))).height,
        SlidingPillNav.iosHeight,
      );
    });

    testWidgets('смена вкладки не двигает подписи', (tester) async {
      await pumpNav(tester);
      final before = tester.getRect(find.text('Звонки'));
      await pumpNav(tester, position: 2);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getRect(find.text('Звонки')), before);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Звонки')), before);
    });

    testWidgets('бейдж и нажатие', (tester) async {
      final taps = <int>[];
      await pumpNav(tester, badges: ['5'], onTap: taps.add);
      expect(find.byKey(const ValueKey('ios-tab-badge')), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      await tester.tap(find.text('Настройки'));
      expect(taps, [3]);
    });

    testWidgets('подсветка шире ячейки и не выходит за края панели', (
      tester,
    ) async {
      await pumpNav(tester, position: 3);
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byKey(const ValueKey('ios-tab-bar')));
      final cell = tester.getRect(find.byKey(const ValueKey('ios-tab-3')));
      final thumb = tester.getRect(find.byKey(const ValueKey('ios-tab-thumb')));
      expect(thumb.width, greaterThan(cell.width));
      expect(thumb.center.dx, closeTo(cell.center.dx, 0.01));
      expect(
        bar.right - thumb.right,
        closeTo(SlidingPillNav.iosThumbInset, 0.01),
      );
    });

    testWidgets('значки с анимацией рисуются через Lottie', (tester) async {
      await tester.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: 360,
              child: SlidingPillNav(
                items: const [
                  PillNavItem(
                    icon: Symbols.chat_bubble,
                    label: 'Чаты',
                    animationAsset: AppAnimations.chat,
                  ),
                  PillNavItem(icon: Symbols.call, label: 'Звонки'),
                ],
                position: 0,
                geometry: PillNavGeometry.equal(
                  (360 - SlidingPillNav.iosPadding * 2) / 2,
                  2,
                ),
                onTap: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.byType(AnimatedLottieIcon), findsOneWidget);
      expect(find.byIcon(Symbols.call), findsOneWidget);
    });
  });
}
