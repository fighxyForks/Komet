import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'glass_capsule.dart';
import 'ios_glass.dart';

class GlassSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const GlassSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (!IosGlass.of(context)) {
      return Switch(value: value, onChanged: onChanged);
    }
    final cs = Theme.of(context).colorScheme;
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: cs.primary,
    );
  }
}

class GlassSearchCapsule extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  final double height;

  const GlassSearchCapsule({
    super.key,
    required this.hint,
    this.onTap,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: onTap != null,
      label: hint,
      child: GlassCapsule(
        height: height,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(
              Symbols.search,
              size: 20,
              weight: 500,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassSegmentThumb extends StatelessWidget {
  final double radius;

  const GlassSegmentThumb({super.key, required this.radius});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = cs.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: GlassStyle.rim(cs), width: 0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
