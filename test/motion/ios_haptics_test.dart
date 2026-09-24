import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/motion/ios_haptics.dart';

void main() {
  test('IosHaptics semantic methods are callable', () {
    IosHaptics.selectionChange();
    IosHaptics.swipeToReplyThreshold();
    IosHaptics.dismissThreshold();
    IosHaptics.menuOpen();
    IosHaptics.longPress();
    IosHaptics.toggle();
    IosHaptics.itemActivate();
    IosHaptics.destructiveActivate();
  });
}
