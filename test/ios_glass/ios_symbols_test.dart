import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_empty_state.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_symbols.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIosGlass.debugReset();
    await AppIosGlass.load();
  });

  tearDown(AppIosGlass.debugReset);

  test('the Cupertino icon font ships with the app', () async {
    const family =
        'packages/${CupertinoIcons.iconFontPackage}/${CupertinoIcons.iconFont}';
    final manifest = await rootBundle.loadString('FontManifest.json');
    expect(manifest, contains('"family":"$family"'));
  });

  testWidgets('IosSymbols resolves Cupertino icons in iOS mode', (tester) async {
    AppIosGlass.debugSetSupported(true);
    late IconData resolved;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => IosGlass(child: child!),
        home: Builder(
          builder: (context) {
            resolved = IosSymbols.search(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(resolved, CupertinoIcons.search);
  });

  testWidgets('IosSymbols keeps Material icons off iOS', (tester) async {
    late IconData resolved;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => IosGlass(child: child!),
        home: Builder(
          builder: (context) {
            resolved = IosSymbols.search(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(resolved, Symbols.search);
  });

  testWidgets('IosEmptyState renders message', (tester) async {
    AppIosGlass.debugSetSupported(true);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => IosGlass(child: child!),
        home: const Scaffold(
          body: IosEmptyState(
            icon: CupertinoIcons.person_crop_circle,
            message: 'Нет контактов',
          ),
        ),
      ),
    );
    expect(find.text('Нет контактов'), findsOneWidget);
  });
}
