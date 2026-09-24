import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/prompt_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  testWidgets('iOS-промпт возвращает текст и спокойно закрывается', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => IosGlass(child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showTextInputDialog(
                  context,
                  title: 'Имя',
                  initialValue: 'Круг',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoTextField), findsOneWidget);
    await tester.enterText(find.byType(CupertinoTextField), 'Иван');
    await tester.tap(find.text('Подтвердить'));
    await tester.pumpAndSettle();
    expect(result, 'Иван');
    expect(find.byType(CupertinoAlertDialog), findsNothing);
  });
}
