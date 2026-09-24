import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/motion/ios_motion.dart';

void main() {
  group('IosMotion.shouldCommitDismiss', () {
    test('commits when distance exceeds height/12', () {
      const h = 840.0;
      final threshold = h / IosMotion.dismissDistanceDivisor;
      expect(
        IosMotion.shouldCommitDismiss(
          offset: threshold + 1,
          velocityY: 0,
          viewportHeight: h,
        ),
        isTrue,
      );
      expect(
        IosMotion.shouldCommitDismiss(
          offset: threshold - 1,
          velocityY: 0,
          viewportHeight: h,
        ),
        isFalse,
      );
    });

    test('commits on fast fling even with small offset', () {
      expect(
        IosMotion.shouldCommitDismiss(
          offset: 20,
          velocityY: IosMotion.dismissFlingVelocity + 50,
          viewportHeight: 800,
        ),
        isTrue,
      );
      expect(
        IosMotion.shouldCommitDismiss(
          offset: 20,
          velocityY: IosMotion.dismissFlingVelocity - 50,
          viewportHeight: 800,
        ),
        isFalse,
      );
    });

    test('does not commit a fling back toward rest', () {
      expect(
        IosMotion.shouldCommitDismiss(
          offset: 20,
          velocityY: -(IosMotion.dismissFlingVelocity + 50),
          viewportHeight: 800,
        ),
        isFalse,
      );
      expect(
        IosMotion.shouldCommitDismiss(
          offset: -20,
          velocityY: -(IosMotion.dismissFlingVelocity + 50),
          viewportHeight: 800,
        ),
        isTrue,
      );
    });

    test('works for upward and downward offsets', () {
      const h = 800.0;
      final past = h / IosMotion.dismissDistanceDivisor + 5;
      expect(
        IosMotion.shouldCommitDismiss(
          offset: -past,
          velocityY: 0,
          viewportHeight: h,
        ),
        isTrue,
      );
    });
  });

  group('IosMotion.rubberBand', () {
    test('is linear before banding start', () {
      expect(IosMotion.rubberBand(offset: 40, bandingStart: 60), 40);
      expect(IosMotion.rubberBand(offset: -40, bandingStart: 60), -40);
    });

    test('softens past banding start', () {
      final raw = 120.0;
      final banded = IosMotion.rubberBand(offset: raw, bandingStart: 60);
      expect(banded, lessThan(raw));
      expect(banded, greaterThan(60));
    });
  });

  group('IosMotion.progress', () {
    test('clamps to 0..1', () {
      expect(IosMotion.progress(0, 80), 0);
      expect(IosMotion.progress(40, 80), 0.5);
      expect(IosMotion.progress(200, 80), 1);
    });
  });

  group('springVelocityFromPixels', () {
    test('scales by span', () {
      expect(
        springVelocityFromPixels(pixelsPerSecond: 800, spanPixels: 400),
        2,
      );
      expect(springVelocityFromPixels(pixelsPerSecond: 100, spanPixels: 0), 0);
    });
  });

  testWidgets('animateSpring settles near target', (tester) async {
    final controller = AnimationController.unbounded(vsync: tester);
    addTearDown(controller.dispose);
    controller.value = 0;
    animateSpring(controller, target: 1, spring: IosMotion.standard);
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (!controller.isAnimating) break;
    }
    expect(controller.isAnimating, isFalse);
    expect(controller.value, closeTo(1, 0.02));
  });

  test('SnapSimulation finishes immediately at value', () {
    final sim = SnapSimulation(1);
    expect(sim.x(0), 1);
    expect(sim.dx(0), 0);
    expect(sim.isDone(0), isTrue);
  });

  test('hero and overlay springs are critically damped', () {
    for (final spring in [IosMotion.hero, IosMotion.overlay]) {
      expect(
        spring.damping * spring.damping,
        closeTo(4 * spring.mass * spring.stiffness, 0.5),
      );
    }
  });
}
