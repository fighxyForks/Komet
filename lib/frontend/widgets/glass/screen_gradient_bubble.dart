import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class ScreenGradientBubble extends StatelessWidget {
  final List<Color> colors;
  final BorderRadius borderRadius;
  final Color rim;
  final Widget child;

  const ScreenGradientBubble({
    super.key,
    required this.colors,
    required this.borderRadius,
    required this.rim,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => ScreenGradientBox(
    colors: colors,
    borderRadius: borderRadius,
    rim: rim,
    viewportHeight: MediaQuery.sizeOf(context).height,
    scrollPosition: Scrollable.maybeOf(context)?.position,
    child: RepaintBoundary(child: child),
  );
}

class ScreenGradientBox extends SingleChildRenderObjectWidget {
  final List<Color> colors;
  final BorderRadius borderRadius;
  final Color rim;
  final double viewportHeight;
  final Listenable? scrollPosition;

  const ScreenGradientBox({
    super.key,
    required this.colors,
    required this.borderRadius,
    required this.rim,
    required this.viewportHeight,
    this.scrollPosition,
    super.child,
  });

  @override
  RenderScreenGradientBox createRenderObject(BuildContext context) =>
      RenderScreenGradientBox(
        colors: colors,
        borderRadius: borderRadius,
        rim: rim,
        viewportHeight: viewportHeight,
        scrollPosition: scrollPosition,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderScreenGradientBox renderObject,
  ) {
    renderObject
      ..colors = colors
      ..borderRadius = borderRadius
      ..rim = rim
      ..viewportHeight = viewportHeight
      ..scrollPosition = scrollPosition;
  }
}

class RenderScreenGradientBox extends RenderProxyBox {
  RenderScreenGradientBox({
    required List<Color> colors,
    required BorderRadius borderRadius,
    required Color rim,
    required double viewportHeight,
    Listenable? scrollPosition,
  }) : _colors = colors,
       _borderRadius = borderRadius,
       _rim = rim,
       _viewportHeight = viewportHeight,
       _scrollPosition = scrollPosition;

  List<Color> _colors;
  BorderRadius _borderRadius;
  Color _rim;
  double _viewportHeight;
  Listenable? _scrollPosition;
  double? _paintedTop;
  bool _watching = false;

  double? get debugPaintedTop => _paintedTop;

  set colors(List<Color> value) {
    if (listEquals(value, _colors)) return;
    _colors = value;
    markNeedsPaint();
  }

  set borderRadius(BorderRadius value) {
    if (value == _borderRadius) return;
    _borderRadius = value;
    markNeedsPaint();
  }

  set rim(Color value) {
    if (value == _rim) return;
    _rim = value;
    markNeedsPaint();
  }

  set viewportHeight(double value) {
    if (value == _viewportHeight) return;
    _viewportHeight = value;
    markNeedsPaint();
  }

  set scrollPosition(Listenable? value) {
    if (identical(value, _scrollPosition)) return;
    if (attached) _scrollPosition?.removeListener(markNeedsPaint);
    _scrollPosition = value;
    if (attached) _scrollPosition?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scrollPosition?.addListener(markNeedsPaint);
    _watchPosition();
  }

  @override
  void detach() {
    _scrollPosition?.removeListener(markNeedsPaint);
    _watching = false;
    super.detach();
  }

  void _watchPosition() {
    if (_watching) return;
    _watching = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _watching = false;
      if (!attached) return;
      if (_paintedTop != null && _globalTop() != _paintedTop) markNeedsPaint();
      _watchPosition();
    });
  }

  double _globalTop() => localToGlobal(Offset.zero).dy;

  @override
  void paint(PaintingContext context, Offset offset) {
    final top = _globalTop();
    _paintedTop = top;
    final rect = offset & size;
    final rrect = _borderRadius.toRRect(rect);
    final shaderTop = offset.dy - top;
    final paint = Paint()
      ..shader = _colors.length < 2
          ? null
          : ui.Gradient.linear(
              Offset(0, shaderTop),
              Offset(0, shaderTop + _viewportHeight),
              _colors,
            );
    if (_colors.length < 2 && _colors.isNotEmpty) paint.color = _colors.first;
    context.canvas.drawRRect(rrect, paint);
    context.canvas.drawRRect(
      rrect.deflate(0.25),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = _rim,
    );
    super.paint(context, offset);
  }
}
