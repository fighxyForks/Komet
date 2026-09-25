import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/widgets/ios_tab_switcher.dart';

class _Counter extends StatefulWidget {
  final String label;

  const _Counter(this.label);

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  static int created = 0;
  int taps = 0;

  @override
  void initState() {
    super.initState();
    created++;
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => setState(() => taps++),
    child: Text('${widget.label} $taps'),
  );
}

Widget _host(int index, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: IosTabSwitcher(
      index: index,
      tabs: [(_) => const _Counter('chats'), (_) => const _Counter('calls')],
    ),
  ),
);

void main() {
  setUp(() => _CounterState.created = 0);

  testWidgets('вкладка строится при первом открытии и сохраняет состояние', (
    tester,
  ) async {
    await tester.pumpWidget(_host(0));
    expect(_CounterState.created, 1);
    await tester.tap(find.text('chats 0'));
    await tester.pump();
    expect(find.text('chats 1'), findsOneWidget);

    await tester.pumpWidget(_host(1));
    await tester.pumpAndSettle();
    expect(_CounterState.created, 2);

    await tester.pumpWidget(_host(0));
    await tester.pumpAndSettle();
    expect(_CounterState.created, 2);
    expect(find.text('chats 1'), findsOneWidget);
  });

  testWidgets('скрытая вкладка не принимает нажатия', (tester) async {
    await tester.pumpWidget(_host(0));
    await tester.pumpWidget(_host(1));
    await tester.pumpAndSettle();
    expect(find.text('chats 0'), findsNothing);
    await tester.tap(find.text('calls 0'));
    await tester.pump();
    expect(find.text('calls 1'), findsOneWidget);
  });

  testWidgets('новая вкладка проявляется, старая уходит после проявления', (
    tester,
  ) async {
    await tester.pumpWidget(_host(0));
    await tester.pumpWidget(_host(1));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('chats 0'), findsOneWidget);
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('calls 0'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, inExclusiveRange(0, 1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('chats 0'), findsNothing);
    await tester.pumpAndSettle();
    expect(fade.opacity.value, 1);
  });

  testWidgets('при уменьшении движения переключение мгновенное', (
    tester,
  ) async {
    await tester.pumpWidget(_host(0, reduceMotion: true));
    await tester.pumpWidget(_host(1, reduceMotion: true));
    await tester.pump();
    expect(find.text('chats 0'), findsNothing);
    expect(find.text('calls 0'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
