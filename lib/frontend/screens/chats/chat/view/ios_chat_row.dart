import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../widgets/glass/ios_typography.dart';
import '../../../../widgets/glass/ios_tracking.dart';
import '../../../../widgets/glass/ios_palette.dart';

class IosChatRow extends StatelessWidget {
  static const double height = 78;
  static const double avatarSize = 60;
  static const double textInset = 86;

  final Widget avatar;
  final String name;
  final String time;
  final IconData? titleIcon;
  final bool isVerified;
  final bool isMuted;
  final bool isPinned;
  final bool isSelected;
  final Widget? statusIcon;
  final String sender;
  final Widget body;
  final int unreadCount;
  final bool hasMention;
  final Widget? miniApp;

  const IosChatRow({
    super.key,
    required this.avatar,
    required this.name,
    required this.time,
    required this.body,
    this.titleIcon,
    this.isVerified = false,
    this.isMuted = false,
    this.isPinned = false,
    this.isSelected = false,
    this.statusIcon,
    this.sender = '',
    this.unreadCount = 0,
    this.hasMention = false,
    this.miniApp,
  });

  static String compactCount(int count) {
    if (count < 1000) return '$count';
    final value = count / 1000;
    final text = value >= 100
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    final trimmed = text.endsWith('.0')
        ? text.substring(0, text.length - 2)
        : text;
    return '${trimmed}K';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fontFamily = Theme.of(context).textTheme.bodyLarge?.fontFamily;
    final secondary = IosPalette.secondaryLabel(cs);
    final background = isSelected
        ? Color.alphaBlend(
            cs.primary.withValues(alpha: 0.08),
            IosPalette.background(cs),
          )
        : isPinned
        ? IosPalette.grouped(cs)
        : IosPalette.background(cs);
    final trailing = _trailing(context, cs, secondary);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: background,
      height: height,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: Center(child: avatar),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _titleRow(context, cs, secondary),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (sender.isNotEmpty)
                                      Text(
                                        sender,
                                        key: const ValueKey('ios-chat-sender'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: IosPalette.label(cs),
                                          fontSize: IosTypography.chatPreview,
                                          fontWeight: IosTypography.regular,
                                          height: 1.25,
                                          letterSpacing: iosLetterSpacing(
                                            fontSize: IosTypography.chatPreview,
                                            fontFamily: fontFamily,
                                          ),
                                        ),
                                      ),
                                    body,
                                  ],
                                ),
                              ),
                              if (trailing != null) ...[
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: trailing,
                                ),
                              ],
                              if (miniApp != null) ...[
                                const SizedBox(width: 8),
                                miniApp!,
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: textInset,
            right: 0,
            bottom: 0,
            child: Container(
              height: 1 / MediaQuery.devicePixelRatioOf(context),
              color: IosPalette.separator(cs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleRow(BuildContext context, ColorScheme cs, Color secondary) {
    final fontFamily = Theme.of(context).textTheme.bodyLarge?.fontFamily;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (titleIcon != null) ...[
                Icon(
                  titleIcon,
                  color: secondary,
                  size: 16,
                  weight: 500,
                  fill: 1,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: IosPalette.label(cs),
                    fontSize: IosTypography.chatTitle,
                    fontWeight: IosTypography.semibold,
                    height: 1.2,
                    letterSpacing: iosLetterSpacing(
                      fontSize: IosTypography.chatTitle,
                      fontFamily: fontFamily,
                    ),
                  ),
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 4),
                Icon(Symbols.verified, color: cs.primary, size: 16, fill: 1),
              ],
              if (isMuted) ...[
                const SizedBox(width: 4),
                Icon(
                  Symbols.volume_off,
                  key: const ValueKey('ios-chat-muted'),
                  color: secondary,
                  size: 16,
                  fill: 1,
                ),
              ],
            ],
          ),
        ),
        if (statusIcon != null)
          KeyedSubtree(
            key: const ValueKey('ios-chat-status'),
            child: statusIcon!,
          ),
        const SizedBox(width: 4),
        Text(
          time,
          key: const ValueKey('ios-chat-time'),
          style: TextStyle(
            color: secondary,
            fontSize: IosTypography.chatTime,
            fontWeight: IosTypography.regular,
            height: 1.2,
            fontFeatures: IosTypography.tabularDigits,
            letterSpacing: iosLetterSpacing(
              fontSize: IosTypography.chatTime,
              fontFamily: fontFamily,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _trailing(BuildContext context, ColorScheme cs, Color secondary) {
    final fontFamily = Theme.of(context).textTheme.bodyLarge?.fontFamily;
    if (unreadCount > 0 || hasMention) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasMention) _badge(cs, '@', fontFamily),
          if (hasMention && unreadCount > 0) const SizedBox(width: 4),
          if (unreadCount > 0) _badge(cs, compactCount(unreadCount), fontFamily),
        ],
      );
    }
    if (!isPinned) return null;
    return Icon(
      Symbols.keep,
      key: const ValueKey('ios-chat-pin'),
      size: 20,
      fill: 1,
      color: secondary,
    );
  }

  Widget _badge(ColorScheme cs, String label, String? fontFamily) {
    return Container(
      key: ValueKey('ios-chat-badge-$label'),
      height: IosTypography.chatBadgeDiameter,
      constraints: const BoxConstraints(
        minWidth: IosTypography.chatBadgeDiameter,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isMuted ? IosPalette.mutedBadge(cs) : cs.primary,
        borderRadius: BorderRadius.circular(
          IosTypography.chatBadgeDiameter / 2,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isMuted ? Colors.white : cs.onPrimary,
          fontSize: IosTypography.chatBadge,
          fontWeight: IosTypography.semibold,
          height: 1,
          fontFeatures: IosTypography.tabularDigits,
          letterSpacing: iosLetterSpacing(
            fontSize: IosTypography.chatBadge,
            fontFamily: fontFamily,
          ),
        ),
      ),
    );
  }
}
