import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/motion/ios_motion.dart';
import 'package:komet/frontend/widgets/photo_viewer.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:komet/models/attachment.dart';

void main() {
  testWidgets('gallery pages use horizontal gap padding', (tester) async {
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
    final padding = tester.widget<Padding>(
      find
          .descendant(of: find.byType(PageView), matching: find.byType(Padding))
          .first,
    );
    expect(
      padding.padding,
      const EdgeInsets.symmetric(horizontal: IosMotion.galleryPageGap / 2),
    );
  });
}
