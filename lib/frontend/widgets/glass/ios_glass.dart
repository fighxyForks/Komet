import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../../../core/config/app_ios_glass.dart';
import '../../../core/utils/perf_trace.dart';

class IosGlass extends InheritedNotifier<ValueNotifier<bool>> {
  IosGlass({super.key, required super.child})
    : super(notifier: AppIosGlass.active);

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<IosGlass>()?.notifier?.value ??
      AppIosGlass.active.value;
}

class IosType {
  static const FontWeight largeTitle = FontWeight.w700;
  static const FontWeight title = FontWeight.w600;
  static const FontWeight name = FontWeight.w500;
  static const FontWeight body = FontWeight.w400;
}

class GlassSuppression {
  static final ValueNotifier<int> count = ValueNotifier<int>(0);

  static VoidCallback hold() {
    count.value++;
    PerfTrace.instance.event('glass', 'подавление вкл (${count.value})');
    if (count.value == 1 && NativeLiquidGlassUtils.supportsLiquidGlass) {
      unawaited(_invoke(NativeLiquidGlassLifecycle.suppressGlassEffects));
    }
    var released = false;
    return () {
      if (released) return;
      released = true;
      count.value--;
      PerfTrace.instance.event('glass', 'подавление выкл (${count.value})');
      if (count.value == 0 && NativeLiquidGlassUtils.supportsLiquidGlass) {
        unawaited(_invoke(NativeLiquidGlassLifecycle.unsuppressGlassEffects));
      }
    };
  }

  static Future<T> during<T>(Future<T> Function() body) async {
    final release = hold();
    try {
      return await body();
    } finally {
      release();
    }
  }

  static Future<void> _invoke(Future<void> Function() call) async {
    try {
      await call();
    } on MissingPluginException {
      debugPrint('Liquid glass lifecycle channel unavailable');
    } on PlatformException catch (error) {
      debugPrint('Liquid glass lifecycle: ${error.code}');
    }
  }
}

class NativeGlassScope extends InheritedWidget {
  final bool enabled;

  const NativeGlassScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NativeGlassScope>()?.enabled ??
      true;

  @override
  bool updateShouldNotify(NativeGlassScope oldWidget) =>
      oldWidget.enabled != enabled;
}

class NativeGlassGate extends StatefulWidget {
  final Widget Function(BuildContext context, bool useNative) builder;
  final String? label;

  const NativeGlassGate({super.key, required this.builder, this.label});

  @override
  State<NativeGlassGate> createState() => _NativeGlassGateState();
}

class _NativeGlassGateState extends State<NativeGlassGate> {
  bool? _lastNative;

  static bool routeSettled(ModalRoute<dynamic>? route) =>
      (route?.isCurrent ?? true) &&
      (route?.animation == null || route!.animation!.isCompleted) &&
      (route?.secondaryAnimation?.value ?? 0) == 0;

  String? _fallbackReason(BuildContext context, ModalRoute<dynamic>? route) {
    if (_lastNative != true && !routeSettled(route)) {
      return 'анимация перехода';
    }
    if (GlassSuppression.count.value > 0) return 'подавление';
    if (!NativeGlassScope.of(context)) return 'движение панели';
    if (MediaQuery.highContrastOf(context)) return 'повышенный контраст';
    if (MediaQuery.disableAnimationsOf(context)) return 'уменьшение движения';
    return null;
  }

  Widget _resolve(BuildContext context, bool useNative, String? reason) {
    final trace = PerfTrace.instance;
    if (trace.enabled) {
      trace.count(useNative ? 'стекло.нативное' : 'стекло.flutter');
      final last = _lastNative;
      if (last != null && last != useNative) {
        trace.event(
          'glass',
          '${widget.label ?? 'капсула'}: '
              '${useNative ? 'Flutter → нативное' : 'нативное → Flutter'}'
              '${reason == null ? '' : ' ($reason)'}',
        );
      }
    }
    _lastNative = useNative;
    return widget.builder(context, useNative);
  }

  @override
  Widget build(BuildContext context) {
    if (!IosGlass.of(context) || !AppIosGlass.nativeViews) {
      return widget.builder(context, false);
    }
    final route = ModalRoute.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        GlassSuppression.count,
        if (route?.animation != null) route!.animation!,
        if (route?.secondaryAnimation != null) route!.secondaryAnimation!,
      ]),
      builder: (context, _) {
        final reason = _fallbackReason(context, route);
        return _resolve(context, reason == null, reason);
      },
    );
  }
}

class IosGlassAppearance extends StatefulWidget {
  final Widget child;

  const IosGlassAppearance({super.key, required this.child});

  @override
  State<IosGlassAppearance> createState() => _IosGlassAppearanceState();
}

class _IosGlassAppearanceState extends State<IosGlassAppearance> {
  static const _channel = MethodChannel('ru.komet.app/appearance');
  String? _sent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    if (!NativeLiquidGlassUtils.supportsLiquidGlass) return;
    final appearance = IosGlass.of(context)
        ? Theme.of(context).brightness.name
        : 'system';
    if (appearance == _sent) return;
    _sent = appearance;
    unawaited(_send(appearance));
  }

  Future<void> _send(String appearance) async {
    try {
      await _channel.invokeMethod<void>('setBrightness', appearance);
    } on MissingPluginException {
      debugPrint('Appearance channel unavailable');
    } on PlatformException catch (error) {
      debugPrint('Appearance channel: ${error.code}');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
