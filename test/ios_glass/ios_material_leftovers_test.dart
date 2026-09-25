import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/core/config/countries.dart';
import 'package:komet/frontend/screens/auth/select_country_screen.dart';
import 'package:komet/frontend/screens/chats/profile_action_sheets.dart';
import 'package:komet/frontend/screens/profile/customization_section.dart';
import 'package:komet/frontend/widgets/glass/glass_controls.dart';
import 'package:komet/frontend/widgets/glass/ios_alert.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/settings_card.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:komet/main.dart' show api;
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ru'),
  builder: (context, child) => IosGlass(child: child!),
  home: home,
);

Future<BuildContext> _pumpContext(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) {
          captured = context;
          return const Scaffold();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => api);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  testWidgets('подтверждение на iOS — системный алерт', (tester) async {
    final context = await _pumpContext(tester);
    final result = showBlurredConfirm(
      context,
      title: 'Очистить историю?',
      message: 'Действие нельзя отменить',
      confirmLabel: 'Очистить',
      cancelLabel: 'Отмена',
      destructive: true,
    );
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.byType(IosCheckbox), findsNothing);
    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();
    final choice = await result;
    expect(choice.confirmed, isTrue);
    expect(choice.checked, isFalse);
  });

  testWidgets('галочка в подтверждении переключается и возвращается', (
    tester,
  ) async {
    final context = await _pumpContext(tester);
    final result = showBlurredConfirm(
      context,
      title: 'Очистить историю?',
      message: 'Действие нельзя отменить',
      confirmLabel: 'Очистить',
      cancelLabel: 'Отмена',
      checkboxLabel: 'Также у собеседника',
    );
    await tester.pumpAndSettle();

    expect(find.byType(IosCheckbox), findsOneWidget);
    await tester.tap(find.text('Также у собеседника'));
    await tester.pump();
    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();
    final choice = await result;
    expect(choice.confirmed, isTrue);
    expect(choice.checked, isTrue);
  });

  testWidgets('отмена подтверждения', (tester) async {
    final context = await _pumpContext(tester);
    final result = showBlurredConfirm(
      context,
      title: 'Выйти из группы?',
      message: 'Вы сможете вернуться по ссылке',
      confirmLabel: 'Выйти',
      cancelLabel: 'Отмена',
      checkboxLabel: 'Удалить историю',
      checkboxInitial: true,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    final choice = await result;
    expect(choice.confirmed, isFalse);
    expect(choice.checked, isFalse);
  });

  testWidgets('выбор страны на iOS: поиск и выбор', (tester) async {
    const first = CountryName(
      code: 'AA',
      en: 'Alpha',
      ru: 'Альфа',
      phoneCode: '+901',
      phoneDigits: 7,
      phoneMask: '### ####',
      phoneGroupSizes: [3, 4],
      phoneGroupSeparators: ['', ' ', ''],
    );
    const second = CountryName(
      code: 'BB',
      en: 'Beta',
      ru: 'Бета',
      phoneCode: '+902',
      phoneDigits: 7,
      phoneMask: '### ####',
      phoneGroupSizes: [3, 4],
      phoneGroupSeparators: ['', ' ', ''],
    );
    CountryName? picked;
    final context = await _pumpContext(tester);
    Navigator.of(context)
        .push(
          MaterialPageRoute<CountryName>(
            builder: (_) => SelectCountryScreen(
              selectedCountry: first,
              countries: const [first, second],
            ),
          ),
        )
        .then((value) => picked = value);
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(ListTile), findsNothing);
    await tester.enterText(find.byType(CupertinoSearchTextField), 'бет');
    await tester.pump();
    expect(find.text('Альфа'), findsNothing);
    await tester.tap(find.text('Бета'));
    await tester.pumpAndSettle();
    expect(picked, second);
  });

  testWidgets('«Кастомизация» на iOS — сразу список разделов', (tester) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: SingleChildScrollView(child: CustomizationSection()),
        ),
      ),
    );
    expect(find.byType(SettingsNavTile), findsNWidgets(6));
    expect(find.text('Кастомизация'), findsNothing);
  });

  testWidgets('action sheet без нативной стороны — Cupertino', (tester) async {
    final context = await _pumpContext(tester);
    final chosen = <String>[];
    final done = showIosActionSheet(
      context: context,
      title: 'Язык',
      cancelLabel: 'Отмена',
      actions: [
        IosSheetAction(
          id: 'ru',
          label: 'Русский',
          onSelected: () => chosen.add('ru'),
        ),
        IosSheetAction(
          id: 'en',
          label: 'English',
          onSelected: () => chosen.add('en'),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await done;
    expect(chosen, ['en']);
  });
}
