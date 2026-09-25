import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/core/native/native_alert_bridge.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/prompt_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    AppIosGlass.debugSetSupported(true);
    NativeAlertBridge.debugAvailable = true;
  });

  tearDown(() {
    AppIosGlass.debugReset();
    NativeAlertBridge.debugReset();
    messenger.setMockMethodCallHandler(NativeAlertBridge.channel, null);
  });

  Future<Future<String?>> openPrompt(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => IosGlass(child: child!),
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final result = showTextInputDialog(
      captured,
      title: 'Присоединиться к звонку',
      description: 'Вставьте ссылку-приглашение',
      hint: 'https://example.test/join/...',
      confirmLabel: 'Присоединиться',
      keyboardType: TextInputType.url,
    );
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('в iOS-режиме спрашивает системное окно', (tester) async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(NativeAlertBridge.channel, (call) async {
      calls.add(call);
      return 'https://example.test/join/abc';
    });

    final result = await openPrompt(tester);

    expect(await result, 'https://example.test/join/abc');
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(calls.single.method, 'prompt');
    expect(calls.single.arguments, {
      'title': 'Присоединиться к звонку',
      'message': 'Вставьте ссылку-приглашение',
      'placeholder': 'https://example.test/join/...',
      'text': null,
      'confirm': 'Присоединиться',
      'cancel': 'Отмена',
      'secure': false,
      'keyboard': 'url',
    });
  });

  testWidgets('отмена в системном окне возвращает null', (tester) async {
    messenger.setMockMethodCallHandler(
      NativeAlertBridge.channel,
      (call) async => null,
    );

    final result = await openPrompt(tester);

    expect(await result, isNull);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
  });

  testWidgets('без нативной стороны показывает Cupertino-окно', (tester) async {
    messenger.setMockMethodCallHandler(
      NativeAlertBridge.channel,
      (call) async => throw MissingPluginException(),
    );

    final result = await openPrompt(tester);

    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    await tester.enterText(find.byType(CupertinoTextField), '  ссылка  ');
    await tester.tap(find.text('Присоединиться'));
    await tester.pumpAndSettle();
    expect(await result, 'ссылка');
  });

  test('тип клавиатуры передаётся по имени', () {
    expect(NativeAlertBridge.keyboardName(TextInputType.url), 'url');
    expect(NativeAlertBridge.keyboardName(TextInputType.emailAddress), 'email');
    expect(NativeAlertBridge.keyboardName(TextInputType.number), 'number');
    expect(NativeAlertBridge.keyboardName(null), 'text');
  });
}
