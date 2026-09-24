import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/motion/gallery_dismiss.dart';
import 'package:komet/frontend/motion/ios_motion.dart';

void main() {
  testWidgets('reduceMotionOf follows MediaQuery.disableAnimations', (
    tester,
  ) async {
    late bool reduced;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            reduced = IosMotion.reduceMotionOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(reduced, isTrue);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: false),
        child: Builder(
          builder: (context) {
            reduced = IosMotion.reduceMotionOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(reduced, isFalse);
  });

  test('SnapSimulation is used for reduced-motion hero snaps', () {
    final sim = SnapSimulation(1);
    expect(sim.isDone(0), isTrue);
    expect(sim.x(0), 1);
    expect(sim.dx(0), 0);
    final close = SnapSimulation(0);
    expect(close.x(0), 0);
  });

  testWidgets('flyOff with reduceMotion snaps immediately', (tester) async {
    late GalleryDismissController dismiss;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _DismissHost(onCreated: (c) => dismiss = c),
        ),
      ),
    );
    await tester.pump();
    dismiss.updateViewportHeight(800);
    dismiss.onDragStart();
    dismiss.onDragUpdate(100);
    var done = false;
    await dismiss.flyOff(
      velocityY: 1200,
      reduceMotion: true,
      onDone: () => done = true,
    );
    expect(done, isTrue);
    expect(dismiss.offset.abs(), greaterThan(800));
  });

  testWidgets('gestureVelocityY is preserved on commit', (tester) async {
    late GalleryDismissController dismiss;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _DismissHost(onCreated: (c) => dismiss = c),
        ),
      ),
    );
    await tester.pump();
    dismiss.updateViewportHeight(800);
    dismiss.onDragStart();
    dismiss.onDragUpdate(15);
    expect(dismiss.onDragEnd(1500), isTrue);
    expect(dismiss.gestureVelocityY, 1500);
  });

  testWidgets('onDragUpdate reports threshold crossed once', (tester) async {
    late GalleryDismissController dismiss;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _DismissHost(onCreated: (c) => dismiss = c),
        ),
      ),
    );
    await tester.pump();
    dismiss.updateViewportHeight(800);
    dismiss.onDragStart();
    expect(dismiss.onDragUpdate(20), isFalse);
    final past = 800 / IosMotion.dismissDistanceDivisor + 5;
    expect(dismiss.onDragUpdate(past - 20), isTrue);
    expect(dismiss.onDragUpdate(10), isFalse);
  });
}

class _DismissHost extends StatefulWidget {
  const _DismissHost({required this.onCreated});
  final ValueChanged<GalleryDismissController> onCreated;

  @override
  State<_DismissHost> createState() => _DismissHostState();
}

class _DismissHostState extends State<_DismissHost>
    with TickerProviderStateMixin {
  late final GalleryDismissController _dismiss;

  @override
  void initState() {
    super.initState();
    _dismiss = GalleryDismissController(vsync: this);
    widget.onCreated(_dismiss);
  }

  @override
  void dispose() {
    _dismiss.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
