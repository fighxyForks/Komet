import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/screens/chats/chat_preview_overlay.dart';
import 'package:komet/frontend/widgets/chat_menu_item.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Rect _row = Rect.fromLTWH(0, 300, 390, 78);

Future<void> _pumpAndShow(WidgetTester tester, {VoidCallback? onPin}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    IosGlass(
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showIosChatPreview(
                  context,
                  sourceRect: _row,
                  chatId: 42,
                  name: 'Синтетический чат',
                  imageUrl: '',
                  chatType: 'DIALOG',
                  actions: [
                    ChatMenuItem(
                      icon: Symbols.keep,
                      label: 'Закрепить',
                      onTap: onPin,
                    ),
                  ],
                  onOpen: () {},
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
}

Rect _cardRect(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey('chat-preview-card')));

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  testWidgets('карточка вырастает из строки и держит меню под собой', (
    tester,
  ) async {
    await _pumpAndShow(tester);
    await tester.pump(const Duration(milliseconds: 16));
    final early = _cardRect(tester);
    expect(early.width, lessThan(390 - ChatPreviewOverlay.sideInset * 2));
    expect(early.center.dy, closeTo(_row.center.dy, 80));

    await tester.pump(const Duration(milliseconds: 200));
    final later = _cardRect(tester);
    expect(later.width, greaterThan(early.width));
    expect(find.text('Закрепить'), findsOneWidget);
    expect(find.text('Открыть'), findsOneWidget);
  });

  testWidgets('тап по фону закрывает предпросмотр', (tester) async {
    await _pumpAndShow(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byType(ChatPreviewOverlay), findsNothing);
  });

  testWidgets('пункт меню закрывает предпросмотр и выполняет действие', (
    tester,
  ) async {
    var pinned = false;
    await _pumpAndShow(tester, onPin: () => pinned = true);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Закрепить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byType(ChatPreviewOverlay), findsNothing);
    expect(pinned, isTrue);
  });
}
