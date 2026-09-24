import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../motion/ios_motion.dart';
import 'ios_glass.dart';

/// Adaptive page route: Cupertino (with Reduce Motion cross-fade) in iOS mode,
/// [MaterialPageRoute] otherwise.
Route<T> iosPageRoute<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool fullscreenDialog = false,
  bool maintainState = true,
  bool allowSnapshotting = true,
}) {
  if (IosGlass.of(context)) {
    return IosCupertinoPageRoute<T>(
      builder: builder,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
      allowSnapshotting: allowSnapshotting,
      reduceMotion: IosMotion.reduceMotionOf(context),
    );
  }
  return MaterialPageRoute<T>(
    builder: builder,
    settings: settings,
    fullscreenDialog: fullscreenDialog,
    maintainState: maintainState,
    allowSnapshotting: allowSnapshotting,
  );
}

/// Push with [iosPageRoute].
Future<T?> iosPush<T extends Object?>(
  BuildContext context,
  WidgetBuilder builder, {
  RouteSettings? settings,
  bool fullscreenDialog = false,
  bool maintainState = true,
  bool rootNavigator = false,
}) {
  return Navigator.of(context, rootNavigator: rootNavigator).push<T>(
    iosPageRoute<T>(
      context,
      builder: builder,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
    ),
  );
}

/// [CupertinoPageRoute] that cross-fades under Reduce Motion (no parallax).
///
/// Edge back-swipe still drives the route controller interactively; the
/// transition maps drag progress to opacity instead of a horizontal slide.
class IosCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  IosCupertinoPageRoute({
    required super.builder,
    required this.reduceMotion,
    super.settings,
    super.fullscreenDialog,
    super.maintainState,
    super.allowSnapshotting,
  });

  final bool reduceMotion;

  @override
  Duration get transitionDuration =>
      reduceMotion ? IosMotion.pageCrossFade : super.transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      reduceMotion ? IosMotion.pageCrossFade : super.reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition {
    if (reduceMotion) {
      return (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        bool allowSnapshotting,
        Widget? child,
      ) =>
          child;
    }
    return super.delegatedTransition;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!reduceMotion) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    final faded = FadeTransition(opacity: animation, child: child);
    if (fullscreenDialog) return faded;
    return _IosFadeBackGestureDetector<T>(
      enabledCallback: () => popGestureEnabled,
      onStartPopGesture: _startFadePopGesture,
      child: faded,
    );
  }

  _IosFadeBackGestureController<T> _startFadePopGesture() {
    assert(popGestureEnabled);
    return _IosFadeBackGestureController<T>(
      navigator: navigator!,
      controller: controller!,
      getIsCurrent: () => isCurrent,
      getIsActive: () => isActive,
    );
  }
}

const double _kBackGestureWidth = 20;
const double _kMinFlingVelocity = 1;
const Duration _kDroppedSwipe = Duration(milliseconds: 200);

class _IosFadeBackGestureDetector<T> extends StatefulWidget {
  const _IosFadeBackGestureDetector({
    required this.enabledCallback,
    required this.onStartPopGesture,
    required this.child,
  });

  final Widget child;
  final ValueGetter<bool> enabledCallback;
  final ValueGetter<_IosFadeBackGestureController<T>> onStartPopGesture;

  @override
  State<_IosFadeBackGestureDetector<T>> createState() =>
      _IosFadeBackGestureDetectorState<T>();
}

class _IosFadeBackGestureDetectorState<T>
    extends State<_IosFadeBackGestureDetector<T>> {
  _IosFadeBackGestureController<T>? _controller;
  late HorizontalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    if (_controller != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller?.navigator.mounted ?? false) {
          _controller?.navigator.didStopUserGesture();
        }
        _controller = null;
      });
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    assert(_controller == null);
    _controller = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    assert(_controller != null);
    final width = context.size?.width;
    if (width == null || width <= 0) return;
    _controller!.dragUpdate(_toLogical(details.primaryDelta! / width));
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    assert(_controller != null);
    final width = context.size?.width ?? 1;
    _controller!.dragEnd(
      _toLogical(details.velocity.pixelsPerSecond.dx / width),
    );
    _controller = null;
  }

  void _handleDragCancel() {
    assert(mounted);
    _controller?.dragEnd(0);
    _controller = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback()) {
      _recognizer.addPointer(event);
    }
  }

  double _toLogical(double value) {
    return switch (Directionality.of(context)) {
      TextDirection.rtl => -value,
      TextDirection.ltr => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    final dragAreaWidth = switch (Directionality.of(context)) {
      TextDirection.rtl => MediaQuery.paddingOf(context).right,
      TextDirection.ltr => MediaQuery.paddingOf(context).left,
    };
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          width: math.max(dragAreaWidth, _kBackGestureWidth),
          top: 0,
          bottom: 0,
          child: Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

class _IosFadeBackGestureController<T> {
  _IosFadeBackGestureController({
    required this.navigator,
    required this.controller,
    required this.getIsActive,
    required this.getIsCurrent,
  }) {
    navigator.didStartUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;
  final ValueGetter<bool> getIsActive;
  final ValueGetter<bool> getIsCurrent;

  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  void dragEnd(double velocity) {
    const curve = Curves.fastEaseInToSlowEaseOut;
    final isCurrent = getIsCurrent();
    final bool animateForward;
    if (!isCurrent) {
      animateForward = getIsActive();
    } else if (velocity.abs() >= _kMinFlingVelocity) {
      animateForward = velocity <= 0;
    } else {
      animateForward = controller.value > 0.5;
    }

    if (animateForward) {
      controller.animateTo(1, duration: _kDroppedSwipe, curve: curve);
    } else {
      if (isCurrent) {
        navigator.pop();
      }
      if (controller.isAnimating) {
        controller.animateBack(0, duration: _kDroppedSwipe, curve: curve);
      }
    }

    if (controller.isAnimating) {
      late AnimationStatusListener listener;
      listener = (status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          navigator.didStopUserGesture();
          controller.removeStatusListener(listener);
        }
      };
      controller.addStatusListener(listener);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
