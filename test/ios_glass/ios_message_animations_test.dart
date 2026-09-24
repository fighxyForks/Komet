import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/screens/chats/chat/view/message_row_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: child)),
  ),
);

double _translationY(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find
        .descendant(
          of: find.byType(SentMessageAnimation),
          matching: find.byType(Transform),
        )
        .first,
  );
  return transform.transform.getTranslation().y;
}

double _scale(WidgetTester tester) => tester
    .widget<ScaleTransition>(
      find.descendant(
        of: find.byType(DeletingMessageAnimation),
        matching: find.byType(ScaleTransition),
      ),
    )
    .scale
    .value;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
  });

  tearDown(AppIosGlass.debugReset);

  testWidgets('в iOS-режиме новое сообщение только проявляется', (
    tester,
  ) async {
    AppIosGlass.debugSetSupported(true);
    await _pump(
      tester,
      SentMessageAnimation(onComplete: () {}, child: const Text('синтетика')),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(_translationY(tester), 0);
    await tester.pumpAndSettle();
  });

  testWidgets('вне iOS-режима новое сообщение поднимается снизу', (
    tester,
  ) async {
    AppIosGlass.debugSetSupported(false);
    await _pump(
      tester,
      SentMessageAnimation(onComplete: () {}, child: const Text('синтетика')),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(_translationY(tester), greaterThan(0));
    await tester.pumpAndSettle();
  });

  testWidgets('в iOS-режиме удаление сжимает сообщение до 0,1', (tester) async {
    AppIosGlass.debugSetSupported(true);
    await _pump(
      tester,
      DeletingMessageAnimation(
        onComplete: () {},
        child: const Text('синтетика'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 160));
    expect(_scale(tester), closeTo(0.1, 0.02));
    await tester.pumpAndSettle();
  });

  testWidgets('вне iOS-режима удаление сжимает до 0,82', (tester) async {
    AppIosGlass.debugSetSupported(false);
    await _pump(
      tester,
      DeletingMessageAnimation(
        onComplete: () {},
        child: const Text('синтетика'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(_scale(tester), closeTo(0.82, 0.02));
    await tester.pumpAndSettle();
  });
}
