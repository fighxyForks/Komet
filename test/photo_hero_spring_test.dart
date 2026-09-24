import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/motion/ios_motion.dart';
import 'package:komet/frontend/widgets/attachment/photo_hero.dart';

void main() {
  test('PhotoHeroRoute exposes motion hero durations', () {
    final hero = PhotoHeroController(
      origin: () => const Rect.fromLTWH(40, 400, 80, 80),
    );
    final route = PhotoHeroRoute<void>(
      hero: hero,
      builder: (_) => const SizedBox(),
    );
    expect(route.transitionDuration, IosMotion.heroOpen);
    expect(route.reverseTransitionDuration, IosMotion.heroClose);
    route.dispose();
  });

  test('dismiss handoff fields round-trip', () {
    final hero = PhotoHeroController(
      origin: () => const Rect.fromLTWH(40, 400, 80, 80),
    );
    addTearDown(hero.dispose);
    hero.dismissMediaOffset = const Offset(0, 120);
    hero.dismissMediaScale = 0.9;
    hero.dismissVelocityY = 800;
    expect(hero.hasDismissHandoff, isTrue);
    expect(hero.dismissMediaScale, 0.9);
    hero.clearDismissHandoff();
    expect(hero.hasDismissHandoff, isFalse);
    expect(hero.dismissMediaScale, 1);
  });

  test('hero spring is critically damped', () {
    final s = IosMotion.hero;
    final critical = 2 * math.sqrt(s.mass * s.stiffness);
    expect(s.damping, closeTo(critical, 0.01));
  });

  test('dismiss velocity maps to negative close-spring velocity', () {
    final animVelocity = -springVelocityFromPixels(
      pixelsPerSecond: 1200,
      spanPixels: 800,
    );
    expect(animVelocity, closeTo(-1.5, 1e-9));
    final sim = SpringSimulation(IosMotion.hero, 1.0, 0.0, animVelocity);
    expect(sim, isA<SpringSimulation>());
    expect(sim.dx(0), closeTo(animVelocity, 0.05));
    expect(sim.x(0), closeTo(1.0, 0.01));
  });

  testWidgets('animateSpring interrupt keeps value and settles to target', (
    tester,
  ) async {
    final controller = AnimationController.unbounded(vsync: tester);
    addTearDown(controller.dispose);
    controller.value = 0;
    animateSpring(controller, target: 1, spring: IosMotion.standard);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (controller.value > 0.15 && controller.value < 0.9) break;
    }
    expect(controller.value, greaterThan(0.15));
    final midVelocity = controller.velocity;
    final midValue = controller.value;
    animateSpring(
      controller,
      target: 0,
      spring: IosMotion.standard,
      velocity: midVelocity,
    );
    expect(controller.value, closeTo(midValue, 0.001));
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (!controller.isAnimating) break;
    }
    expect(controller.value, closeTo(0, 0.05));
  });

  test('createSimulation builds reverse spring from dismissVelocityY', () {
    final hero = PhotoHeroController(
      origin: () => const Rect.fromLTWH(40, 400, 80, 80),
    );
    hero.dismissVelocityY = 1200;
    final route = PhotoHeroRoute<void>(
      hero: hero,
      builder: (_) => const SizedBox(),
    );
    addTearDown(route.dispose);
    final sim = route.createSimulation(forward: false);
    expect(sim, isA<SettlingSpringSimulation>());
    expect(sim!.dx(0), lessThan(0));
    final open = route.createSimulation(forward: true);
    expect(open, isA<SettlingSpringSimulation>());
    expect(open!.dx(0), 0);
  });
}
