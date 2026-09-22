import 'package:flutter/widgets.dart';

class ChatMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool dividerAfter;
  final bool destructive;

  const ChatMenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.showChevron = false,
    this.dividerAfter = false,
    this.destructive = false,
  });
}
