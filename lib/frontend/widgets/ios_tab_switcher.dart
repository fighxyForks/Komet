import 'package:flutter/widgets.dart';

import '../motion/ios_motion.dart';

class IosTabSwitcher extends StatefulWidget {
  static const Duration duration = Duration(milliseconds: 250);
  static const double _fadeEnd = 0.4;
  static const double _leaveEnd = 0.48;

  final int index;
  final List<WidgetBuilder> tabs;

  const IosTabSwitcher({super.key, required this.index, required this.tabs});

  @override
  State<IosTabSwitcher> createState() => _IosTabSwitcherState();
}

class _IosTabSwitcherState extends State<IosTabSwitcher>
    with SingleTickerProviderStateMixin {
  late final Set<int> _built = {widget.index};
  int? _leaving;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: IosTabSwitcher.duration,
    value: 1,
  )..addListener(_onTick);
  late final CurvedAnimation _fadeIn = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, IosTabSwitcher._fadeEnd),
  );
  late final CurvedAnimation _settleIn = CurvedAnimation(
    parent: _controller,
    curve: const Interval(
      IosTabSwitcher._fadeEnd,
      1,
      curve: Curves.easeOutCubic,
    ),
  );
  late final CurvedAnimation _shrinkOut = CurvedAnimation(
    parent: _controller,
    curve: const Interval(
      0,
      IosTabSwitcher._leaveEnd,
      curve: Curves.easeOutCubic,
    ),
  );

  void _onTick() {
    if (_leaving != null && _controller.value >= IosTabSwitcher._fadeEnd) {
      setState(() => _leaving = null);
    }
  }

  @override
  void didUpdateWidget(IosTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    _built.add(widget.index);
    if (IosMotion.reduceMotionOf(context)) {
      _leaving = null;
      _controller.value = 1;
      return;
    }
    _leaving = oldWidget.index;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _fadeIn.dispose();
    _settleIn.dispose();
    _shrinkOut.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final shrunk = height.isFinite && height > 3
            ? (height - 3) / height
            : 1.0;
        final order = [
          for (final i in _built)
            if (i != widget.index && i != _leaving) i,
          ?_leaving,
          widget.index,
        ];
        return Stack(
          fit: StackFit.expand,
          children: [
            for (final i in order)
              KeyedSubtree(key: ValueKey<int>(i), child: _layer(i, shrunk)),
          ],
        );
      },
    );
  }

  Widget _layer(int i, double shrunk) {
    final active = i == widget.index;
    final leaving = i == _leaving;
    final Animation<double> opacity;
    final Animation<double> scale;
    if (active) {
      opacity = _fadeIn;
      scale = Tween<double>(begin: shrunk, end: 1).animate(_settleIn);
    } else if (leaving) {
      opacity = const AlwaysStoppedAnimation(1);
      scale = Tween<double>(begin: 1, end: shrunk).animate(_shrinkOut);
    } else {
      opacity = const AlwaysStoppedAnimation(1);
      scale = const AlwaysStoppedAnimation(1);
    }
    return Offstage(
      offstage: !active && !leaving,
      child: TickerMode(
        enabled: active,
        child: IgnorePointer(
          ignoring: !active,
          child: FadeTransition(
            opacity: opacity,
            child: ScaleTransition(
              scale: scale,
              child: Builder(builder: widget.tabs[i]),
            ),
          ),
        ),
      ),
    );
  }
}
