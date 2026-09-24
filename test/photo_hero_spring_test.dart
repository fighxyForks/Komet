import 'package:flutter/material.dart';
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
}
