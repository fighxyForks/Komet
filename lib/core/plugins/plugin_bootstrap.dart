import 'plugin_availability.dart';
import 'plugin_cleanup.dart';
import 'plugin_store.dart';

Future<void> loadPlugins() async {
  if (!kPluginsCompiled) {
    await discardDownloadedPlugins();
    return;
  }
  await PluginStore.instance.load();
}
