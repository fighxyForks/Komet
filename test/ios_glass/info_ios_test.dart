import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/glass/glass_capsule.dart';
import 'package:komet/frontend/widgets/glass/glass_controls.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/settings_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tabs = ['Общие чаты', 'Медиа', 'Файлы', 'Голосовые', 'Ссылки'];

Widget _app(Widget body) => MaterialApp(
  builder: (context, child) => IosGlass(child: child!),
  home: Scaffold(body: Center(child: body)),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  testWidgets('категории вложений — одна стеклянная капсула с бегунком', (
    tester,
  ) async {
    var selected = _tabs.first;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 360,
            child: GlassTabStrip(
              tabs: _tabs,
              selected: selected,
              onSelected: (tab) => setState(() => selected = tab),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(GlassCapsule), findsOneWidget);
    expect(
      tester.widget<GlassCapsule>(find.byType(GlassCapsule)).allowNative,
      isTrue,
    );
    expect(find.byType(GlassSegmentThumb), findsNWidgets(_tabs.length));

    await tester.tap(find.byKey(const ValueKey('glass-tab-Медиа')));
    await tester.pumpAndSettle();
    expect(selected, 'Медиа');

    final label = tester.widget<AnimatedDefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Медиа'),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .first,
    );
    expect(label.style.fontWeight, IosType.title);
  });

  testWidgets('панели инфо — белые сгруппированные секции', (tester) async {
    await tester.pumpWidget(
      _app(
        const IosGroupedSection(
          radius: 18,
          child: SizedBox(width: 200, height: 60),
        ),
      ),
    );
    final box = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(IosGroupedSection),
        matching: find.byType(ColoredBox),
      ),
    );
    final context = tester.element(find.byType(IosGroupedSection));
    expect(
      box.color,
      IosGroupedSection.background(Theme.of(context).colorScheme),
    );
    final clip = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
    expect(clip.borderRadius, BorderRadius.circular(18));
  });
}
