import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

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

  /// Default interactive spring (hero-ish settle, general UI).
  static final SpringDescription standard = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 32,
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
  static const Duration chrome = Duration(milliseconds: 200);
  static const Duration heroOpen = Duration(milliseconds: 320);
  static const Duration heroClose = Duration(milliseconds: 280);

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
    return offset.abs() > distanceThreshold ||
        velocityY.abs() > dismissFlingVelocity;
  }
}

/// Drives [controller] with a [SpringSimulation] toward [target].
///
/// [velocity] is in units of the controller value per second (same space as
/// the animation value). Returns the [TickerFuture] from [animateWith].
TickerFuture animateSpring(
  AnimationController controller, {
  required double target,
  SpringDescription? spring,
  double velocity = 0,
}) {
  final simulation = SpringSimulation(
    spring ?? IosMotion.standard,
    controller.value,
    target,
    velocity,
  );
  return controller.animateWith(simulation);
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
