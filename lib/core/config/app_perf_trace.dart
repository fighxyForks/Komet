import 'package:flutter/foundation.dart';

import '../utils/perf_trace.dart';
import 'persisted_setting.dart';

class AppPerfTrace {
  static const prefKey = 'dev_perf_trace';
  static const bool defaultValue = false;

  static final _setting = PersistedSetting<bool>(
    prefKey: prefKey,
    defaultValue: defaultValue,
    read: (prefs, key) => prefs.getBool(key),
    write: (prefs, key, value) async {
      await prefs.setBool(key, value);
    },
  );

  static ValueNotifier<bool> get current => _setting.current;

  static Future<bool> load() async {
    final value = await _setting.load();
    PerfTrace.instance.setEnabled(value);
    return value;
  }

  static Future<void> save(bool value) async {
    await _setting.save(value);
    PerfTrace.instance.setEnabled(value);
  }
}
