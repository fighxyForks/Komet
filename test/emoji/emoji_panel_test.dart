import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/core/emoji/emoji_animoji_source.dart';
import 'package:komet/core/emoji/emoji_catalog.dart';
import 'package:komet/core/emoji/emoji_platform.dart';
import 'package:komet/core/emoji/emoji_recents.dart';
import 'package:komet/core/emoji/emoji_skin_prefs.dart';
import 'package:komet/core/emoji/emoji_version_filter.dart';
import 'package:komet/frontend/widgets/emoji_panel.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/rich_message_controller.dart';
import 'package:komet/frontend/widgets/small_spinner.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:komet/models/animoji.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _awaitPanel(WidgetTester tester) async {
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(CupertinoSearchTextField).evaluate().isNotEmpty) return;
    if (find.byType(TextField).evaluate().isNotEmpty) return;
    if (find.textContaining('Не удалось').evaluate().isNotEmpty) return;
    if (find.byType(SmallSpinner).evaluate().isEmpty) return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    AppIosGlass.debugSetSupported(true);
    EmojiRecents.debugReset();
    EmojiSkinPrefs.debugReset();
    EmojiVersionFilter.debugReset();
    EmojiPlatform.debugReset();
    EmojiVersionFilter.debugPlatform = TargetPlatform.macOS;
    await EmojiCatalog.instance.ensureLoaded();
    await EmojiPlatform.resolve();
  });

  tearDown(() {
    EmojiAnimojiSource.loader = null;
    AppIosGlass.debugReset();
    EmojiRecents.debugReset();
    EmojiSkinPrefs.debugReset();
    EmojiVersionFilter.debugReset();
    EmojiPlatform.debugReset();
  });

  testWidgets('search finds heart and tap inserts plain text', (tester) async {
    final controller = RichMessageController();
    final inserted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        builder: (context, child) => IosGlass(child: child!),
        home: Scaffold(
          body: SizedBox(
            height: 480,
            child: EmojiPanel(
              onEmojiTap: (_) {},
              onPlainEmojiTap: (emoji) {
                inserted.add(emoji);
                controller.insertPlainText(emoji);
              },
            ),
          ),
        ),
      ),
    );
    await _awaitPanel(tester);
    expect(
      find.byType(SmallSpinner),
      findsNothing,
      reason: 'panel still loading',
    );
    final search = find.byType(CupertinoSearchTextField);
    final materialSearch = find.byType(TextField);
    expect(
      search.evaluate().isNotEmpty || materialSearch.evaluate().isNotEmpty,
      isTrue,
    );
    await tester.enterText(
      search.evaluate().isNotEmpty ? search : materialSearch,
      'сердце',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Ничего не найдено'), findsNothing);
    final emojiTexts = find.byWidgetPredicate(
      (w) =>
          w is Text &&
          w.data != null &&
          w.data!.isNotEmpty &&
          w.style?.fontSize == 28,
    );
    expect(emojiTexts, findsWidgets);
    await tester.tap(emojiTexts.first);
    await tester.pump();
    expect(inserted, isNotEmpty);
    expect(controller.text, inserted.first);
  });

  testWidgets('category section headers appear', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        builder: (context, child) => IosGlass(child: child!),
        home: Scaffold(
          body: SizedBox(height: 480, child: EmojiPanel(onEmojiTap: (_) {})),
        ),
      ),
    );
    await _awaitPanel(tester);
    expect(
      find.byType(SmallSpinner),
      findsNothing,
      reason: 'panel still loading',
    );
    expect(
      find.byType(CupertinoSearchTextField).evaluate().isNotEmpty ||
          find.byType(TextField).evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.text('Смайлы и люди'), findsWidgets);
  });

  testWidgets('recent and animated sections precede categories', (
    tester,
  ) async {
    EmojiAnimojiSource.loader = () async => const [
      Animoji(id: 1, emoji: '👍'),
      Animoji(id: 2, emoji: '🔥'),
    ];
    SharedPreferences.setMockInitialValues({
      EmojiRecents.prefKey: ['a:2', 'e:😀', 'a:404'],
    });
    final tapped = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        builder: (context, child) => IosGlass(child: child!),
        home: Scaffold(
          body: SizedBox(
            height: 800,
            child: EmojiPanel(onEmojiTap: (a) => tapped.add(a.id)),
          ),
        ),
      ),
    );
    await _awaitPanel(tester);
    await tester.pump(const Duration(milliseconds: 100));

    double top(String title) => tester.getTopLeft(find.text(title).last).dy;
    expect(top('Недавние'), lessThan(top('Анимированные')));
    expect(top('Анимированные'), lessThan(top('Смайлы и люди')));

    expect(find.byKey(const ValueKey('ra-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('r-😀')), findsOneWidget);
    expect(find.byKey(const ValueKey('ra-404')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('animoji-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tapped, [1]);
    expect(EmojiRecents.current.value.first, const EmojiRecentAnimoji(1));
    expect(find.byKey(const ValueKey('ra-1')), findsOneWidget);
  });

  test('insertPlainText places emoji at cursor', () {
    final controller = RichMessageController(text: 'ab');
    controller.selection = const TextSelection.collapsed(offset: 1);
    controller.insertPlainText('😀');
    expect(controller.text, 'a😀b');
    expect(controller.selection.baseOffset, 1 + '😀'.length);
  });
}
