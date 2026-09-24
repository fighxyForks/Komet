
import 'package:flutter/widgets.dart';

class ChatMenuItem {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool dividerAfter;
  final bool destructive;
  final bool enabled;
  final bool isSectionHeader;

  const ChatMenuItem({
    this.icon,
    required this.label,
    this.onTap,
    this.showChevron = false,
    this.dividerAfter = false,
    this.destructive = false,
    this.enabled = true,
    this.isSectionHeader = false,
  });
}
