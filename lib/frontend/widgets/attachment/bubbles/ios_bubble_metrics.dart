import 'dart:math' as math;

// #***! размеры баблов на iOS, остальные платформы на прежних значениях
abstract final class IosBubbleMetrics {
  static const double compactWidthBoundary = 500;
  static const double compactInset = 36;
  static const double freeFillFactor = 0.85;
  static const double edgeInset = 3;
  static const double contentInsets = 6;
  static const double avatarSize = 34;
  static const double avatarGap = 4;
  static const double avatarInset = avatarSize + avatarGap;

  // #***! на телефоне ширина списка минус 36, шире 500 — 0,85 списка,
  // #***! дальше вычитаем отступы и место под аватар в группах
  static double maxBubbleWidth(double listWidth, {required bool avatarSlot}) {
    final fill = listWidth <= compactWidthBoundary
        ? listWidth - compactInset
        : (listWidth * freeFillFactor).floorToDouble();
    final width =
        fill - edgeInset * 3 - contentInsets - (avatarSlot ? avatarInset : 0);
    return math.max(1, width);
  }
}
