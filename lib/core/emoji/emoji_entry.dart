import 'emoji_category.dart';

class EmojiEntry {
  final String glyph;
  final String name;
  final EmojiCategory category;
  final int versionTenths;
  final bool skinToneCapable;
  final List<String> skinToneVariants;
  final List<String> keywords;

  const EmojiEntry({
    required this.glyph,
    required this.name,
    required this.category,
    required this.versionTenths,
    required this.skinToneCapable,
    required this.skinToneVariants,
    required this.keywords,
  });

  String get versionLabel {
    final major = versionTenths ~/ 10;
    final minor = versionTenths % 10;
    return '$major.$minor';
  }
}
