import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'ios_motion.dart';

/// Tracks interactive vertical dismiss for a fullscreen media viewer.
///
/// Drive visuals with [Listenable] listeners / [AnimatedBuilder]; avoid
/// rebuilding the pager subtree during the drag.
class GalleryDismissController extends ChangeNotifier {
  GalleryDismissController({required TickerProvider vsync})
    : _anim = AnimationController.unbounded(vsync: vsync, value: 0) {
    _anim.addListener(_onAnimTick);
  }

  final AnimationController _anim;
  double _viewportHeight = 800;
  bool _dragging = false;
  bool _committing = false;
  double _gestureVelocityY = 0;
  bool _crossedThreshold = false;

  AnimationController get animation => _anim;

  /// Signed pixel offset of the media (positive = down).
  double get offset => _anim.value;

  /// Last gesture velocity from [onDragEnd] (px/s). Prefer this over
  /// [animation.velocity] after a manual drag, which is typically ~0.
  double get gestureVelocityY => _gestureVelocityY;

  bool get isDragging => _dragging;
  bool get isCommitting => _committing;
  bool get isActive =>
      _dragging || _anim.value.abs() > 0.5 || _anim.isAnimating;

  void updateViewportHeight(double height) {
    if (height > 0) _viewportHeight = height;
  }

  double get _dimFull => IosMotion.dismissDimPixels;
  double get _chromeFull => IosMotion.dismissChromePixels;

  /// 0 at rest, 1 when fully dimmed.
  double get dimProgress => IosMotion.progress(offset, _dimFull);

  /// 0 at rest, 1 when chrome should be gone.
  double get chromeProgress => IosMotion.progress(offset, _chromeFull);

  /// Background opacity multiplier (1 = opaque black).
  double get backgroundOpacity => (1.0 - dimProgress).clamp(0.0, 1.0);

  /// Media scale while dragging (shrinks slightly with distance).
  double get mediaScale {
    final t = IosMotion.progress(offset, _dimFull);
    return (1.0 - IosMotion.dismissScaleLoss * t).clamp(
      IosMotion.dismissMinScale,
      1.0,
    );
  }

  void onDragStart() {
    if (_committing) return;
    _anim.stop();
    _dragging = true;
    _crossedThreshold = false;
    notifyListeners();
  }

  /// Returns true once when the commit distance threshold is first crossed.
  bool onDragUpdate(double deltaY) {
    if (_committing) return false;
    if (!_dragging) onDragStart();
    _anim.value = _anim.value + deltaY;
    notifyListeners();
    final threshold = _viewportHeight / IosMotion.dismissDistanceDivisor;
    final crossed = _anim.value.abs() > threshold;
    if (crossed && !_crossedThreshold) {
      _crossedThreshold = true;
      return true;
    }
    if (!crossed) _crossedThreshold = false;
    return false;
  }

  /// Returns true if dismiss was committed (caller should pop / fly away).
  bool onDragEnd(double velocityY) {
    if (_committing) return false;
    _dragging = false;
    _gestureVelocityY = velocityY;
    final commit = IosMotion.shouldCommitDismiss(
      offset: _anim.value,
      velocityY: velocityY,
      viewportHeight: _viewportHeight,
    );
    if (commit) {
      _committing = true;
      notifyListeners();
      return true;
    }
    _snapBack(velocityY);
    return false;
  }

  void onDragCancel() {
    if (_committing) return;
    _dragging = false;
    _gestureVelocityY = 0;
    _snapBack(0);
  }

  void _snapBack(double velocityY) {
    final simulation = SpringSimulation(
      IosMotion.dismissSnap,
      _anim.value,
      0,
      velocityY,
    );
    _anim.animateWith(simulation).whenComplete(() {
      if (!_anim.isAnimating && !_dragging) {
        _anim.value = 0;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  /// Instantly reset to rest (Reduce Motion snap-back).
  void snapBackImmediate() {
    _anim.stop();
    _anim.value = 0;
    _dragging = false;
    notifyListeners();
  }

  /// Continue off-screen with [velocityY] (px/s), then invoke [onDone].
  Future<void> flyOff({
    required VoidCallback onDone,
    double? velocityY,
    bool reduceMotion = false,
  }) async {
    _committing = true;
    notifyListeners();
    final v = velocityY ?? _gestureVelocityY;
    final direction = offset == 0
        ? (v == 0 ? 1.0 : v.sign)
        : offset.sign;
    final target = direction * _viewportHeight * 1.15;
    if (reduceMotion) {
      _anim.value = target;
      notifyListeners();
      onDone();
      return;
    }
    final simulation = SpringSimulation(
      IosMotion.soft,
      _anim.value,
      target,
      v,
    );
    await _anim.animateWith(simulation);
    onDone();
  }

  void reset() {
    _anim.stop();
    _anim.value = 0;
    _dragging = false;
    _committing = false;
    _gestureVelocityY = 0;
    _crossedThreshold = false;
    notifyListeners();
  }

  void _onAnimTick() => notifyListeners();

  @override
  void dispose() {
    _anim.removeListener(_onAnimTick);
    _anim.dispose();
    super.dispose();
  }
}

/// Vertical drag that wins only when motion is clearly vertical.
///
/// Used for media-viewer dismiss so horizontal paging and pinch-zoom can
/// still claim the pointer when appropriate.
class GalleryDismissDragRecognizer extends VerticalDragGestureRecognizer {
  GalleryDismissDragRecognizer({required this.canStart, super.debugOwner});

  /// Called before accepting; return false to fail the gesture (e.g. zoomed).
  final ValueGetter<bool> canStart;

  Offset? _start;
  bool _validated = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (!canStart()) {
      return;
    }
    _start = event.position;
    _validated = false;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent && _start != null && !_validated) {
      final delta = event.position - _start!;
      final adx = delta.dx.abs();
      final ady = delta.dy.abs();
      if (adx > kTouchSlop && adx > ady * IosMotion.dismissAxisRatio) {
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(event.pointer);
        return;
      }
      if (ady > kTouchSlop && ady > adx * IosMotion.dismissAxisRatio) {
        _validated = true;
      }
    }
    super.handleEvent(event);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _start = null;
    _validated = false;
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    _start = null;
    _validated = false;
    super.rejectGesture(pointer);
  }
}
