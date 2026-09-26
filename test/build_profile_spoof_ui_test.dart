import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/build_profile.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('spoofing settings stay hidden on iOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(BuildProfile.spoofUi, isFalse);
  });

  test('spoofing settings are shown on Android outside public releases', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(BuildProfile.spoofUi, !BuildProfile.isStore);
  });
}
