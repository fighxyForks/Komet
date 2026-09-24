import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/motion/ios_motion.dart';
import 'package:komet/frontend/motion/zoom_transform.dart';

void main() {
  test('matrixForZoomAt scales around focal', () {
    final current = Matrix4.identity();
    final focal = const Offset(100, 200);
    final next = matrixForZoomAt(
      current: current,
      focalViewport: focal,
      targetScale: 2.75,
    );
    expect(next.getMaxScaleOnAxis(), closeTo(2.75, 0.001));
  });

  test('rubberBandScale softens past soft max', () {
    expect(rubberBandScale(scale: 2), 2);
    final banded = rubberBandScale(scale: 3.4);
    expect(banded, lessThan(IosMotion.zoomHardMax + 0.001));
    expect(banded, greaterThan(IosMotion.zoomSoftMax));
  });

  test('clampPanToBounds resets at fit scale', () {
    final m = Matrix4.identity()..translateByDouble(40, 40, 0, 1);
    // scale still 1
    final clamped = clampPanToBounds(
      matrix: m,
      viewport: const Size(400, 800),
      contentSize: const Size(400, 800),
    );
    expect(clamped.getMaxScaleOnAxis(), 1);
    expect(clamped.storage[12], 0);
  });

  testWidgets('animateMatrixSpring reaches target', (tester) async {
    final anim = AnimationController.unbounded(vsync: tester);
    final transform = TransformationController();
    addTearDown(anim.dispose);
    addTearDown(transform.dispose);
    final target = matrixForZoomAt(
      current: transform.value,
      focalViewport: const Offset(50, 50),
      targetScale: 2,
    );
    animateMatrixSpring(controller: anim, transform: transform, target: target);
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (!anim.isAnimating) break;
    }
    expect(transform.value.getMaxScaleOnAxis(), closeTo(2, 0.05));
  });
}
