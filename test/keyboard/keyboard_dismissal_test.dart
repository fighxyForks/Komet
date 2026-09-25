import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/widgets/keyboard_dismissal.dart';

Widget _app(Widget body, {List<NavigatorObserver> observers = const []}) {
  return MaterialApp(
    navigatorObservers: observers,
    builder: (context, child) => KeyboardDismissal(child: child!),
    home: Scaffold(body: body),
  );
}

void main() {
  late FocusNode focus;

  setUp(() => focus = FocusNode());
  tearDown(() => focus.dispose());

  Future<void> focusField(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('field')));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
  }

  testWidgets('короткий тап вне поля закрывает клавиатуру', (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            TextField(key: const ValueKey('field'), focusNode: focus),
            const SizedBox(key: ValueKey('outside'), height: 300),
          ],
        ),
      ),
    );
    await focusField(tester);

    await tester.tap(find.byKey(const ValueKey('outside')));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });

  testWidgets('долгое касание и сдвиг пальца не закрывают', (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            TextField(key: const ValueKey('field'), focusNode: focus),
            const SizedBox(key: ValueKey('outside'), height: 300),
          ],
        ),
      ),
    );
    await focusField(tester);

    final hold = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('outside'))),
    );
    await tester.pump(const Duration(seconds: 1));
    await hold.up(timeStamp: const Duration(seconds: 1));
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    await tester.dragFrom(
      tester.getCenter(find.byKey(const ValueKey('outside'))),
      const Offset(120, 0),
    );
    await tester.pump();
    expect(focus.hasFocus, isTrue);
  });

  testWidgets('кнопки в TextFieldTapRegion не закрывают', (tester) async {
    var sent = 0;
    await tester.pumpWidget(
      _app(
        TextFieldTapRegion(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('field'),
                  focusNode: focus,
                ),
              ),
              IconButton(
                key: const ValueKey('send'),
                onPressed: () => sent++,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
    await focusField(tester);

    await tester.tap(find.byKey(const ValueKey('send')));
    await tester.pump();
    expect(sent, 1);
    expect(focus.hasFocus, isTrue);
  });

  testWidgets('вертикальная прокрутка закрывает, горизонтальная — нет', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            TextField(key: const ValueKey('field'), focusNode: focus),
            SizedBox(
              height: 80,
              child: ListView(
                key: const ValueKey('row'),
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < 20; i++)
                    SizedBox(width: 80, child: Text('h$i')),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey('list'),
                children: [
                  for (var i = 0; i < 40; i++)
                    SizedBox(height: 60, child: Text('v$i')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    await focusField(tester);

    await tester.drag(find.byKey(const ValueKey('row')), const Offset(-200, 0));
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    await tester.drag(
      find.byKey(const ValueKey('list')),
      const Offset(0, -200),
    );
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });

  testWidgets('прокрутка внутри многострочного поля не закрывает', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ListView(
          children: [
            TextField(
              key: const ValueKey('field'),
              focusNode: focus,
              maxLines: 3,
              controller: TextEditingController(
                text: List.generate(30, (i) => 'строка $i').join('\n'),
              ),
            ),
          ],
        ),
      ),
    );
    await focusField(tester);

    await tester.drag(find.byType(EditableText), const Offset(0, -60));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
  });

  testWidgets('переход на новый экран снимает фокус', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [KeyboardNavigatorObserver()],
        home: Scaffold(
          body: TextField(key: const ValueKey('field'), focusNode: focus),
        ),
      ),
    );
    await focusField(tester);

    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isFalse);
  });

  testWidgets('начало свайпа назад снимает фокус с поля', (tester) async {
    await tester.pumpWidget(
      _app(TextField(key: const ValueKey('field'), focusNode: focus)),
    );
    await focusField(tester);

    KeyboardNavigatorObserver().didStartUserGesture(
      MaterialPageRoute<void>(builder: (_) => const SizedBox()),
      null,
    );
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });
}
