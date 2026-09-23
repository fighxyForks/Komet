import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'glass_capsule.dart';

typedef GlassLensItemBuilder =
    Widget Function(BuildContext context, int index, bool lens);

class GlassLensStyle {
  static const double magnification = 0.2;
  static const double liftX = 10;
  static const double liftY = 9;
  static const double fringeOuter = 1.035;
  static const double fringeInner = 0.97;
  static const Duration liftIn = Duration(milliseconds: 180);
  static const Duration liftOut = Duration(milliseconds: 280);

  static Color fill(ColorScheme cs) => cs.brightness == Brightness.dark
      ? const Color(0xFF2C2C2E)
      : const Color(0xFFFAFAFC);

  static const Color fringeCool = Color(0xFF00C2FF);
  static const Color fringeWarm = Color(0xFFFF3D9A);

  static const List<Color> rim = [
    Color(0xFF7FE7FF),
    Color(0xFFFF8AD8),
    Color(0xFFFFE27A),
    Color(0xFF9DFFB0),
    Color(0xFF7FE7FF),
  ];
}

class GlassLensTrack extends StatefulWidget {
  final List<double> widths;
  final double position;
  final Duration duration;
  final double height;
  final EdgeInsets contentPadding;
  final double thumbInset;
  final double thumbOutset;
  final Widget Function(BuildContext context, double radius) thumbBuilder;
  final GlassLensItemBuilder itemBuilder;
  final Key? capsuleKey;
  final Key? thumbKey;

  const GlassLensTrack({
    super.key,
    required this.widths,
    required this.position,
    required this.height,
    required this.thumbBuilder,
    required this.itemBuilder,
    this.duration = Duration.zero,
    this.contentPadding = EdgeInsets.zero,
    this.thumbInset = 0,
    this.thumbOutset = 0,
    this.capsuleKey,
    this.thumbKey,
  });

  static Rect thumbRect({
    required List<double> widths,
    required double position,
    required double height,
    EdgeInsets contentPadding = EdgeInsets.zero,
    double thumbInset = 0,
    double thumbOutset = 0,
  }) {
    if (widths.isEmpty) return Rect.zero;
    final p = position.clamp(0.0, widths.length - 1.0);
    final i0 = p.floor();
    final i1 = math.min(i0 + 1, widths.length - 1);
    final t = p - i0;
    double offsetOf(int index) {
      var sum = 0.0;
      for (var i = 0; i < index; i++) {
        sum += widths[i];
      }
      return sum;
    }

    final left = ui.lerpDouble(offsetOf(i0), offsetOf(i1), t)!;
    final width = ui.lerpDouble(widths[i0], widths[i1], t)!;
    return Rect.fromLTWH(
      contentPadding.left + left - thumbOutset,
      thumbInset,
      width + thumbOutset * 2,
      height - thumbInset * 2,
    );
  }

  static Rect lensRect(Rect thumb, double lift) => Rect.fromLTRB(
    thumb.left - GlassLensStyle.liftX * lift,
    thumb.top - GlassLensStyle.liftY * lift,
    thumb.right + GlassLensStyle.liftX * lift,
    thumb.bottom + GlassLensStyle.liftY * lift,
  );

  @override
  State<GlassLensTrack> createState() => _GlassLensTrackState();
}

class _GlassLensTrackState extends State<GlassLensTrack>
    with TickerProviderStateMixin {
  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: widget.position,
  );
  late final AnimationController _lift = AnimationController(
    vsync: this,
    duration: GlassLensStyle.liftIn,
    reverseDuration: GlassLensStyle.liftOut,
  );

  bool get _atRest => widget.position == widget.position.roundToDouble();

  @override
  void didUpdateWidget(GlassLensTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.position == oldWidget.position) return;
    final animate = !MediaQuery.disableAnimationsOf(context);
    if (widget.duration == Duration.zero) {
      _position.stop();
      _position.value = widget.position;
      if (_atRest) {
        _lift.reverse();
      } else if (animate) {
        _lift.forward();
      }
      return;
    }
    if (animate) _lift.forward();
    _position
        .animateTo(
          widget.position,
          duration: widget.duration,
          curve: Curves.easeOutCubic,
        )
        .whenCompleteOrCancel(() {
          if (mounted && !_position.isAnimating && _atRest) _lift.reverse();
        });
  }

  @override
  void dispose() {
    _position.dispose();
    _lift.dispose();
    super.dispose();
  }

  Widget _row(BuildContext context, {required bool lens}) => Row(
    children: [
      for (var i = 0; i < widget.widths.length; i++)
        SizedBox(
          width: widget.widths[i],
          child: widget.itemBuilder(context, i, lens),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_position, _lift]),
      builder: (context, _) {
        final thumb = GlassLensTrack.thumbRect(
          widths: widget.widths,
          position: _position.value,
          height: widget.height,
          contentPadding: widget.contentPadding,
          thumbInset: widget.thumbInset,
          thumbOutset: widget.thumbOutset,
        );
        final lift = _lift.value;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            GlassCapsule(
              key: widget.capsuleKey,
              height: widget.height,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fromRect(
                    key: widget.thumbKey,
                    rect: thumb,
                    child: Opacity(
                      opacity: 1 - lift,
                      child: widget.thumbBuilder(context, thumb.height / 2),
                    ),
                  ),
                  Padding(
                    padding: widget.contentPadding,
                    child: _row(context, lens: false),
                  ),
                ],
              ),
            ),
            if (lift > 0)
              Positioned.fromRect(
                rect: GlassLensTrack.lensRect(thumb, lift),
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: _Lens(
                      key: const ValueKey('glass-lens'),
                      lift: lift,
                      lensRect: GlassLensTrack.lensRect(thumb, lift),
                      rowOrigin: Offset(
                        widget.contentPadding.left,
                        widget.contentPadding.top,
                      ),
                      rowSize: Size(
                        widget.widths.fold(0.0, (sum, w) => sum + w),
                        widget.height - widget.contentPadding.vertical,
                      ),
                      row: _row(context, lens: true),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Lens extends StatelessWidget {
  final double lift;
  final Rect lensRect;
  final Offset rowOrigin;
  final Size rowSize;
  final Widget row;

  const _Lens({
    super.key,
    required this.lift,
    required this.lensRect,
    required this.rowOrigin,
    required this.rowSize,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(lensRect.height / 2);
    final scale = 1 + GlassLensStyle.magnification * lift;
    final center = lensRect.center - rowOrigin;
    final alignment = Alignment(
      rowSize.width == 0 ? 0 : center.dx / rowSize.width * 2 - 1,
      rowSize.height == 0 ? 0 : center.dy / rowSize.height * 2 - 1,
    );
    Widget layer(double factor, Color? tint) {
      Widget child = row;
      if (tint != null) {
        child = ColorFiltered(
          colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
          child: child,
        );
      }
      return Positioned(
        left: rowOrigin.dx - lensRect.left,
        top: rowOrigin.dy - lensRect.top,
        width: rowSize.width,
        height: rowSize.height,
        child: Transform.scale(
          scale: scale * factor,
          alignment: alignment,
          child: child,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: (cs.brightness == Brightness.dark ? 0.35 : 0.12) * lift,
            ),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: ColoredBox(color: GlassLensStyle.fill(cs))),
            layer(
              GlassLensStyle.fringeOuter,
              GlassLensStyle.fringeCool.withValues(alpha: 0.6 * lift),
            ),
            layer(
              GlassLensStyle.fringeInner,
              GlassLensStyle.fringeWarm.withValues(alpha: 0.55 * lift),
            ),
            layer(1, null),
            Positioned.fill(
              child: CustomPaint(
                painter: _LensRimPainter(
                  lift: lift,
                  dark: cs.brightness == Brightness.dark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LensRimPainter extends CustomPainter {
  final double lift;
  final bool dark;

  const _LensRimPainter({required this.lift, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.75),
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = SweepGradient(
          colors: [
            for (final c in GlassLensStyle.rim)
              c.withValues(alpha: 0.85 * lift),
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rrect.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: (dark ? 0.35 : 0.9) * lift),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.45],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_LensRimPainter oldDelegate) =>
      oldDelegate.lift != lift || oldDelegate.dark != dark;
}
