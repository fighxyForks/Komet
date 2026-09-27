import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/screens/contacts/native_contact_cards.dart';

void main() {
  test('поиск контакта затемняет светлый список, а не заливает его чёрным', () {
    final light = contactLookupScrim(Brightness.light);
    final dark = contactLookupScrim(Brightness.dark);
    expect(light.a, inInclusiveRange(0.2, 0.4));
    expect(dark.a, greaterThan(light.a));
  });
}
