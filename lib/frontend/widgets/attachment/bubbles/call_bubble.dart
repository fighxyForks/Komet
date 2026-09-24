import 'package:flutter/material.dart';
import 'package:komet/frontend/widgets/glass/ios_symbols.dart';

import '../../../../core/utils/format.dart';
import '../../../../models/attachment.dart';
import 'bubble_context.dart';

class CallBubble extends StatelessWidget {
  final BubbleContext ctx;
  final CallAttachment call;

  const CallBubble({super.key, required this.ctx, required this.call});

  @override
  Widget build(BuildContext context) {
    final isMe = ctx.isMe;
    final missed = call.isMissedOrFailed;
    final accent = isMe ? ctx.cs.onPrimaryContainer : ctx.cs.primary;
    final iconColor = missed ? ctx.cs.error : accent;

    final IconData icon;
    final String label;
    if (call.isGroup) {
      icon = call.isVideo ? IosSymbols.videocam(ctx.context) : IosSymbols.group(ctx.context);
      label = call.isVideo ? 'Групповой видеозвонок' : 'Групповой звонок';
    } else if (call.isVideo) {
      icon = IosSymbols.videocam(ctx.context);
      label = missed
          ? (isMe ? 'Отменённый видеозвонок' : 'Пропущенный видеозвонок')
          : (isMe ? 'Исходящий видеозвонок' : 'Входящий видеозвонок');
    } else {
      icon = IosSymbols.phone(ctx.context);
      label = missed
          ? (isMe ? 'Отменённый звонок' : 'Пропущенный звонок')
          : (isMe ? 'Исходящий звонок' : 'Входящий звонок');
    }

    final directionIcon = isMe ? IosSymbols.callMade(ctx.context) : IosSymbols.callReceived(ctx.context);

    final subtitle = missed
        ? ctx.clockText
        : '${ctx.clockText} · ${formatSecondsMmSs((call.durationMs / 1000).round())}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: missed
                  ? ctx.cs.error.withValues(alpha: 0.12)
                  : (isMe ? ctx.systemTint : ctx.cs.primaryContainer),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ctx.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      directionIcon,
                      size: 13,
                      color: missed ? ctx.cs.error : ctx.dim,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: ctx.dim,
                        fontSize: 12,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
