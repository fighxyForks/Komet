import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/core/utils/download_history.dart';
import 'package:komet/core/utils/media_cache.dart';
import 'package:komet/frontend/screens/downloads_screen.dart';
import 'package:komet/frontend/widgets/glass/glass_capsule.dart';
import 'package:komet/frontend/widgets/glass/glass_menu.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SyntheticPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String directory;

  _SyntheticPathProvider(this.directory);

  @override
  Future<String?> getApplicationSupportPath() async => directory;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('в iOS-режиме загрузки получают стеклянные кнопки и меню', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'synthetic_downloads_ios_test',
    );
    addTearDown(() {
      DownloadHistory.resetForTesting();
      MediaCache.resetForTesting();
      AppIosGlass.debugReset();
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });
    PathProviderPlatform.instance = _SyntheticPathProvider(directory.path);
    MediaCache.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      DownloadHistory.resetForTesting();
      final file = await MediaCache.fileFor('synthetic-archive.zip');
      await file.writeAsBytes(List<int>.filled(1024, 1));
      await DownloadHistory.record(
        const DownloadMetadata(
          cacheName: 'synthetic-archive.zip',
          name: 'synthetic-archive.zip',
          kind: DownloadKind.file,
          sourceName: 'Synthetic source',
          chatId: 5,
          messageId: 'synthetic-id',
          messageTime: 1,
        ),
        file,
      );
      DownloadHistory.resetForTesting();
      await DownloadHistory.load();
      await AppIosGlass.load();
    });
    AppIosGlass.debugSetSupported(true);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => IosGlass(child: child!),
        home: const DownloadsScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final settings = find.byKey(const ValueKey('downloads-settings'));
    expect(
      find.descendant(of: settings, matching: find.byType(GlassCapsule)),
      findsOneWidget,
    );

    await tester.tap(settings);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('glass-menu')), findsOneWidget);
    expect(find.text('Очистить историю загрузок'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('glass-menu-barrier')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('download-more-synthetic-archive.zip')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GlassMenuRow), findsWidgets);
    expect(find.text('Перейти к сообщению'), findsOneWidget);
    expect(find.text('Сохранить как…'), findsOneWidget);
  });
}
