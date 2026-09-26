import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/build_profile.dart';

void main() {
  test('KOMET_APPSTORE is off unless the release build sets it', () {
    const defined = bool.hasEnvironment('KOMET_APPSTORE');
    if (defined) {
      expect(BuildProfile.isAppStoreBuild, isTrue);
      expect(BuildProfile.devTools, isFalse);
      expect(BuildProfile.selfUpdate, isFalse);
    } else {
      expect(BuildProfile.isAppStoreBuild, isFalse);
      expect(BuildProfile.devTools, isTrue);
      expect(BuildProfile.selfUpdate, isTrue);
    }
  });
}
