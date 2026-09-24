import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/utils/haptics.dart';
import 'glass/ios_glass.dart';
import 'glass/ios_typography.dart';

/// Compact media scrubber: thin track that thickens while dragging, optional
/// buffered fill, and a time readout. Seek updates are debounced.
class MediaScrubber extends StatefulWidget {
  const MediaScrubber({
    super.key,
    required this.position,
    required this.duration,
    this.buffered,
    this.onSeek,
    this.onSeekEnd,
    this.debounce = const Duration(milliseconds: 32),
  });

  final Duration position;
  final Duration duration;
  final Duration? buffered;
  final ValueChanged<Duration>? onSeek;
  final ValueChanged<Duration>? onSeekEnd;
  final Duration debounce;

  @override
  State<MediaScrubber> createState() => _MediaScrubberState();
}

class _MediaScrubberState extends State<MediaScrubber> {
  bool _dragging = false;
  double? _dragValue;
  Timer? _debounce;
  int _lastTickSecond = -1;

  double get _maxMs => math.max(widget.duration.inMilliseconds.toDouble(), 1);

  double get _value {
    if (_dragValue != null) return _dragValue!.clamp(0, _maxMs);
    return widget.position.inMilliseconds.toDouble().clamp(0, _maxMs);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _emitSeek(double ms, {required bool end}) {
    final d = Duration(milliseconds: ms.round());
    if (end) {
      _debounce?.cancel();
      widget.onSeekEnd?.call(d);
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => widget.onSeek?.call(d));
  }

  void _onDragStart(double localX, double width) {
    setState(() => _dragging = true);
    _updateFromX(localX, width, end: false);
  }

  void _updateFromX(double localX, double width, {required bool end}) {
    if (width <= 0) return;
    final t = (localX / width).clamp(0.0, 1.0);
    final ms = t * _maxMs;
    setState(() => _dragValue = ms);
    final sec = (ms / 1000).floor();
    if (sec != _lastTickSecond) {
      _lastTickSecond = sec;
      if (_dragging) unawaited(Haptics.tap());
    }
    _emitSeek(ms, end: end);
  }

  void _onDragEnd() {
    final ms = _value;
    setState(() {
      _dragging = false;
      _dragValue = null;
    });
    _emitSeek(ms, end: true);
  }

  @override
  Widget build(BuildContext context) {
    final ios = IosGlass.of(context);
    final active = ios
        ? const Color(0xFFFF3B30)
        : Theme.of(context).colorScheme.primary;
    final track = Colors.white.withValues(alpha: ios ? 0.28 : 0.35);
    final bufColor = Colors.white.withValues(alpha: ios ? 0.45 : 0.5);
    final pos = Duration(milliseconds: _value.round());
    final progress = (_value / _maxMs).clamp(0.0, 1.0);
    final buffered = widget.buffered == null
        ? 0.0
        : (widget.buffered!.inMilliseconds / _maxMs).clamp(0.0, 1.0);
    final trackHeight = _dragging ? 6.0 : 3.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              _format(pos),
              style: TextStyle(
                color: Colors.white,
                fontSize: ios ? IosTypography.callLabel : 11,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            Text(
              _format(widget.duration),
              style: TextStyle(
                color: Colors.white70,
                fontSize: ios ? IosTypography.callLabel : 11,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) => _onDragStart(d.localPosition.dx, w),
              onHorizontalDragUpdate: (d) =>
                  _updateFromX(d.localPosition.dx, w, end: false),
              onHorizontalDragEnd: (_) => _onDragEnd(),
              onTapDown: (d) => _onDragStart(d.localPosition.dx, w),
              onTapUp: (_) => _onDragEnd(),
              child: SizedBox(
                height: 28,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: trackHeight,
                    decoration: BoxDecoration(
                      color: track,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FractionallySizedBox(
                          widthFactor: buffered,
                          alignment: Alignment.centerLeft,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: bufColor,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          alignment: Alignment.centerLeft,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: active,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static String _format(Duration d) {
    final total = d.inSeconds.clamp(0, 359999);
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
