import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'ios_motion.dart';

final Expando<VoidCallback> _matrixSpringTicks = Expando<VoidCallback>();

/// Matrix that scales around a viewport focal point so that point stays put.
Matrix4 matrixForZoomAt({
  required Matrix4 current,
  required Offset focalViewport,
  required double targetScale,
}) {
  final currentScale = current.getMaxScaleOnAxis().clamp(0.01, 100.0);
  if ((currentScale - targetScale).abs() < 0.001) return current.clone();
  final sceneFocal = MatrixUtils.transformPoint(
    Matrix4.inverted(current),
    focalViewport,
  );
  return Matrix4.identity()
    ..translateByDouble(focalViewport.dx, focalViewport.dy, 0, 1)
    ..scaleByDouble(targetScale, targetScale, 1, 1)
    ..translateByDouble(-sceneFocal.dx, -sceneFocal.dy, 0, 1);
}

/// Clamps translation so content of [contentSize] at scale covers [viewport].
///
/// When content size is unknown, falls back to identity at fit scale.
Matrix4 clampPanToBounds({
  required Matrix4 matrix,
  required Size viewport,
  Size? contentSize,
}) {
  final scale = matrix.getMaxScaleOnAxis();
  if (scale <= 1.01) {
    return Matrix4.identity();
  }
  if (contentSize == null || contentSize.isEmpty || viewport.isEmpty) {
    return matrix;
  }
  final scaled = Size(contentSize.width * scale, contentSize.height * scale);
  final tx = matrix.storage[12];
  final ty = matrix.storage[13];

  late final double minX;
  late final double maxX;
  if (scaled.width <= viewport.width) {
    minX = maxX = (viewport.width - scaled.width) / 2;
  } else {
    minX = viewport.width - scaled.width;
    maxX = 0;
  }

  late final double minY;
  late final double maxY;
  if (scaled.height <= viewport.height) {
    minY = maxY = (viewport.height - scaled.height) / 2;
  } else {
    minY = viewport.height - scaled.height;
    maxY = 0;
  }

  final clampedX = tx.clamp(minX, maxX).toDouble();
  final clampedY = ty.clamp(minY, maxY).toDouble();
  if (clampedX == tx && clampedY == ty) return matrix;

  final out = matrix.clone();
  out.storage[12] = clampedX;
  out.storage[13] = clampedY;
  return out;
}

/// Soft-clamps scale into [minScale, softMax]; hard ceiling at [hardMax].
double rubberBandScale({
  required double scale,
  double minScale = 1,
  double softMax = IosMotion.zoomSoftMax,
  double hardMax = IosMotion.zoomHardMax,
}) {
  if (scale < minScale) {
    final overflow = minScale - scale;
    return minScale - math.min(overflow * 0.35, hardMax - softMax);
  }
  if (scale <= softMax) return scale;
  final overflow = scale - softMax;
  final band = hardMax - softMax;
  final banded =
      softMax + (1.0 - (1.0 / ((overflow * 0.5 / band) + 1.0))) * band;
  return math.min(banded, hardMax);
}

/// Animates [transform] from its current matrix to [target] via a spring on t.
TickerFuture animateMatrixSpring({
  required AnimationController controller,
  required TransformationController transform,
  required Matrix4 target,
  SpringDescription? spring,
  double velocity = 0,
}) {
  final from = transform.value.clone();
  final to = target.clone();
  void tick() {
    final t = controller.value.clamp(0.0, 1.0);
    transform.value = _lerpMatrix(from, to, t);
  }

  final previous = _matrixSpringTicks[controller];
  if (previous != null) controller.removeListener(previous);
  _matrixSpringTicks[controller] = null;
  controller
    ..stop()
    ..value = 0;
  _matrixSpringTicks[controller] = tick;
  controller.addListener(tick);
  final future = animateSpring(
    controller,
    target: 1,
    spring: spring ?? IosMotion.standard,
    velocity: velocity,
  );
  future.whenCompleteOrCancel(() {
    if (!identical(_matrixSpringTicks[controller], tick)) return;
    controller.removeListener(tick);
    _matrixSpringTicks[controller] = null;
    if (controller.value >= 0.999) transform.value = to;
  });
  return future;
}

Matrix4 _lerpMatrix(Matrix4 a, Matrix4 b, double t) {
  final out = Matrix4.zero();
  for (var i = 0; i < 16; i++) {
    out.storage[i] = a.storage[i] + (b.storage[i] - a.storage[i]) * t;
  }
  return out;
}
