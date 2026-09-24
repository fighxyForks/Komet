import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/motion/gallery_dismiss.dart';
import 'package:komet/frontend/motion/ios_motion.dart';

void main() {
  testWidgets('drag update moves offset and dims background', (tester) async {
    late GalleryDismissController dismiss;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return _Host(onCreated: (c) => dismiss = c);
            },
          ),
        ),
      ),
    );
    await tester.pump();
    dismiss.updateViewportHeight(800);
    dismiss.onDragStart();
    dismiss.onDragUpdate(40);
    expect(dismiss.offset, 40);
    expect(dismiss.backgroundOpacity, lessThan(1));
    expect(dismiss.mediaScale, lessThan(1));
    dismiss.onDragCancel();
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(dismiss.offset, closeTo(0, 0.5));
  });

  testWidgets('small drag snaps back without commit', (tester) async {
    late GalleryDismissController dismiss;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _Host(onCreated: (c) => dismiss = c)),
      ),
    );
    await tester.pump();
    dismiss.updateViewportHeight(800);
    dismiss.onDragStart();
    dismiss.onDragUpdate(30);
    final committed = dismiss.onDragEnd(0);
    expect(committed, isFalse);
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(dismiss.offset, closeTo(0, 0.5));
  });

  testWidgets('large drag commits', (tester) async {
    late GalleryDismissController dismiss;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _Host(onCreated: (c) => dismiss = c)),
      ),
    );
    await tester.pump();
    dismiss.updateViewportHeight(800);
    final past = 800 / IosMotion.dismissDistanceDivisor + 10;
    dismiss.onDragStart();
    dismiss.onDragUpdate(past);
    expect(dismiss.onDragEnd(0), isTrue);
    expect(dismiss.isCommitting, isTrue);
  });

  testWidgets('fast fling commits', (tester) async {
    late GalleryDismissController dismiss;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _Host(onCreated: (c) => dismiss = c)),
      ),
    );
    await tester.pump();
    dismiss.updateViewportHeight(800);
    dismiss.onDragStart();
    dismiss.onDragUpdate(15);
    expect(dismiss.onDragEnd(IosMotion.dismissFlingVelocity + 100), isTrue);
  });
}

class _Host extends StatefulWidget {
  const _Host({required this.onCreated});
  final ValueChanged<GalleryDismissController> onCreated;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with TickerProviderStateMixin {
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
