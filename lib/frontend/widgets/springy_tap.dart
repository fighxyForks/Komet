import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class SpringyTap extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  final bool enabled;

  const SpringyTap({
    super.key,
    required this.child,
    this.pressedScale = 0.98,
    this.enabled = true,
  });

  @override
  State<SpringyTap> createState() => _SpringyTapState();
}

class _SpringyTapState extends State<SpringyTap>
    with SingleTickerProviderStateMixin {
  static const Duration _pressDelay = Duration(milliseconds: 60);
  static const Duration _pressDuration = Duration(milliseconds: 90);
  static const Duration _settleDuration = Duration(milliseconds: 120);

  static final SpringDescription _spring = SpringDescription.withDampingRatio(
    ratio: 0.8,
    stiffness: 350,
    mass: 1,
  );

  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
    value: 1.0,
  );

  Timer? _pressTimer;
  Offset? _downPosition;
  bool _moved = false;

  @override
  void dispose() {
    _pressTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    _controller.stop();
    _controller.animateTo(
      widget.pressedScale,
      duration: _pressDuration,
      curve: Curves.easeOut,
    );
  }

  void _release() {
    if (_controller.value == 1.0 && !_controller.isAnimating) return;
    _controller.animateWith(
      SpringSimulation(_spring, _controller.value, 1.0, 1.5),
    );
  }

  Future<void> _pulse() async {
    _controller.stop();
    await _controller.animateTo(
      widget.pressedScale,
      duration: _pressDuration,
      curve: Curves.easeOut,
    );
    if (mounted) _release();
  }

  void _settle() {
    if (_controller.value == 1.0 && !_controller.isAnimating) return;
    _controller.stop();
    _controller.animateTo(
      1.0,
      duration: _settleDuration,
      curve: Curves.easeOut,
    );
  }

  void _onDown(PointerDownEvent event) {
    _pressTimer?.cancel();
    _downPosition = event.position;
    _moved = false;
    _pressTimer = Timer(_pressDelay, () {
      _pressTimer = null;
      _press();
    });
  }

  void _onMove(PointerMoveEvent event) {
    final origin = _downPosition;
    if (_moved || origin == null) return;
    if ((event.position - origin).distance <= kTouchSlop) return;
    _moved = true;
    _pressTimer?.cancel();
    _pressTimer = null;
    _settle();
  }

  void _onUp(PointerUpEvent _) {
    _downPosition = null;
    if (_moved) return;
    if (_pressTimer != null) {
      _pressTimer!.cancel();
      _pressTimer = null;
      unawaited(_pulse());
    } else {
      _release();
    }
  }

  void _onCancel(PointerCancelEvent _) {
    _downPosition = null;
    _pressTimer?.cancel();
    _pressTimer = null;
    _settle();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onCancel,
      child: ScaleTransition(scale: _controller, child: widget.child),
    );
  }
}
