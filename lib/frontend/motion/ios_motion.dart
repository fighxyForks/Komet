import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Shared spring presets and gesture thresholds for interactive motion.
///
/// Values are behavioral targets for an iOS-like feel; they are not copied
/// from any third-party source.
abstract final class IosMotion {
  /// Soft overdamped spring for underlay / push-style motion.
  static final SpringDescription soft = SpringDescription(
    mass: 1,
    stiffness: 280,
    damping: 40,
  );

  /// Default interactive spring (zoom settle, general UI).
  static final SpringDescription standard = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 32,
  );

  /// Critically damped hero open/close flight (~0.3–0.35s settle).
  static final SpringDescription hero = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 380,
    ratio: 1.0,
  );

  /// Overlay / menu appear (critically damped, slightly softer than hero).
  static final SpringDescription overlay = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 280,
    ratio: 1.0,
  );

  /// Snappier spring for dismiss snap-back to rest.
  static final SpringDescription dismissSnap = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 36,
  );

  /// Light bounce for lift / press release.
  static final SpringDescription bounce = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 22,
  );

  /// Chat-list style press (matches existing SpringyTap feel).
  static final SpringDescription press = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 350,
    ratio: 0.8,
  );

  /// Preview / overlay grow (matches ChatPreviewOverlay).
  static final SpringDescription preview = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 230,
    ratio: 1,
  );

  static const Duration dimIn = Duration(milliseconds: 150);
  static const Duration dimOut = Duration(milliseconds: 100);
  static const Duration chrome = Duration(milliseconds: 200);
  static const Duration heroOpen = Duration(milliseconds: 400);
  static const Duration heroClose = Duration(milliseconds: 400);
  static const Duration flyOff = Duration(milliseconds: 200);
  static const Duration overlayForward = Duration(milliseconds: 420);
  static const Duration overlayReverse = Duration(milliseconds: 280);

  /// Short cross-fade for page / sheet transitions under Reduce Motion.
  static const Duration pageCrossFade = Duration(milliseconds: 200);

  /// Soft max scale for media zoom (pinch / double-tap target band).
  static const double zoomSoftMax = 3.0;

  /// Hard max during pinch; rubber-bands back to [zoomSoftMax] on release.
  static const double zoomHardMax = 3.6;

  /// Double-tap zoom factor when currently at fit.
  static const double doubleTapZoomScale = 2.75;

  /// Edge inset where double-tap is ignored (chrome-only single tap).
  static const double doubleTapEdgeInset = 44;

  /// Deferred single-tap window so a second tap can claim double-tap zoom
  /// without waiting for Flutter's full double-tap timeout. Applied only when
  /// double-tap zoom is possible (zoomable image, not Reduce Motion, not edge).
  static const Duration singleTapDelay = Duration(milliseconds: 200);

  /// Visual gap between gallery pages (logical pixels).
  static const double galleryPageGap = 20;

  /// Swipe-to-reply trigger distances (incoming / outgoing).
  static const double replyTriggerIncoming = 48;
  static const double replyTriggerOutgoing = 60;

  /// Visual drag cap for swipe-to-reply (before rubber-band).
  static const double replyBandingStart = 60;
  static const double replyMaxVisual = 120;

  /// Commit dismiss when |offset| exceeds height / this divisor.
  static const double dismissDistanceDivisor = 12;

  /// Commit dismiss when |vertical velocity| exceeds this (px/s).
  static const double dismissFlingVelocity = 1000;

  /// Background alpha falls to 0 across this many pixels of drag.
  static const double dismissDimPixels = 80;

  /// Chrome alpha falls to 0 across this many pixels of drag.
  static const double dismissChromePixels = 50;

  /// Media scales down by this fraction at full dim distance.
  static const double dismissScaleLoss = 0.12;

  /// Minimum scale while dragging to dismiss.
  static const double dismissMinScale = 0.88;

  /// Axis lock: vertical must dominate horizontal by this factor.
  static const double dismissAxisRatio = 1.5;

  /// Whether the platform accessibility setting asks to reduce motion.
  static bool reduceMotionOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Rubber-band after [bandingStart]; asymptotic range and strength.
  static double rubberBand({
    required double offset,
    required double bandingStart,
    double range = 100,
    double coefficient = 0.4,
  }) {
    final abs = offset.abs();
    final sign = offset < 0 ? -1.0 : 1.0;
    if (abs <= bandingStart) return offset;
    final banded = abs - bandingStart;
    final eased =
        bandingStart +
        (1.0 - (1.0 / ((banded * coefficient / range) + 1.0))) * range;
    return eased * sign;
  }

  /// Normalized progress 0..1 for a drag distance.
  static double progress(double distance, double full) {
    if (full <= 0) return 0;
    return (distance.abs() / full).clamp(0.0, 1.0);
  }

  /// Whether a vertical dismiss gesture should commit.
  static bool shouldCommitDismiss({
    required double offset,
    required double velocityY,
    required double viewportHeight,
  }) {
    final distanceThreshold = viewportHeight / dismissDistanceDivisor;
    if (velocityY.abs() > dismissFlingVelocity) {
      return offset == 0 || offset.sign == velocityY.sign;
    }
    return offset.abs() > distanceThreshold;
  }
}

/// Drives [controller] with a [SpringSimulation] toward [target].
///
/// [velocity] is in units of the controller value per second (same space as
/// the animation value). Returns the [TickerFuture] from [animateWith].
/// Re-entrant: stopping a mid-flight spring and calling again preserves the
/// controller's current value; pass [velocity] (often `controller.velocity`)
/// to keep momentum when reversing.
TickerFuture animateSpring(
  AnimationController controller, {
  required double target,
  SpringDescription? spring,
  double velocity = 0,
}) {
  return controller.animateWith(
    SettlingSpringSimulation(
      spring ?? IosMotion.standard,
      controller.value,
      target,
      velocity,
    ),
  );
}

/// Maps a pixel-space fling into controller-value velocity.
///
/// [pixelsPerSecond] is the gesture velocity; [spanPixels] is how many pixels
/// correspond to a controller delta of 1.0 (e.g. viewport height).
double springVelocityFromPixels({
  required double pixelsPerSecond,
  required double spanPixels,
}) {
  if (spanPixels.abs() < 1e-6) return 0;
  return pixelsPerSecond / spanPixels;
}

/// Simulation that snaps to [value] immediately (Reduce Motion).
final class SnapSimulation extends Simulation {
  SnapSimulation(this._value);

  final double _value;

  @override
  double x(double time) => _value;

  @override
  double dx(double time) => 0;

  @override
  bool isDone(double time) => true;
}

/// [SpringSimulation] that snaps exactly to [end] once settled.
final class SettlingSpringSimulation extends Simulation {
  SettlingSpringSimulation(
    SpringDescription spring,
    double start,
    this._end,
    double velocity, {
    Tolerance tolerance = Tolerance.defaultTolerance,
  }) : _inner = SpringSimulation(spring, start, _end, velocity, tolerance: tolerance);

  final double _end;
  final SpringSimulation _inner;

  @override
  double x(double time) => _inner.isDone(time) ? _end : _inner.x(time);

  @override
  double dx(double time) => _inner.isDone(time) ? 0 : _inner.dx(time);

  @override
  bool isDone(double time) => _inner.isDone(time);
}
