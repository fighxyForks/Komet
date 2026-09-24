import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/widgets/attachment/bubbles/ios_bubble_metrics.dart';
import 'package:komet/frontend/widgets/text_with_meta.dart';

void main() {
  testWidgets('single-line meta baseline aligns with body text baseline', (
    tester,
  ) async {
    const bodyStyle = TextStyle(
      fontSize: IosBubbleMetrics.textSize,
      height: IosBubbleMetrics.textHeight,
      color: Colors.white,
    );
    const metaStyle = TextStyle(
      fontSize: IosBubbleMetrics.timeSize,
      color: Colors.white70,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ColoredBox(
              color: Colors.black,
              child: TextWithMeta(
                text: const Text('Получено', style: bodyStyle),
                meta: const Text('09:03', style: metaStyle),
              ),
            ),
          ),
        ),
      ),
    );

    final textPara = tester.renderObject<RenderParagraph>(
      find.text('Получено'),
    );
    final metaPara = tester.renderObject<RenderParagraph>(find.text('09:03'));

    final textBl = textPara.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final metaBl = metaPara.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );

    final textOrigin = tester.getTopLeft(find.text('Получено'));
    final metaOrigin = tester.getTopLeft(find.text('09:03'));
    final bodyBaseline = textOrigin.dy + textBl;
    final metaBaseline = metaOrigin.dy + metaBl;

    expect(
      metaBaseline,
      closeTo(bodyBaseline, 1.0),
      reason:
          'meta baseline $metaBaseline should sit on body baseline $bodyBaseline',
    );
    // Guard against the old bug where meta sat 1–2pt above the body baseline.
    expect(metaBaseline, greaterThanOrEqualTo(bodyBaseline - 0.5));
  });

  testWidgets('multi-line meta stays on its own bottom row', (tester) async {
    const bodyStyle = TextStyle(
      fontSize: IosBubbleMetrics.textSize,
      height: IosBubbleMetrics.textHeight,
      color: Colors.white,
    );
    const metaStyle = TextStyle(
      fontSize: IosBubbleMetrics.timeSize,
      color: Colors.white70,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              child: ColoredBox(
                color: Colors.black,
                child: TextWithMeta(
                  text: const Text(
                    'Длинная строка которая точно переносится на две',
                    style: bodyStyle,
                  ),
                  meta: const Text('15:29', style: metaStyle),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final box = tester.getSize(find.byType(TextWithMeta));
    final metaRect = tester.getRect(find.text('15:29'));
    final textRect = tester.getRect(find.textContaining('Длинная'));
    expect(metaRect.top, greaterThanOrEqualTo(textRect.top + 8));
    expect(box.height, greaterThan(textRect.height));
  });
}
