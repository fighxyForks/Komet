import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/screens/chats/chat/view/message_list_decorations.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget body, {Brightness brightness = Brightness.dark}) =>
    MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: brightness,
        ),
      ),
      home: IosGlass(child: Scaffold(body: body)),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  test('floating date hides after roughly 1–1.5s of idle', () {
    expect(
      FloatingDateBehavior.idleHideDelay.inMilliseconds,
      inInclusiveRange(1000, 1500),
    );
  });

  testWidgets('iOS floating date pill uses an opaque fill', (tester) async {
    await tester.pumpWidget(
      _app(
        DateSeparatorLabel(
          date: DateTime(2026, 9, 24),
          floating: true,
        ),
      ),
    );

    final decorated = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('ios-floating-date')),
    );
    final decoration = decorated.decoration as BoxDecoration;
    final color = decoration.color!;
    expect(color.a, greaterThanOrEqualTo(0.9));
    expect(find.text('Сегодня'), findsOneWidget);
  });

  testWidgets('inline date separator stays distinct from floating pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        DateSeparatorLabel(
          date: DateTime(2026, 9, 24),
          floating: false,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('ios-floating-date')), findsNothing);
    expect(find.text('Сегодня'), findsOneWidget);
  });

  testWidgets('top edge vignette is IgnorePointer DecoratedBox gradient', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Stack(
          children: [
            MessageListEdgeVignette(top: true, height: 100),
          ],
        ),
      ),
    );

    expect(find.byType(IgnorePointer), findsWidgets);
    final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.gradient, isA<LinearGradient>());
  });
}
