import '../config/build_profile.dart';

const bool kPluginsCompiled =
    bool.fromEnvironment('KOMET_PLUGINS', defaultValue: true) &&
    !BuildProfile.isAppStoreBuild;

const String kPluginStateKey = 'plugins_state_v1';

const String kPluginStoragePrefix = 'plugin_storage_v1_';
