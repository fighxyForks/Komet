import 'dart:math' as math;

import 'package:flutter/widgets.dart';

abstract final class IosBubbleMetrics {
  static const double compactWidthBoundary = 500;
  static const double compactInset = 36;
  static const double freeFillFactor = 0.85;
  static const double edgeInset = 3;
  static const double contentInsets = 6;
  static const double avatarSize = 34;
  static const double avatarGap = 4;
  static const double avatarInset = avatarSize + avatarGap;

  static const Duration mergeWindow = Duration(minutes: 10);
  static const double mergedSpacing = 0.5;
  static const double groupSpacing = 2;

  static const double textSize = 17;
  static const double textHeight = 1.25;
  static const EdgeInsets textPadding = EdgeInsets.fromLTRB(11, 7, 11, 8);
  static const double timeSize = 11;
  static const double statusGap = 5;
  static const double senderNameSize = 14;

  static double maxBubbleWidth(double listWidth, {required bool avatarSlot}) {
    final fill = listWidth <= compactWidthBoundary
        ? listWidth - compactInset
        : (listWidth * freeFillFactor).floorToDouble();
    final width =
        fill - edgeInset * 3 - contentInsets - (avatarSlot ? avatarInset : 0);
    return math.max(1, width);
  }
}
