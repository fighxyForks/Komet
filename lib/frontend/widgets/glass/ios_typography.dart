import 'package:flutter/painting.dart';

abstract final class IosTypography {
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;

  static const List<FontFeature> tabularDigits = [FontFeature.tabularFigures()];

  static const double chatTitle = 16;
  static const double chatPreview = 15;
  static const double chatTime = 14;
  static const double chatBadge = 12;
  static const double chatBadgeDiameter = 20;
  static const double folderLabel = 14;

  static const double headerTitle = 17;
  static const double headerSubtitle = 13;

  static const double body = 17;
  static const double caption = 17;
  static const double forwarded = 14;
  static const double dateHeader = 13;
  static const double service = 13;
  static const double reactionCount = 11;
  static const double linkPreview = 14;
  static const double fileName = 16;
  static const double fileDetails = 13;

  static const double composer = 17;

  static const double listTitle = 17;
  static const double listSubtitle = 15;
  static const double sectionHeader = 13;
  static const double footer = 13;
}
