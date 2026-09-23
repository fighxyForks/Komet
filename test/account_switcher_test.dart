import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/widgets/account_switcher_overlay.dart';

void main() {
  const screen = Size(390, 844);

  test('вызов снизу открывает меню над точкой касания', () {
    final top = accountSwitcherMenuTop(
      screen: screen,
      bottomInset: 34,
      tapPoint: const Offset(340, 800),
      height: 200,
    );
    expect(top + 200, lessThanOrEqualTo(800 - 20));
  });

  test('вызов сверху открывает меню под точкой касания', () {
    final top = accountSwitcherMenuTop(
      screen: screen,
      bottomInset: 34,
      tapPoint: const Offset(30, 90),
      height: 200,
    );
    expect(top, 110);
  });

  test('меню не уходит за нижний край', () {
    final top = accountSwitcherMenuTop(
      screen: screen,
      bottomInset: 34,
      tapPoint: const Offset(30, 400),
      height: 600,
    );
    expect(top + 600, lessThanOrEqualTo(844 - 34 - 24));
  });

  testWidgets('обычный тап выбирает пункт, а не только жест с ведением', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    final controller = AccountSwitcherController()
      ..attach(const Offset(10, 10));
    addTearDown(controller.dispose);
    await tester.tapAt(const Offset(200, 300));
    expect(controller.pointer, const Offset(200, 300));
    expect(controller.committed, isTrue);
  });
}
