import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/native/native_menu_button.dart';

void main() {
  test('items encode everything the native menu reads', () {
    const item = NativeMenuItem(
      id: '42',
      title: 'Профиль',
      subtitle: '+70000000000',
      symbol: 'person.crop.circle',
      imageUrl: 'https://example.test/a.png',
      checked: true,
    );
    expect(item.toMap(), {
      'id': '42',
      'title': 'Профиль',
      'subtitle': '+70000000000',
      'symbol': 'person.crop.circle',
      'imageUrl': 'https://example.test/a.png',
      'checked': true,
      'destructive': false,
    });
  });

  test('separator encodes as a section break', () {
    const separator = NativeMenuItem.separator();
    expect(separator.isSeparator, isTrue);
    expect(separator.toMap(), {'separator': true});
  });

  test('equal items compare equal so the menu is not resent', () {
    expect(
      const NativeMenuItem(id: 'a', title: 'A'),
      const NativeMenuItem(id: 'a', title: 'A'),
    );
    expect(
      const NativeMenuItem(id: 'a', title: 'A'),
      isNot(const NativeMenuItem(id: 'a', title: 'A', checked: true)),
    );
  });
}
