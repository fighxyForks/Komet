import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/screens/contacts/contacts_tab.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
  });

  tearDown(AppIosGlass.debugReset);

  Future<void> pumpButton(WidgetTester tester, {required bool ios}) async {
    if (ios) AppIosGlass.debugSetSupported(true);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => IosGlass(child: child!),
        home: Scaffold(
          body: ContactsNfcExchangeButton(onPressed: () {}),
        ),
      ),
    );
  }

  testWidgets('NFC exchange button hidden in iOS glass mode', (tester) async {
    await pumpButton(tester, ios: true);
    expect(find.byKey(const ValueKey('contacts-nfc-exchange')), findsNothing);
  });

  testWidgets('NFC exchange button visible in Material mode', (tester) async {
    await pumpButton(tester, ios: false);
    expect(find.byKey(const ValueKey('contacts-nfc-exchange')), findsOneWidget);
  });
}
