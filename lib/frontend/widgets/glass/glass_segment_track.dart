import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'glass_capsule.dart';

class GlassSegmentTrack extends StatefulWidget {
  final List<double> widths;
  final double position;
  final Duration duration;
  final double height;
  final EdgeInsets contentPadding;
  final double thumbInset;
  final double thumbOutset;
  final Widget Function(BuildContext context, double radius) thumbBuilder;
  final IndexedWidgetBuilder itemBuilder;
  final Key? capsuleKey;
  final Key? thumbKey;

  const GlassSegmentTrack({
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

  @override
  State<GlassSegmentTrack> createState() => _GlassSegmentTrackState();
}

class _GlassSegmentTrackState extends State<GlassSegmentTrack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: widget.position,
  );

  @override
  void didUpdateWidget(GlassSegmentTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.position == oldWidget.position) return;
    if (widget.duration == Duration.zero ||
        MediaQuery.disableAnimationsOf(context)) {
      _position.stop();
      _position.value = widget.position;
      return;
    }
    _position.animateTo(
      widget.position,
      duration: widget.duration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: widget.contentPadding,
      child: Row(
        children: [
          for (var i = 0; i < widget.widths.length; i++)
            SizedBox(
              width: widget.widths[i],
              child: widget.itemBuilder(context, i),
            ),
        ],
      ),
    );
    return GlassCapsule(
      key: widget.capsuleKey,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _position,
        child: row,
        builder: (context, row) {
          final thumb = GlassSegmentTrack.thumbRect(
            widths: widget.widths,
            position: _position.value,
            height: widget.height,
            contentPadding: widget.contentPadding,
            thumbInset: widget.thumbInset,
            thumbOutset: widget.thumbOutset,
          );
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fromRect(
                key: widget.thumbKey,
                rect: thumb,
                child: widget.thumbBuilder(context, thumb.height / 2),
              ),
              row!,
            ],
          );
        },
      ),
    );
  }
}
