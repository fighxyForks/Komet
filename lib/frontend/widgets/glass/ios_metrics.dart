/// Shared iOS 26 / HIG layout tokens for Liquid Glass mode.
///
/// Material mode keeps using [AppShape] and local constants; these values are
/// only applied behind [IosGlass.of].
abstract final class IosMetrics {
  /// Minimum interactive control size (Apple HIG).
  static const double minHitTarget = 44;

  /// Continuous corner for small controls (chips, icon buttons, fields).
  static const double controlRadius = 14;

  /// Inset grouped list / settings section corner.
  static const double groupedRadius = 20;

  /// Modal sheet top corners (inset continuous).
  static const double sheetRadius = 28;

  /// Capsule / pill chrome (search field, tab bar).
  static const double capsuleRadius = 100;

  /// Context menu / glass menu panel.
  static const double menuRadius = 14;

  /// 8-pt spacing grid.
  static const double space1 = 8;
  static const double space2 = 16;
  static const double space3 = 24;
  static const double space4 = 32;

  /// Horizontal inset for inset-grouped lists.
  static const double listHorizontalInset = 16;

  /// Leading inset for separators under an icon+label row (icon 30 + gap 16 + pad).
  static const double separatorLeadingInset = 62;

  /// Default search-field height (system search bars sit at 36–44).
  static const double searchBarHeight = 44;

  /// Sheet grabber metrics.
  static const double grabberWidth = 36;
  static const double grabberHeight = 5;
}
