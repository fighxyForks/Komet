import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komet/core/config/app_fonts.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_tracking.dart';
import 'package:komet/frontend/widgets/glass/ios_typography.dart';
import 'package:komet/frontend/widgets/section_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

TextTheme get _m3 => Typography.material2021().englishLike;

void main() {
  group('iosSfTracking', () {
    test('17pt matches Apple HIG (−0.43)', () {
      expect(iosSfTracking(17), closeTo(-0.43, 0.001));
    });

    test('table anchors', () {
      expect(iosSfTracking(11), closeTo(0.06, 0.001));
      expect(iosSfTracking(12), closeTo(0.0, 0.001));
      expect(iosSfTracking(13), closeTo(-0.08, 0.001));
      expect(iosSfTracking(14), closeTo(-0.15, 0.001));
      expect(iosSfTracking(16), closeTo(-0.31, 0.001));
      expect(iosSfTracking(20), closeTo(-0.45, 0.001));
      expect(iosSfTracking(22), closeTo(-0.26, 0.001));
      expect(iosSfTracking(28), closeTo(0.38, 0.001));
      expect(iosSfTracking(34), closeTo(0.40, 0.001));
    });

    test('interpolates between anchors', () {
      final mid = iosSfTracking(16.5);
      expect(mid, lessThan(iosSfTracking(16)));
      expect(mid, greaterThan(iosSfTracking(17)));
      expect(mid, closeTo((-0.31 + -0.43) / 2, 0.001));
    });

    test('clamps outside the table', () {
      expect(iosSfTracking(1), iosSfTracking(6));
      expect(iosSfTracking(200), iosSfTracking(80));
    });
  });

  group('iosInterTracking', () {
    test('17pt is modestly negative (Dynamic Metrics)', () {
      expect(iosInterTracking(17), closeTo(-0.217, 0.01));
      expect(iosInterTracking(17), lessThan(0));
    });
  });

  group('iosLetterSpacing', () {
    test('system font uses SF table', () {
      expect(iosLetterSpacing(fontSize: 17), closeTo(-0.43, 0.001));
      expect(
        iosLetterSpacing(fontSize: 17, fontFamily: null),
        closeTo(-0.43, 0.001),
      );
    });

    test('Inter uses Dynamic Metrics', () {
      expect(
        iosLetterSpacing(fontSize: 17, fontFamily: 'Inter'),
        closeTo(iosInterTracking(17), 0.001),
      );
    });

    test('other custom fonts strip Material spacing to 0', () {
      expect(iosLetterSpacing(fontSize: 17, fontFamily: 'Unbounded'), 0);
      expect(iosLetterSpacing(fontSize: 17, fontFamily: 'Roboto'), 0);
    });
  });

  group('AppFonts.textTheme iOS transform', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AppIosGlass.debugReset();
      await AppIosGlass.load();
    });

    tearDown(AppIosGlass.debugReset);

    test('on iOS glass, body styles use SF tracking (≤ 0)', () {
      AppIosGlass.debugSetSupported(true);
      expect(AppIosGlass.active.value, isTrue);

      expect(_m3.bodyLarge!.letterSpacing, greaterThan(0));
      expect(_m3.bodyMedium!.letterSpacing, greaterThan(0));

      final themed = AppFonts.textTheme('system', _m3);
      expect(themed.bodyLarge!.letterSpacing, lessThanOrEqualTo(0));
      expect(themed.bodyMedium!.letterSpacing, lessThanOrEqualTo(0));
      expect(
        themed.bodyLarge!.letterSpacing,
        closeTo(iosSfTracking(_m3.bodyLarge!.fontSize!), 0.001),
      );
      expect(
        themed.bodyMedium!.letterSpacing,
        closeTo(iosSfTracking(_m3.bodyMedium!.fontSize!), 0.001),
      );
    });

    test('on Android / glass off, Material defaults stay', () {
      AppIosGlass.debugSetSupported(false);
      expect(AppIosGlass.active.value, isFalse);

      final themed = AppFonts.textTheme('system', _m3);
      expect(themed.bodyLarge!.letterSpacing, _m3.bodyLarge!.letterSpacing);
      expect(themed.bodyMedium!.letterSpacing, _m3.bodyMedium!.letterSpacing);
      expect(themed.bodyLarge!.letterSpacing, 0.5);
      expect(themed.bodyMedium!.letterSpacing, 0.25);
    });

    test('Inter on iOS glass uses Inter Dynamic Metrics', () {
      AppIosGlass.debugSetSupported(true);
      final themed = AppFonts.textTheme('inter', _m3);
      expect(themed.bodyLarge!.fontFamily, 'Inter');
      expect(
        themed.bodyLarge!.letterSpacing,
        closeTo(iosInterTracking(_m3.bodyLarge!.fontSize!), 0.001),
      );
    });
  });

  group('effective letterSpacing under ThemeData', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AppIosGlass.debugReset();
      await AppIosGlass.load();
    });

    tearDown(() {
      AppIosGlass.debugReset();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('17pt Text under iOS theme has negative effective spacing', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      AppIosGlass.debugSetSupported(true);

      final textTheme = AppFonts.textTheme('system', _m3);

      try {
        await tester.pumpWidget(
          IosGlass(
            child: MaterialApp(
              theme: ThemeData(useMaterial3: true, textTheme: textTheme),
              home: const Scaffold(
                body: Text('Hello tracking', style: TextStyle(fontSize: 17)),
              ),
            ),
          ),
        );

        final rich = tester.widget<RichText>(
          find.descendant(
            of: find.text('Hello tracking'),
            matching: find.byType(RichText),
          ),
        );
        final effective = rich.text.style?.letterSpacing;
        expect(effective, isNotNull);
        expect(effective!, lessThanOrEqualTo(0));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
      'message-sized style with explicit helper is SF −0.43 at 17pt',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        AppIosGlass.debugSetSupported(true);

        final textTheme = AppFonts.textTheme('system', _m3);
        const size = 17.0;

        try {
          await tester.pumpWidget(
            IosGlass(
              child: MaterialApp(
                theme: ThemeData(useMaterial3: true, textTheme: textTheme),
                home: Scaffold(
                  body: Text(
                    'Bubble text',
                    style: TextStyle(
                      fontSize: size,
                      letterSpacing: iosLetterSpacing(fontSize: size),
                    ),
                  ),
                ),
              ),
            ),
          );

          final rich = tester.widget<RichText>(
            find.descendant(
              of: find.text('Bubble text'),
              matching: find.byType(RichText),
            ),
          );
          expect(rich.text.style?.letterSpacing, closeTo(-0.43, 0.001));
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'section header local letterSpacing stays null; effective is non-positive',
      (tester) async {
        AppIosGlass.debugSetSupported(true);

        final textTheme = AppFonts.textTheme('system', _m3);

        await tester.pumpWidget(
          IosGlass(
            child: MaterialApp(
              theme: ThemeData(useMaterial3: true, textTheme: textTheme),
              home: const Scaffold(body: SectionHeader('Секция')),
            ),
          ),
        );

        final local = tester.widget<Text>(find.text('Секция')).style!;
        expect(local.letterSpacing, isNull);
        expect(local.fontSize, IosTypography.sectionHeader);

        final rich = tester.widget<RichText>(
          find.descendant(
            of: find.text('Секция'),
            matching: find.byType(RichText),
          ),
        );
        final effective = rich.text.style?.letterSpacing;
        expect(effective, isNotNull);
        expect(
          effective!,
          lessThanOrEqualTo(0),
          reason: 'DefaultTextStyle must no longer leak Material +spacing',
        );
      },
    );
  });
}
