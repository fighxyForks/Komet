import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/attachment/bubbles/ios_bubble_metrics.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/text_with_meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

const TextStyle _body = TextStyle(
  fontSize: IosBubbleMetrics.textSize,
  height: IosBubbleMetrics.textHeight,
);
const TextStyle _meta = TextStyle(fontSize: IosBubbleMetrics.timeSize);
const String _time = '09:03';

Future<void> _pump(
  WidgetTester tester,
  Widget text, {
  double width = 300,
  Widget meta = const Text(_time, style: _meta),
}) => tester.pumpWidget(
  MaterialApp(
    home: IosGlass(
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: Align(
              alignment: Alignment.topLeft,
              child: TextWithMeta(text: text, meta: meta),
            ),
          ),
        ),
      ),
    ),
  ),
);

double _baseline(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  return tester.getTopLeft(finder).dy +
      paragraph.computeDistanceToActualBaseline(TextBaseline.alphabetic);
}

double _lastLineBaseline(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final end = TextPosition(offset: paragraph.text.toPlainText().length);
  final lineBottom =
      paragraph.getOffsetForCaret(end, Rect.zero).dy +
      paragraph.getFullHeightForCaret(end);
  final firstLine = paragraph.getFullHeightForCaret(
    const TextPosition(offset: 0),
  );
  final descent =
      firstLine -
      paragraph.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  return tester.getTopLeft(finder).dy + lineBottom - descent;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
    AppIosGlass.debugSetSupported(true);
  });

  tearDown(AppIosGlass.debugReset);

  testWidgets('одна строка: время стоит на базовой линии текста', (
    tester,
  ) async {
    await _pump(tester, const Text('Получено', style: _body));
    expect(
      _baseline(tester, find.text(_time)),
      closeTo(_baseline(tester, find.text('Получено')), 0.5),
    );
  });

  testWidgets('несколько строк: время на базовой линии последней строки', (
    tester,
  ) async {
    const text = 'Первая строка текста\nи короткая';
    await _pump(tester, const Text(text, style: _body));
    final body = find.text(text);
    expect(
      _baseline(tester, find.text(_time)),
      closeTo(_lastLineBaseline(tester, body), 0.5),
    );
    expect(
      _baseline(tester, find.text(_time)),
      greaterThan(_baseline(tester, body) + 10),
    );
  });

  testWidgets('последняя строка выше первой: время идёт по последней', (
    tester,
  ) async {
    await _pump(
      tester,
      const Text.rich(
        TextSpan(
          style: _body,
          children: [
            TextSpan(text: 'Крупно\n', style: TextStyle(fontSize: 30)),
            TextSpan(text: 'мелко'),
          ],
        ),
      ),
    );
    final body = find.byType(RichText).first;
    expect(
      _baseline(tester, find.text(_time)),
      closeTo(_lastLineBaseline(tester, body), 0.5),
    );
  });

  testWidgets('время на своей строке прижато к низу', (tester) async {
    await _pump(
      tester,
      const Text('Длинная строка которая заполняет ширину', style: _body),
      width: 160,
    );
    final box = tester.getRect(find.byType(TextWithMeta));
    final meta = tester.getRect(find.text(_time));
    expect(meta.bottom, closeTo(box.bottom, 0.01));
  });

  testWidgets('без базовой линии у метки время прижато к низу', (tester) async {
    await _pump(
      tester,
      const Text('Получено', style: _body),
      meta: const SizedBox(key: ValueKey('ticks'), width: 20, height: 10),
    );
    final box = tester.getRect(find.byType(TextWithMeta));
    final meta = tester.getRect(find.byKey(const ValueKey('ticks')));
    expect(meta.bottom, lessThan(box.bottom));
    expect(meta.bottom, greaterThan(box.bottom - 4));
  });

  testWidgets('вне iOS-режима время по-прежнему у нижнего края', (
    tester,
  ) async {
    AppIosGlass.debugSetSupported(false);
    await _pump(tester, const Text('Получено', style: _body));
    final box = tester.getRect(find.byType(TextWithMeta));
    final meta = tester.getRect(find.text(_time));
    expect(meta.bottom, closeTo(box.bottom - 2, 0.01));
  });
}
