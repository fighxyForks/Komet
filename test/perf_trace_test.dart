import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/utils/perf_trace.dart';

ui.FrameTiming _frame({
  required int buildUs,
  required int rasterUs,
  int vsyncUs = 0,
}) => ui.FrameTiming(
  vsyncStart: vsyncUs,
  buildStart: vsyncUs,
  buildFinish: vsyncUs + buildUs,
  rasterStart: vsyncUs + buildUs,
  rasterFinish: vsyncUs + buildUs + rasterUs,
  rasterFinishWallTime: vsyncUs + buildUs + rasterUs,
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

  test('отрезок считает кадры по их времени, даже если они пришли позже', () {
    trace.setEnabled(true);
    var clock = 1000;
    trace.frameClockUs = () => clock;
    trace.beginSpan('смена вкладки');
    clock = 5000;
    trace.endSpan('смена вкладки');
    expect(trace.lines.where((l) => l.contains('■')), isEmpty);
    trace.handleTimings([
      _frame(buildUs: 1000, rasterUs: 1000, vsyncUs: 500),
      _frame(buildUs: 30000, rasterUs: 1000, vsyncUs: 2000),
      _frame(buildUs: 1000, rasterUs: 1000, vsyncUs: 4000),
      _frame(buildUs: 1000, rasterUs: 1000, vsyncUs: 6000),
    ], budgetMs: 16.7);
    final end = trace.lines.lastWhere((l) => l.contains('■'));
    expect(end, contains('смена вкладки'));
    expect(end, contains('кадров 2'));
    expect(end, contains('с рывком 1'));
  });

  test('сводка посреди отрезка не портит его счёт', () {
    trace.setEnabled(true);
    var clock = 0;
    trace.frameClockUs = () => clock;
    trace.beginSpan('переход');
    trace.handleTimings([
      _frame(buildUs: 1000, rasterUs: 1000, vsyncUs: 100),
    ], budgetMs: 16.7);
    trace.debugFlushSummary();
    trace.handleTimings([
      _frame(buildUs: 1000, rasterUs: 1000, vsyncUs: 200),
    ], budgetMs: 16.7);
    clock = 300;
    trace.endSpan('переход');
    trace.handleTimings([
      _frame(buildUs: 1000, rasterUs: 1000, vsyncUs: 400),
    ], budgetMs: 16.7);
    final end = trace.lines.lastWhere((l) => l.contains('■'));
    expect(end, contains('кадров 2'));
  });

  test('незакрытые кадрами отрезки выгружаются с пометкой', () {
    trace.setEnabled(true);
    trace.frameClockUs = () => 0;
    trace.beginSpan('переход');
    trace.endSpan('переход');
    trace.debugSettleSpans();
    expect(
      trace.lines.lastWhere((l) => l.contains('■')),
      contains('кадры ещё не пришли'),
    );
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

  testWidgets('переход экрана длится до конца анимации, а не 0 мс', (
    tester,
  ) async {
    trace.setEnabled(true);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [_TraceObserver()],
        home: const SizedBox(),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const SizedBox()),
    );
    await tester.pump();
    expect(trace.lines.where((l) => l.contains('■ переход')), isEmpty);
    await tester.pumpAndSettle();
    trace.debugSettleSpans();
    final end = trace.lines.lastWhere((l) => l.contains('■ переход'));
    expect(end, isNot(contains(' 0.0 мс')));
  });

  testWidgets('изменения окна пишутся по полям, пустые — только счётчиком', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    trace.viewProvider = () => tester.view;
    trace.setEnabled(true);
    trace.handleMetricsChanged();
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    trace.handleMetricsChanged();
    final window = trace.lines.where((l) => l.contains('[window]')).toList();
    expect(window, hasLength(1));
    expect(window.single, contains('клавиатура снизу 0 → 300'));
    trace.debugFlushSummary();
    expect(
      trace.lines.lastWhere((l) => l.contains('[fps]')),
      contains('окно.без изменений='),
    );
  });
}

class _TraceObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    PerfTrace.instance.routeShown('открыт', route, previousRoute);
  }
}
