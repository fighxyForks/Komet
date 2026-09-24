import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class PerfTrace with WidgetsBindingObserver {
  PerfTrace._();

  static final PerfTrace instance = PerfTrace._();

  static const int maxLines = 6000;
  static const int maxFrames = 1200;
  static const Duration summaryPeriod = Duration(seconds: 5);
  static const Duration spanTimeout = Duration(seconds: 3);

  final ListQueue<String> _lines = ListQueue<String>();
  final ListQueue<_FrameRecord> _recentFrames = ListQueue<_FrameRecord>();
  final Map<String, int> _counters = {};
  final Map<String, _Span> _openSpans = {};
  final List<_Span> _closedSpans = [];
  bool _enabled = false;
  bool _truncated = false;
  int _frames = 0;
  int _janky = 0;
  int _stalls = 0;
  double _worstMs = 0;
  DateTime _windowStart = DateTime.now();
  String _route = '-';
  int _latestVsyncUs = 0;
  _WindowSnapshot? _window;

  @visibleForTesting
  int Function() frameClockUs = () =>
      SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;

  @visibleForTesting
  ui.FlutterView? Function() viewProvider = () =>
      ui.PlatformDispatcher.instance.implicitView;

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
      _window = _WindowSnapshot.of(viewProvider());
      binding.addObserver(this);
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
      event('trace', 'включена, бюджет кадра ${_ms(frameBudgetMs())}');
    } else {
      event('trace', 'выключена');
      binding.removeObserver(this);
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
      _openSpans.clear();
      _closedSpans.clear();
      _recentFrames.clear();
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
    _openSpans[name] = _Span(name, DateTime.now(), frameClockUs());
    _write('span', '▶ $name${detail.isEmpty ? '' : ' $detail'}');
  }

  void endSpan(String name) {
    if (!_enabled) return;
    final span = _openSpans.remove(name);
    if (span == null) return;
    span
      ..endWall = DateTime.now()
      ..endUs = frameClockUs();
    _closedSpans.add(span);
    _settleSpans(force: false);
  }

  void endSpansStartingWith(String prefix) {
    for (final name in _openSpans.keys.toList()) {
      if (name.startsWith(prefix)) endSpan(name);
    }
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
    _trackAnimation(
      'переход ${describeRoute(route)}',
      '$verb от ${describeRoute(previous)}',
      route,
      AnimationStatus.completed,
    );
  }

  void routeClosed(Route<dynamic> route, Route<dynamic>? previous) {
    if (route is PopupRoute) return;
    setRoute(describeRoute(previous));
    _trackAnimation(
      'закрытие ${describeRoute(route)}',
      '→ ${describeRoute(previous)}',
      route,
      AnimationStatus.dismissed,
    );
  }

  void _trackAnimation(
    String span,
    String detail,
    Route<dynamic> route,
    AnimationStatus target,
  ) {
    if (!_enabled) return;
    final animation = route is TransitionRoute ? route.animation : null;
    beginSpan(
      span,
      detail: '$detail (анимация: ${animation?.status.name ?? 'нет'})',
    );
    if (animation == null || animation.status == target) {
      endSpan(span);
      return;
    }
    void listener(AnimationStatus status) {
      if (status != target) return;
      animation.removeStatusListener(listener);
      endSpan(span);
    }

    animation.addStatusListener(listener);
  }

  void handleTimings(List<ui.FrameTiming> timings, {double? budgetMs}) {
    if (!_enabled) return;
    final budget = budgetMs ?? frameBudgetMs();
    for (final timing in timings) {
      final buildMs = timing.buildDuration.inMicroseconds / 1000;
      final rasterMs = timing.rasterDuration.inMicroseconds / 1000;
      final worst = math.max(buildMs, rasterMs);
      final janky = worst > budget;
      final vsync = timing.timestampInMicroseconds(ui.FramePhase.vsyncStart);
      final startDelayMs =
          (timing.timestampInMicroseconds(ui.FramePhase.buildStart) - vsync) /
          1000;
      if (vsync > _latestVsyncUs) _latestVsyncUs = vsync;
      _recentFrames.add(_FrameRecord(vsync, janky));
      while (_recentFrames.length > maxFrames) {
        _recentFrames.removeFirst();
      }
      _frames++;
      if (worst > _worstMs) _worstMs = worst;
      if (startDelayMs > budget) {
        _stalls++;
        _write(
          'stall',
          'сборка началась через ${_ms(startDelayMs)} после кадра '
              '(главный поток занят), экран $_route${_openSpanNames()}',
        );
      }
      if (!janky) continue;
      _janky++;
      _write(
        'jank',
        'сборка ${_ms(buildMs)}, растр ${_ms(rasterMs)} '
            'экран $_route${_openSpanNames()}',
      );
    }
    _settleSpans(force: false);
    _maybeSummarize();
  }

  String export() {
    _settleSpans(force: true);
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
    _latestVsyncUs = 0;
    _window = null;
    frameClockUs = () =>
        SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
    viewProvider = () => ui.PlatformDispatcher.instance.implicitView;
    _resetWindow();
  }

  @visibleForTesting
  void debugFlushSummary() => _summarize();

  @visibleForTesting
  void debugSettleSpans() => _settleSpans(force: true);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    event('app', 'состояние ${state.name}');
  }

  @override
  void didHaveMemoryPressure() {
    event('app', 'нехватка памяти');
  }

  @override
  void didChangeMetrics() => handleMetricsChanged();

  @visibleForTesting
  void handleMetricsChanged() {
    if (!_enabled) return;
    final next = _WindowSnapshot.of(viewProvider());
    final previous = _window;
    _window = next;
    if (next == null || previous == null) return;
    final changes = next.diff(previous);
    if (changes.isEmpty) {
      count('окно.без изменений');
      return;
    }
    count('окно.изменения');
    _write('window', changes.join(', '));
  }

  void _onTimings(List<ui.FrameTiming> timings) => handleTimings(timings);

  void _settleSpans({required bool force}) {
    if (_closedSpans.isEmpty) return;
    final now = DateTime.now();
    _closedSpans.removeWhere((span) {
      final covered = _latestVsyncUs > span.endUs;
      final timedOut = now.difference(span.endWall!) > spanTimeout;
      if (!force && !covered && !timedOut) return false;
      var frames = 0;
      var janky = 0;
      for (final frame in _recentFrames) {
        if (frame.vsyncUs <= span.startUs || frame.vsyncUs > span.endUs) {
          continue;
        }
        frames++;
        if (frame.janky) janky++;
      }
      final ms = span.endWall!.difference(span.start).inMicroseconds / 1000;
      _write(
        'span',
        '■ ${span.name} ${_ms(ms)}, кадров $frames, с рывком $janky'
            '${covered ? '' : ' (кадры ещё не пришли)'}',
      );
      return true;
    });
  }

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
      'кадров $_frames, с рывком $_janky, худший ${_ms(_worstMs)}, '
          'задержек старта $_stalls'
          '${counters.isEmpty ? '' : ' · ${counters.join(', ')}'}',
    );
    _resetWindow();
  }

  void _resetWindow() {
    _windowStart = DateTime.now();
    _frames = 0;
    _janky = 0;
    _stalls = 0;
    _worstMs = 0;
    _counters.clear();
  }

  String _openSpanNames() =>
      _openSpans.isEmpty ? '' : ', идёт: ${_openSpans.keys.join(', ')}';

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
  final String name;
  final DateTime start;
  final int startUs;
  DateTime? endWall;
  int endUs = 0;

  _Span(this.name, this.start, this.startUs);
}

class _FrameRecord {
  final int vsyncUs;
  final bool janky;

  const _FrameRecord(this.vsyncUs, this.janky);
}

class _WindowSnapshot {
  final ui.Size size;
  final double ratio;
  final ui.ViewPadding padding;
  final ui.ViewPadding insets;

  const _WindowSnapshot(this.size, this.ratio, this.padding, this.insets);

  static _WindowSnapshot? of(ui.FlutterView? view) => view == null
      ? null
      : _WindowSnapshot(
          view.physicalSize,
          view.devicePixelRatio,
          view.padding,
          view.viewInsets,
        );

  List<String> diff(_WindowSnapshot previous) {
    String px(double v) => (v / ratio).toStringAsFixed(0);
    final changes = <String>[];
    if (size != previous.size) {
      changes.add(
        'размер ${px(previous.size.width)}×${px(previous.size.height)} → '
        '${px(size.width)}×${px(size.height)}',
      );
    }
    if (ratio != previous.ratio) {
      changes.add('плотность ${previous.ratio} → $ratio');
    }
    void edges(String label, ui.ViewPadding before, ui.ViewPadding after) {
      if (before.top != after.top) {
        changes.add('$label сверху ${px(before.top)} → ${px(after.top)}');
      }
      if (before.bottom != after.bottom) {
        changes.add('$label снизу ${px(before.bottom)} → ${px(after.bottom)}');
      }
      if (before.left != after.left || before.right != after.right) {
        changes.add('$label по бокам изменились');
      }
    }

    edges('отступы', previous.padding, padding);
    edges('клавиатура', previous.insets, insets);
    return changes;
  }
}

class PerfScrollProbe extends StatefulWidget {
  final String tag;
  final bool hidden;
  final Widget child;

  static const double jumpThreshold = 200;
  static const double extentJumpThreshold = 300;

  const PerfScrollProbe({
    super.key,
    required this.tag,
    required this.child,
    this.hidden = false,
  });

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
              'без жеста${widget.hidden ? ' (лента скрыта)' : ''}',
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
            '${extent.toStringAsFixed(0)} px'
            '${widget.hidden ? ' (лента скрыта)' : ''}',
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
