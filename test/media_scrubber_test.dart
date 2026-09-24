import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/widgets/media_scrubber.dart';

void main() {
  testWidgets('scrubber reports seek on drag end', (tester) async {
    Duration? seekEnd;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaScrubber(
            position: const Duration(seconds: 5),
            duration: const Duration(seconds: 20),
            buffered: const Duration(seconds: 12),
            onSeekEnd: (d) => seekEnd = d,
          ),
        ),
      ),
    );
    await tester.pump();
    final center = tester.getCenter(find.byType(MediaScrubber));
    await tester.dragFrom(center, const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(seekEnd, isNotNull);
    expect(seekEnd!.inMilliseconds, greaterThan(5000));
  });

  testWidgets('shows tabular time labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaScrubber(
            position: Duration(seconds: 65),
            duration: Duration(seconds: 125),
          ),
        ),
      ),
    );
    expect(find.text('01:05'), findsOneWidget);
    expect(find.text('02:05'), findsOneWidget);
  });
}
