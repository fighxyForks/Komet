import 'package:flutter/material.dart';
import 'package:komet/frontend/widgets/glass/ios_symbols.dart';

class ChatCallBadge extends StatelessWidget {
  final Color borderColor;
  final double size;

  const ChatCallBadge({super.key, required this.borderColor, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.primary,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Icon(IosSymbols.phone(context),
        fill: 1,
        size: size * 0.55,
        color: cs.onPrimary,
      ),
    );
  }
}
