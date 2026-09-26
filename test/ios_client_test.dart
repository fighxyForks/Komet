import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/ios_client.dart';

void main() {
  test('iOS handshake uses the real model name', () {
    expect(
      IosClient.deviceTitle(
        modelName: 'iPhone 16 Pro',
        model: 'iPhone',
        machine: 'iPhone17,1',
      ),
      'iPhone 16 Pro',
    );
  });

  test('unknown model falls back to the hardware id', () {
    expect(
      IosClient.deviceTitle(
        modelName: 'Unknown device',
        model: 'iPhone',
        machine: 'iPhone18,2',
      ),
      'iPhone18,2',
    );
  });

  test('os label keeps the platform name and the installed version', () {
    expect(
      IosClient.osLabel(systemName: 'iOS', systemVersion: '18.6.2'),
      'iOS 18.6.2',
    );
  });

  test('screen label uses pixels and the real scale', () {
    expect(
      IosClient.screenLabel(width: 1179, height: 2556, scale: 3),
      '1179x2556 3.0x',
    );
    expect(IosClient.screenLabel(width: 0, height: 2556, scale: 3), isEmpty);
  });

  test('iOS client version is 26.33.1', () {
    expect(IosClient.appVersion, '26.33.1');
    expect(IosClient.deviceType, 'IOS');
  });
}
