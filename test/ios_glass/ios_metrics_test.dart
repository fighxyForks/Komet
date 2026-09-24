import 'package:flutter_test/flutter_test.dart';
import 'package:komet/frontend/widgets/glass/glass_controls.dart';
import 'package:komet/frontend/widgets/glass/glass_menu.dart';
import 'package:komet/frontend/widgets/glass/ios_metrics.dart';
import 'package:komet/frontend/widgets/settings_card.dart';

void main() {
  group('IosMetrics', () {
    test('hit target is at least 44 pt', () {
      expect(IosMetrics.minHitTarget, greaterThanOrEqualTo(44));
      expect(GlassMenuStyle.rowHeight, IosMetrics.minHitTarget);
      expect(IosFlatSearchBar(hint: 'x').height, IosMetrics.searchBarHeight);
      expect(IosFlatSearchBar(hint: 'x').height, greaterThanOrEqualTo(44));
      expect(IosGroupedSection.defaultRadius, IosMetrics.groupedRadius);
    });

    test('radius scale is concentric', () {
      expect(IosMetrics.controlRadius, lessThan(IosMetrics.groupedRadius));
      expect(IosMetrics.groupedRadius, lessThan(IosMetrics.sheetRadius));
      expect(
        IosMetrics.menuRadius,
        lessThanOrEqualTo(IosMetrics.groupedRadius),
      );
    });
  });
}
