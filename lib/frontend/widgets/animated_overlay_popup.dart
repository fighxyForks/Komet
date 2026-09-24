import 'package:flutter/material.dart';

import '../motion/ios_motion.dart';

mixin AnimatedOverlayPopup<T extends StatefulWidget>
    on State<T>, TickerProvider {
  Duration get overlayForwardDuration;
  Duration get overlayReverseDuration;
  VoidCallback get onOverlayDismiss;
  Curve get overlayForwardCurve => Curves.easeOutCubic;
  Curve get overlayReverseCurve => Curves.easeInCubic;

  /// When true, appear/dismiss use [overlaySpring] via [animateSpring] so
  /// reversing mid-flight keeps velocity (no curve jump).
  bool get overlayUseSpring => false;

  SpringDescription get overlaySpring => IosMotion.overlay;

  late final AnimationController _overlayController;
  late final Animation<double> overlayAnimation;

  bool _overlayClosing = false;

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      vsync: this,
      duration: overlayForwardDuration,
      reverseDuration: overlayReverseDuration,
    );
    if (overlayUseSpring) {
      overlayAnimation = _overlayController;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _overlayClosing) return;
        if (IosMotion.reduceMotionOf(context)) {
          _overlayController.duration = IosMotion.pageCrossFade;
          _overlayController.forward();
          return;
        }
        animateSpring(
          _overlayController,
          target: 1,
          spring: overlaySpring,
        );
      });
    } else {
      overlayAnimation = CurvedAnimation(
        parent: _overlayController,
        curve: overlayForwardCurve,
        reverseCurve: overlayReverseCurve,
      );
      _overlayController.forward();
    }
  }

  Future<void> closeOverlay() async {
    if (!mounted || _overlayClosing) return;
    _overlayClosing = true;
    try {
      if (overlayUseSpring) {
        if (IosMotion.reduceMotionOf(context)) {
          await _overlayController.animateTo(
            0,
            duration: IosMotion.pageCrossFade,
            curve: Curves.linear,
          );
        } else {
          await animateSpring(
            _overlayController,
            target: 0,
            spring: overlaySpring,
            velocity: _overlayController.velocity,
          );
        }
      } else {
        await _overlayController.reverse();
      }
    } catch (_) {}
    if (!mounted) return;
    onOverlayDismiss();
  }

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
  }
}
