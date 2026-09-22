import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:komet/backend/modules/messages.dart';
import 'package:komet/frontend/widgets/glass/glass_capsule.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glossy_pill.dart';
import '../../../../../core/config/app_fonts.dart';

class SelectionTopBar extends StatelessWidget {
  final ColorScheme cs;
  final Set<String> selected;
  final bool glossy;
  final List<CachedMessage> copyMsgs;
  final CachedMessage? editMsg;
  final VoidCallback onClear;
  final void Function(List<CachedMessage>) onCopy;
  final void Function(CachedMessage) onEdit;
  final VoidCallback onDelete;

  const SelectionTopBar({
    super.key,
    required this.cs,
    required this.selected,
    required this.glossy,
    required this.copyMsgs,
    required this.editMsg,
    required this.onClear,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final count = selected.length;
    final label = 'Выбрано $count';

    if (!glossy) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Symbols.close, color: cs.onSurface),
              onPressed: onClear,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: displayFontOf(context),
                ),
              ),
            ),
            if (copyMsgs.isNotEmpty)
              IconButton(
                icon: Icon(Symbols.content_copy, color: cs.onSurface),
                onPressed: () => onCopy(copyMsgs),
              ),
            if (editMsg != null)
              IconButton(
                icon: Icon(Symbols.edit, color: cs.onSurface),
                onPressed: () => onEdit(editMsg!),
              ),
            IconButton(
              icon: Icon(Symbols.delete, color: cs.onSurface),
              onPressed: onDelete,
            ),
          ],
        ),
      );
    }

    final ios = IosGlass.of(context);
    final size = ios ? 46.0 : 56.0;
    Widget actionBtn(IconData icon, VoidCallback onTap) => ios
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 46,
              child: Center(
                child: Icon(icon, size: 22, weight: 500, color: cs.onSurface),
              ),
            ),
          )
        : IconButton(
            icon: Icon(icon, weight: 500, color: cs.onSurface),
            onPressed: onTap,
          );
    Widget pill({
      required Widget child,
      VoidCallback? onTap,
      EdgeInsetsGeometry padding = EdgeInsets.zero,
    }) => ios
        ? GlassCapsule(onTap: onTap, padding: padding, child: child)
        : GlossyPill(onTap: onTap, padding: padding, child: child);

    return Padding(
      padding: ios
          ? const EdgeInsets.fromLTRB(12, 3, 12, 7)
          : const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Row(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: pill(
              onTap: onClear,
              child: Center(
                child: Icon(
                  Symbols.close,
                  color: cs.onSurface,
                  weight: 500,
                  size: ios ? 21 : 24,
                ),
              ),
            ),
          ),
          SizedBox(width: ios ? 6 : 8),
          Expanded(
            child: pill(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: size,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: ios ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: displayFontOf(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: ios ? 6 : 8),
          pill(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SizedBox(
              height: size,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (copyMsgs.isNotEmpty)
                    actionBtn(Symbols.content_copy, () => onCopy(copyMsgs)),
                  if (editMsg != null)
                    actionBtn(Symbols.edit, () => onEdit(editMsg!)),
                  actionBtn(Symbols.delete, onDelete),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectionBottomBar extends StatelessWidget {
  final ColorScheme cs;
  final Set<String> selected;
  final VoidCallback onReply;
  final VoidCallback onForward;
  final bool allowForward;
  final bool allowReply;

  const SelectionBottomBar({
    super.key,
    required this.cs,
    required this.selected,
    required this.onReply,
    required this.onForward,
    this.allowForward = true,
    this.allowReply = true,
  });

  @override
  Widget build(BuildContext context) {
    final showReply = allowReply && selected.length == 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (showReply) ...[
              Expanded(
                child: _pill(
                  context,
                  cs,
                  icon: Symbols.reply,
                  label: 'Ответить',
                  iconLeading: false,
                  onTap: onReply,
                ),
              ),
              if (allowForward) const SizedBox(width: 12),
            ] else
              const Spacer(),
            if (allowForward)
              Expanded(
                child: _pill(
                  context,
                  cs,
                  icon: Symbols.forward,
                  label: 'Переслать',
                  iconLeading: true,
                  onTap: onForward,
                ),
              )
            else if (!showReply)
              const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _pill(
    BuildContext context,
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required bool iconLeading,
    required VoidCallback onTap,
  }) {
    final textWidget = Text(
      label,
      style: TextStyle(
        color: cs.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: displayFontOf(context),
      ),
    );
    final iconWidget = Icon(icon, color: cs.onSurface, size: 22, weight: 500);
    if (IosGlass.of(context)) {
      return GlassCapsule(
        key: ValueKey('ios-selection-$label'),
        height: 46,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: iconLeading
              ? [iconWidget, const SizedBox(width: 8), textWidget]
              : [textWidget, const SizedBox(width: 8), iconWidget],
        ),
      );
    }
    return GlossyPill(
      onTap: onTap,
      color: Color.alphaBlend(
        cs.surfaceContainerHighest.withValues(alpha: 0.92),
        cs.surface,
      ),
      borderRadius: BorderRadius.circular(28),
      depth: 8,
      borderSide: BorderSide(
        color: cs.outlineVariant.withValues(alpha: 0.5),
        width: 0.5,
      ),
      child: SizedBox(
        height: 54,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: iconLeading
              ? [iconWidget, const SizedBox(width: 8), textWidget]
              : [textWidget, const SizedBox(width: 8), iconWidget],
        ),
      ),
    );
  }
}
