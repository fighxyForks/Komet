import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/app_instance.dart';
import 'plugin_availability.dart';

Future<void> discardDownloadedPlugins({
  Future<Directory> Function()? supportDirectory,
}) async {
  final support = await (supportDirectory ?? getApplicationSupportDirectory)();
  final root = Directory(p.join(support.path, 'plugins${AppInstance.suffix}'));
  if (await root.exists()) {
    await root.delete(recursive: true);
  }
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs
      .getKeys()
      .where(
        (key) => key == kPluginStateKey || key.startsWith(kPluginStoragePrefix),
      )
      .toList();
  for (final key in keys) {
    await prefs.remove(key);
  }
}
