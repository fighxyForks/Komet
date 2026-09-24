import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/screens/profile/appearance_screen.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host() => MaterialApp(
  locale: const Locale('ru'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => IosGlass(child: child!),
  home: const Scaffold(body: IosGlassToggleRow()),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  testWidgets('тумблер выключает и включает iOS-интерфейс', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.text('Интерфейс iOS'), findsOneWidget);
    final toggle = find.byKey(const ValueKey('ios-glass-switch'));
    expect(
      tester
          .widget<CupertinoSwitch>(
            find.descendant(of: toggle, matching: find.byType(CupertinoSwitch)),
          )
          .value,
      isTrue,
    );

    await tester.tap(find.text('Интерфейс iOS'));
    await tester.pumpAndSettle();
    expect(AppIosGlass.enabled.value, isFalse);
    expect(AppIosGlass.active.value, isFalse);
    expect(
      tester
          .widget<Switch>(
            find.descendant(of: toggle, matching: find.byType(Switch)),
          )
          .value,
      isFalse,
    );

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(AppIosGlass.active.value, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AppIosGlass.prefKey), isTrue);
  });
}
