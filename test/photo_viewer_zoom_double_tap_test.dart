import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/motion/ios_motion.dart';
import 'package:komet/frontend/widgets/photo_viewer.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:komet/models/attachment.dart';

double _scale(WidgetTester tester) => tester
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

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PhotoViewerScreen(
        photos: const [PhotoAttachment(baseUrl: 'https://example.com/a.jpg')],
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('double tap zooms in then back to fit', (tester) async {
    await _pump(tester);
    final center = tester.getCenter(find.byType(InteractiveViewer));

    // Two quick taps within singleTapDelay.
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tapAt(center);
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(_scale(tester), greaterThan(2));

    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tapAt(center);
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(_scale(tester), closeTo(1, 0.05));
  });

  testWidgets('InteractiveViewer hard max matches motion constant', (
    tester,
  ) async {
    await _pump(tester);
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(viewer.maxScale, IosMotion.zoomHardMax);
    expect(viewer.minScale, lessThan(1.01));
  });
}
