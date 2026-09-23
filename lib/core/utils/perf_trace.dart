import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class PerfTrace with WidgetsBindingObserver {
  PerfTrace._();

  static final PerfTrace instance = PerfTrace._();

  static const int maxLines = 6000;
  static const Duration summaryPeriod = Duration(seconds: 5);

  final ListQueue<String> _lines = ListQueue<String>();
  final Map<String, int> _counters = {};
  bool _enabled = false;
  bool _truncated = false;
  int _frames = 0;
  int _janky = 0;
  double _worstMs = 0;
  DateTime _windowStart = DateTime.now();
  String _route = '-';
  final Map<String, _Span> _spans = {};

  bool get enabled => _enabled;

  List<String> get lines => List.unmodifiable(_lines);

  static double frameBudgetMs([double? refreshRate]) {
    final rate =
        refreshRate ??
        (ui.PlatformDispatcher.instance.displays.isEmpty
            ? 60.0
            : ui.PlatformDispatcher.instance.displays.first.refreshRate);
    return 1000 / (rate <= 0 ? 60 : rate);
  }

  void setEnabled(bool value) {
    if (value == _enabled) return;
    _enabled = value;
    final binding = WidgetsBinding.instance;
    if (value) {
      _resetWindow();
      binding.addObserver(this);
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
      event('trace', 'включена, бюджет кадра ${_ms(frameBudgetMs())}');
    } else {
      event('trace', 'выключена');
      binding.removeObserver(this);
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
      _spans.clear();
    }
  }

  void event(String category, String message) {
    if (!_enabled) return;
    _write(category, message);
  }

  void count(String counter, [int by = 1]) {
    if (!_enabled) return;
    _counters[counter] = (_counters[counter] ?? 0) + by;
  }

  void setRoute(String route) {
    _route = route;
  }

  void beginSpan(String name, {String detail = ''}) {
    if (!_enabled) return;
    _spans[name] = _Span(DateTime.now(), _frames, _janky);
    _write('span', '▶ $name${detail.isEmpty ? '' : ' $detail'}');
  }

  void endSpan(String name) {
    if (!_enabled) return;
    final span = _spans.remove(name);
    if (span == null) return;
    final ms = DateTime.now().difference(span.start).inMicroseconds / 1000;
    _write(
      'span',
      '■ $name ${_ms(ms)}, кадров ${_frames - span.frames}, '
          'с рывком ${_janky - span.janky}',
    );
  }

  static String describeRoute(Route<dynamic>? route) {
    if (route == null) return '-';
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) return name;
    return route.runtimeType.toString().split('<').first;
  }

  void routeShown(String verb, Route<dynamic> route, Route<dynamic>? previous) {
    if (route is PopupRoute) {
      event('route', 'всплывающее ${describeRoute(route)}');
      return;
    }
    setRoute(describeRoute(route));
    if (!_enabled) return;
    final span = 'переход ${describeRoute(route)}';
    beginSpan(span, detail: '$verb от ${describeRoute(previous)}');
    final animation = route is TransitionRoute ? route.animation : null;
    if (animation == null || animation.isCompleted || animation.isDismissed) {
      endSpan(span);
      return;
    }
    void listener(AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animation.removeStatusListener(listener);
        endSpan(span);
      }
    }

    animation.addStatusListener(listener);
  }

  void routeClosed(Route<dynamic> route, Route<dynamic>? previous) {
    if (route is PopupRoute) return;
    setRoute(describeRoute(previous));
    event(
      'route',
      'закрыт ${describeRoute(route)} → ${describeRoute(previous)}',
    );
  }

  void endSpansStartingWith(String prefix) {
    for (final name in _spans.keys.toList()) {
      if (name.startsWith(prefix)) endSpan(name);
    }
  }

  void handleTimings(List<ui.FrameTiming> timings, {double? budgetMs}) {
    if (!_enabled) return;
    final budget = budgetMs ?? frameBudgetMs();
    for (final timing in timings) {
      _frames++;
      final total = timing.totalSpan.inMicroseconds / 1000;
      if (total > _worstMs) _worstMs = total;
      if (total <= budget) continue;
      _janky++;
      _write(
        'jank',
        '${_ms(total)} (сборка ${_ms(timing.buildDuration.inMicroseconds / 1000)}, '
            'растр ${_ms(timing.rasterDuration.inMicroseconds / 1000)}) '
            'экран $_route${_openSpans()}',
      );
    }
    _maybeSummarize();
  }

  String export() {
    final buffer = StringBuffer()
      ..writeln('Komet — трассировка производительности')
      ..writeln(
        'Строк: ${_lines.length}${_truncated ? ' (старые обрезаны)' : ''}',
      )
      ..writeln();
    for (final line in _lines) {
      buffer.writeln(line);
    }
    return buffer.toString();
  }

  @visibleForTesting
  void debugReset() {
    setEnabled(false);
    _lines.clear();
    _counters.clear();
    _truncated = false;
    _route = '-';
    _resetWindow();
  }

  @visibleForTesting
  void debugFlushSummary() => _summarize();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    event('app', 'состояние ${state.name}');
  }

  @override
  void didHaveMemoryPressure() {
    event('app', 'нехватка памяти');
  }

  @override
  void didChangeMetrics() {
    event('app', 'изменились размеры окна');
  }

  void _onTimings(List<ui.FrameTiming> timings) => handleTimings(timings);

  void _maybeSummarize() {
    if (DateTime.now().difference(_windowStart) < summaryPeriod) return;
    _summarize();
  }

  void _summarize() {
    if (_frames == 0 && _counters.isEmpty) {
      _resetWindow();
      return;
    }
    final counters = _counters.entries.map((e) => '${e.key}=${e.value}');
    _write(
      'fps',
      'кадров $_frames, с рывком $_janky, худший ${_ms(_worstMs)}'
          '${counters.isEmpty ? '' : ' · ${counters.join(', ')}'}',
    );
    _resetWindow();
  }

  void _resetWindow() {
    _windowStart = DateTime.now();
    _frames = 0;
    _janky = 0;
    _worstMs = 0;
    _counters.clear();
  }

  String _openSpans() =>
      _spans.isEmpty ? '' : ', идёт: ${_spans.keys.join(', ')}';

  void _write(String category, String message) {
    _lines.add('${_clock(DateTime.now())} [$category] $message');
    while (_lines.length > maxLines) {
      _lines.removeFirst();
      _truncated = true;
    }
  }

  static String _ms(double ms) => '${ms.toStringAsFixed(1)} мс';

  static String _clock(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.'
        '${t.millisecond.toString().padLeft(3, '0')}';
  }
}

class _Span {
  final DateTime start;
  final int frames;
  final int janky;

  const _Span(this.start, this.frames, this.janky);
}

class PerfScrollProbe extends StatefulWidget {
  final String tag;
  final Widget child;

  static const double jumpThreshold = 200;
  static const double extentJumpThreshold = 300;

  const PerfScrollProbe({super.key, required this.tag, required this.child});

  @override
  State<PerfScrollProbe> createState() => _PerfScrollProbeState();
}

class _PerfScrollProbeState extends State<PerfScrollProbe> {
  double? _extent;

  bool _onScroll(ScrollNotification notification) {
    final trace = PerfTrace.instance;
    if (!trace.enabled) return false;
    if (notification is ScrollUpdateNotification &&
        notification.dragDetails == null) {
      final delta = notification.scrollDelta ?? 0;
      if (delta.abs() >= PerfScrollProbe.jumpThreshold) {
        trace.event(
          'jump',
          '${widget.tag}: прыжок прокрутки ${delta.toStringAsFixed(0)} px '
              'без жеста',
        );
      }
    }
    return false;
  }

  bool _onMetrics(ScrollMetricsNotification notification) {
    final trace = PerfTrace.instance;
    final extent = notification.metrics.maxScrollExtent;
    final previous = _extent;
    _extent = extent;
    if (!trace.enabled || previous == null) return false;
    if ((extent - previous).abs() >= PerfScrollProbe.extentJumpThreshold) {
      trace.event(
        'jump',
        '${widget.tag}: высота содержимого ${previous.toStringAsFixed(0)} → '
            '${extent.toStringAsFixed(0)} px',
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _onMetrics,
        child: widget.child,
      ),
    );
  }
}
