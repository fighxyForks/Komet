import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_fonts.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/screens/chats/chat/view/ios_chat_row.dart';
import 'package:komet/frontend/screens/chats/chat/view/message_list_decorations.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_typography.dart';
import 'package:komet/frontend/widgets/section_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool systemFont = true,
}) async {
  await tester.pumpWidget(
    IosGlass(
      child: MaterialApp(
        theme: ThemeData(
          extensions: [
            AppDisplayFont(
              systemFont ? kDisplayFontFamily : 'Inter',
              systemBody: systemFont,
            ),
          ],
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
}

TextStyle _style(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

String? _displayFamily(WidgetTester tester) =>
    displayFontOf(tester.element(find.byType(Scaffold)));

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
  });

  tearDown(AppIosGlass.debugReset);

  testWidgets('в iOS-режиме заголовки набираются системным шрифтом', (
    tester,
  ) async {
    AppIosGlass.debugSetSupported(true);
    await _pump(tester, const SizedBox());
    expect(_displayFamily(tester), isNull);
  });

  testWidgets('выбранный пользователем шрифт в iOS-режиме сохраняется', (
    tester,
  ) async {
    AppIosGlass.debugSetSupported(true);
    await _pump(tester, const SizedBox(), systemFont: false);
    expect(_displayFamily(tester), 'Inter');
  });

  testWidgets('вне iOS-режима заголовки остаются в Outfit', (tester) async {
    AppIosGlass.debugSetSupported(false);
    await _pump(tester, const SizedBox());
    expect(_displayFamily(tester), kDisplayFontFamily);
  });

  testWidgets('строка чата: имя 16, время 14, счётчик 12 в круге 20', (
    tester,
  ) async {
    AppIosGlass.debugSetSupported(true);
    await _pump(
      tester,
      const IosChatRow(
        avatar: SizedBox(),
        name: 'Синтетический чат',
        time: '12:00',
        body: Text('превью'),
        unreadCount: 3,
      ),
    );
    expect(_style(tester, 'Синтетический чат').fontSize, 16);
    expect(_style(tester, '12:00').fontSize, 14);
    expect(_style(tester, '3').fontSize, 12);
    expect(_style(tester, '3').fontWeight, FontWeight.w600);
    expect(
      tester.getSize(find.byKey(const ValueKey('ios-chat-badge-3'))).height,
      IosTypography.chatBadgeDiameter,
    );
  });

  testWidgets('заголовок секции в iOS-режиме обычного начертания', (
    tester,
  ) async {
    AppIosGlass.debugSetSupported(true);
    await _pump(tester, const SectionHeader('Секция'));
    final style = _style(tester, 'Секция');
    expect(style.fontWeight, FontWeight.w400);
    expect(style.letterSpacing, isNull);
  });

  testWidgets(
    'заголовок секции: effective letterSpacing не Material-положительный',
    (tester) async {
      AppIosGlass.debugSetSupported(true);
      final textTheme = AppFonts.textTheme(
        'system',
        ThemeData(useMaterial3: true).textTheme,
      );
      await tester.pumpWidget(
        IosGlass(
          child: MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              textTheme: textTheme,
              extensions: const [
                AppDisplayFont(kDisplayFontFamily, systemBody: true),
              ],
            ),
            home: const Scaffold(body: SectionHeader('Секция')),
          ),
        ),
      );
      final local = _style(tester, 'Секция');
      expect(local.letterSpacing, isNull);
      final rich = tester.widget<RichText>(
        find.descendant(
          of: find.text('Секция'),
          matching: find.byType(RichText),
        ),
      );
      final effective = rich.text.style?.letterSpacing;
      expect(effective, isNotNull);
      expect(effective!, lessThanOrEqualTo(0));
    },
  );

  testWidgets('заголовок секции вне iOS-режима прежний', (tester) async {
    AppIosGlass.debugSetSupported(false);
    await _pump(tester, const SectionHeader('Секция'));
    final style = _style(tester, 'Секция');
    expect(style.fontWeight, FontWeight.w600);
    expect(style.letterSpacing, 0.5);
  });

  testWidgets('дата в ленте iOS-режима 13 medium без курсива', (tester) async {
    AppIosGlass.debugSetSupported(true);
    await _pump(tester, DateSeparatorLabel(date: DateTime(2020, 5, 17)));
    final style = tester.widget<Text>(find.byType(Text)).style!;
    expect(style.fontSize, IosTypography.dateHeader);
    expect(style.fontStyle, isNot(FontStyle.italic));
  });

  testWidgets('дата в ленте вне iOS-режима без курсива', (tester) async {
    AppIosGlass.debugSetSupported(false);
    await _pump(tester, DateSeparatorLabel(date: DateTime(2020, 5, 17)));
    final style = tester.widget<Text>(find.byType(Text)).style!;
    expect(style.fontStyle, isNot(FontStyle.italic));
  });
}
