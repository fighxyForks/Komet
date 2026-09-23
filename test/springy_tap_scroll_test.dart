import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/widgets/springy_tap.dart';

Widget _list() => MaterialApp(
  home: Scaffold(
    body: ListView.builder(
      itemCount: 60,
      itemBuilder: (context, i) => SpringyTap(
        key: ValueKey('row-$i'),
        child: SizedBox(height: 72, child: Text('Строка $i')),
      ),
    ),
  ),
);

double _scaleOf(WidgetTester tester, int row) => tester
    .widget<ScaleTransition>(
      find.descendant(
        of: find.byKey(ValueKey('row-$row')),
        matching: find.byType(ScaleTransition),
      ),
    )
    .scale
    .value;

void main() {
  testWidgets('прокрутка не сжимает и не раздувает строку', (tester) async {
    await tester.pumpWidget(_list());
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('row-2'))),
    );
    var maxScale = 0.0;
    var minScale = 2.0;
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, -12));
      await tester.pump(const Duration(milliseconds: 16));
      final scale = _scaleOf(tester, 2);
      maxScale = scale > maxScale ? scale : maxScale;
      minScale = scale < minScale ? scale : minScale;
    }
    await gesture.up();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (find.byKey(const ValueKey('row-2')).evaluate().isEmpty) break;
      final scale = _scaleOf(tester, 2);
      maxScale = scale > maxScale ? scale : maxScale;
    }
    expect(maxScale, lessThanOrEqualTo(1.0));
    expect(minScale, 1.0);
    await tester.pumpAndSettle();
  });

  testWidgets('обычное нажатие по-прежнему пружинит', (tester) async {
    await tester.pumpWidget(_list());
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('row-0'))),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_scaleOf(tester, 0), lessThan(1.0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_scaleOf(tester, 0), closeTo(1.0, 0.001));
  });
}
