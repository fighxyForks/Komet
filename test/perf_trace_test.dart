import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/utils/perf_trace.dart';

ui.FrameTiming _frame({required int buildUs, required int rasterUs}) =>
    ui.FrameTiming(
      vsyncStart: 0,
      buildStart: 0,
      buildFinish: buildUs,
      rasterStart: buildUs,
      rasterFinish: buildUs + rasterUs,
      rasterFinishWallTime: buildUs + rasterUs,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final trace = PerfTrace.instance;

  setUp(trace.debugReset);
  tearDown(trace.debugReset);

  test('выключенная трассировка ничего не пишет', () {
    trace.event('nav', 'синтетика');
    trace.handleTimings([_frame(buildUs: 40000, rasterUs: 40000)]);
    expect(trace.lines, isEmpty);
  });

  test('кадр дольше бюджета попадает в журнал с экраном', () {
    trace.setEnabled(true);
    trace.setRoute('ChatScreen');
    trace.handleTimings([
      _frame(buildUs: 3000, rasterUs: 3000),
      _frame(buildUs: 12000, rasterUs: 9000),
    ], budgetMs: 8.3);
    final jank = trace.lines.where((l) => l.contains('[jank]')).toList();
    expect(jank, hasLength(1));
    expect(jank.single, contains('21.0 мс'));
    expect(jank.single, contains('ChatScreen'));
  });

  test('сводка считает кадры, рывки и счётчики', () {
    trace.setEnabled(true);
    trace.count('стекло.нативное', 3);
    trace.handleTimings([
      _frame(buildUs: 2000, rasterUs: 2000),
      _frame(buildUs: 30000, rasterUs: 1000),
    ], budgetMs: 16.7);
    trace.debugFlushSummary();
    final summary = trace.lines.lastWhere((l) => l.contains('[fps]'));
    expect(summary, contains('кадров 2'));
    expect(summary, contains('с рывком 1'));
    expect(summary, contains('стекло.нативное=3'));
  });

  test('отрезок меряет длительность и рывки внутри себя', () {
    trace.setEnabled(true);
    trace.beginSpan('смена вкладки');
    trace.handleTimings([
      _frame(buildUs: 30000, rasterUs: 1000),
    ], budgetMs: 16.7);
    trace.endSpan('смена вкладки');
    final end = trace.lines.lastWhere((l) => l.contains('■'));
    expect(end, contains('смена вкладки'));
    expect(end, contains('кадров 1'));
    expect(end, contains('с рывком 1'));
  });

  test('журнал ограничен и помечает обрезку при выгрузке', () {
    trace.setEnabled(true);
    for (var i = 0; i < PerfTrace.maxLines + 10; i++) {
      trace.event('nav', 'событие $i');
    }
    expect(trace.lines, hasLength(PerfTrace.maxLines));
    expect(trace.export(), contains('старые обрезаны'));
  });

  testWidgets('прыжок прокрутки без жеста попадает в журнал', (tester) async {
    trace.setEnabled(true);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: PerfScrollProbe(
          tag: 'список',
          child: ListView.builder(
            controller: controller,
            itemCount: 200,
            itemBuilder: (context, i) =>
                SizedBox(height: 60, child: Text('$i')),
          ),
        ),
      ),
    );
    controller.jumpTo(3000);
    await tester.pump();
    expect(
      trace.lines.where((l) => l.contains('[jump]') && l.contains('список')),
      isNotEmpty,
    );
  });

  testWidgets('обычная прокрутка пальцем не считается прыжком', (tester) async {
    trace.setEnabled(true);
    await tester.pumpWidget(
      MaterialApp(
        home: PerfScrollProbe(
          tag: 'список',
          child: ListView.builder(
            itemCount: 200,
            itemBuilder: (context, i) =>
                SizedBox(height: 60, child: Text('$i')),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    expect(trace.lines.where((l) => l.contains('[jump]')), isEmpty);
  });
}
