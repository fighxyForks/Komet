import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/motion/gallery_dismiss.dart';
import 'package:komet/frontend/motion/ios_motion.dart';
import 'package:komet/frontend/widgets/photo_viewer.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:komet/models/attachment.dart';

Future<void> _pumpViewer(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PhotoViewerScreen(
        photos: const [
          PhotoAttachment(baseUrl: 'https://example.com/a.jpg'),
          PhotoAttachment(baseUrl: 'https://example.com/b.jpg'),
        ],
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

GalleryDismissController _dismissOf(WidgetTester tester) {
  final state = tester.state(find.byType(PhotoViewerScreen));
  return (state as dynamic).debugDismissController as GalleryDismissController;
}

Future<void> _dragVertical(
  WidgetTester tester, {
  required double dy,
  Duration step = const Duration(milliseconds: 16),
  int steps = 12,
}) async {
  final center = tester.getCenter(find.byType(PhotoViewerScreen));
  final gesture = await tester.startGesture(center);
  await tester.pump(step);
  final perStep = dy / steps;
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(0, perStep));
    await tester.pump(step);
  }
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets('small vertical drag snaps back without commit', (tester) async {
    await _pumpViewer(tester);
    final dismiss = _dismissOf(tester);

    await _dragVertical(tester, dy: 30);
    expect(dismiss.isCommitting, isFalse);
    // Snap-back spring toward 0.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(dismiss.offset.abs(), lessThan(1));
  });

  testWidgets('large vertical drag commits dismiss', (tester) async {
    await _pumpViewer(tester);
    final dismiss = _dismissOf(tester);
    final height = tester.getSize(find.byType(PhotoViewerScreen)).height;
    final past = height / IosMotion.dismissDistanceDivisor + 40;

    await _dragVertical(tester, dy: past);
    expect(dismiss.isCommitting, isTrue);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  });

  testWidgets('fast fling commits dismiss', (tester) async {
    await _pumpViewer(tester);
    final dismiss = _dismissOf(tester);

    final center = tester.getCenter(find.byType(PhotoViewerScreen));
    await tester.flingFrom(
      center,
      const Offset(0, 200),
      IosMotion.dismissFlingVelocity + 200,
    );
    await tester.pump();
    expect(dismiss.isCommitting, isTrue);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  });

  testWidgets('zoomed state blocks vertical dismiss', (tester) async {
    await _pumpViewer(tester);
    final dismiss = _dismissOf(tester);

    final center = tester.getCenter(find.byType(InteractiveViewer));
    final a = await tester.startGesture(center.translate(-40, 0));
    final b = await tester.startGesture(center.translate(40, 0));
    await tester.pump(const Duration(milliseconds: 16));
    for (var i = 0; i < 12; i++) {
      await a.moveBy(const Offset(-12, 0));
      await b.moveBy(const Offset(12, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await a.up();
    await b.up();
    await tester.pump();

    final scale = tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(InteractiveViewer),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .getMaxScaleOnAxis();
    expect(scale, greaterThan(1.01));

    final height = tester.getSize(find.byType(PhotoViewerScreen)).height;
    final past = height / IosMotion.dismissDistanceDivisor + 40;
    await _dragVertical(tester, dy: past);

    expect(dismiss.isCommitting, isFalse);
    expect(dismiss.offset.abs(), lessThan(1));
  });
}
