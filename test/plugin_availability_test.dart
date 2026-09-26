import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/build_profile.dart';
import 'package:komet/core/plugins/plugin_availability.dart';
import 'package:komet/core/plugins/plugin_cleanup.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('KOMET_PLUGINS stays on unless the build sets it', () {
    const defined = bool.hasEnvironment('KOMET_PLUGINS');
    if (defined || BuildProfile.isAppStoreBuild) {
      expect(kPluginsCompiled, isFalse);
    } else {
      expect(kPluginsCompiled, isTrue);
    }
  });

  test('discardDownloadedPlugins removes scripts and saved state', () async {
    SharedPreferences.setMockInitialValues({
      kPluginStateKey: '{"synthetic":true}',
      '${kPluginStoragePrefix}synthetic': '{"token":"1"}',
      'unrelated_setting': 'keep',
    });
    final support = await Directory.systemTemp.createTemp('komet_plugins_');
    final plugins = Directory(p.join(support.path, 'plugins'));
    await plugins.create();
    await File(p.join(plugins.path, 'main.js')).writeAsString('synthetic');

    await discardDownloadedPlugins(supportDirectory: () async => support);

    expect(await plugins.exists(), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kPluginStateKey), isNull);
    expect(prefs.getString('${kPluginStoragePrefix}synthetic'), isNull);
    expect(prefs.getString('unrelated_setting'), 'keep');
    if (await support.exists()) await support.delete(recursive: true);
  });
}
