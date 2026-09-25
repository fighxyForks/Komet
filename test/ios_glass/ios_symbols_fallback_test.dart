import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_symbols.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<T> _resolveIos<T>(
  WidgetTester tester,
  T Function(BuildContext context) read,
) async {
  late T value;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => IosGlass(child: child!),
      home: Builder(
        builder: (context) {
          value = read(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  test('пустой кружок стоит только там, где он и нужен', () {
    const allowed = {'Symbols.circle', 'Symbols.radio_button_unchecked'};
    final source = File(
      'lib/frontend/widgets/glass/ios_symbols.dart',
    ).readAsStringSync();
    final pairs = RegExp(
      r'(Symbols\.\w+)(?:\.codePoint:|,\s*cupertino:)\s*CupertinoIcons\.circle\b',
    ).allMatches(source).map((m) => m.group(1)).toSet();
    expect(pairs.difference(allowed), isEmpty);
  });

  test('словарь adapt не подменяет иконки кружком', () {
    final circles = IosSymbols.debugCupertinoByCodePoint.entries
        .where((e) => e.value == CupertinoIcons.circle)
        .map((e) => e.key)
        .toSet();
    expect(
      circles.difference({
        Symbols.circle.codePoint,
        Symbols.radio_button_unchecked.codePoint,
      }),
      isEmpty,
    );
  });

  testWidgets('без точного аналога остаётся Material-символ', (tester) async {
    final icons = await _resolveIos(
      tester,
      (c) => [
        IosSymbols.fingerprint(c),
        IosSymbols.key(c),
        IosSymbols.doneAll(c),
        IosSymbols.videocamOff(c),
        IosSymbols.missedVideoCall(c),
        IosSymbols.smartToy(c),
      ],
    );
    expect(icons, [
      Symbols.fingerprint,
      Symbols.key,
      Symbols.done_all,
      Symbols.videocam_off,
      Symbols.missed_video_call,
      Symbols.smart_toy,
    ]);
  });

  testWidgets('бывшие заглушки получают свои iOS-иконки', (tester) async {
    final icons = await _resolveIos(
      tester,
      (c) => [
        IosSymbols.editSquare(c),
        IosSymbols.face(c),
        IosSymbols.exitToApp(c),
        IosSymbols.qrCodeScanner(c),
        IosSymbols.openInNew(c),
        IosSymbols.closeFullscreen(c),
        IosSymbols.openInFull(c),
      ],
    );
    expect(icons, [
      CupertinoIcons.square_pencil,
      CupertinoIcons.smiley,
      CupertinoIcons.square_arrow_right,
      CupertinoIcons.qrcode_viewfinder,
      CupertinoIcons.arrow_up_right_square,
      CupertinoIcons.arrow_down_right_arrow_up_left,
      CupertinoIcons.arrow_up_left_arrow_down_right,
    ]);
  });

  testWidgets('adapt без аналога возвращает исходный символ', (tester) async {
    final icon = await _resolveIos(
      tester,
      (c) => IosSymbols.adapt(c, Symbols.fingerprint),
    );
    expect(icon, Symbols.fingerprint);
  });
}
