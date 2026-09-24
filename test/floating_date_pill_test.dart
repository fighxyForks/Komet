import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/screens/chats/chat/view/message_list_decorations.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget body, {Brightness brightness = Brightness.dark}) =>
    MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: brightness,
        ),
      ),
      home: IosGlass(
        child: Scaffold(body: Center(child: body)),
      ),
    );

BoxDecoration _pill(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .ancestor(
                    of: find.byType(Text),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  test('плавающая дата прячется примерно через 1–1,5 с простоя', () {
    expect(
      FloatingDateBehavior.idleHideDelay.inMilliseconds,
      inInclusiveRange(1000, 1500),
    );
  });

  testWidgets('плавающая дата почти непрозрачна, текст под ней не виден', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(DateSeparatorLabel(date: DateTime.now(), floating: true)),
    );
    expect(find.byKey(const ValueKey('ios-floating-date')), findsOneWidget);
    expect(_pill(tester).color!.a, greaterThanOrEqualTo(0.9));
    expect(find.text('Сегодня'), findsOneWidget);
  });

  testWidgets('плавающая и встроенная дата одной формы и с одним ободком', (
    tester,
  ) async {
    final date = DateTime.now().subtract(const Duration(days: 1));
    await tester.pumpWidget(
      _app(DateSeparatorLabel(date: date, floating: true)),
    );
    final floating = _pill(tester);
    await tester.pumpWidget(_app(DateSeparatorLabel(date: date)));
    final inline = _pill(tester);
    expect(find.byKey(const ValueKey('ios-floating-date')), findsNothing);
    expect(find.text('Вчера'), findsOneWidget);
    expect(inline.borderRadius, floating.borderRadius);
    expect(inline.border, floating.border);
    expect(inline.color!.a, lessThan(floating.color!.a));
  });
}
