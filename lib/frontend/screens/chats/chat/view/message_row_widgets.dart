import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:komet/backend/modules/animoji.dart' show AnimojiModule;
import 'package:komet/backend/modules/message_info.dart';
import 'package:komet/backend/modules/messages.dart' show CachedMessage;
import 'package:komet/core/config/app_show_extra_info.dart';
import 'package:komet/core/config/app_fonts.dart';
import 'package:komet/core/config/app_frost.dart';
import 'package:komet/core/config/app_ios_glass.dart';
import 'package:komet/core/config/app_message_actions_style.dart';
import 'package:komet/core/crypto/message_decryption_cache.dart';
import 'package:komet/core/utils/haptics.dart';
import 'package:komet/frontend/motion/ios_haptics.dart';
import 'package:komet/frontend/motion/ios_motion.dart';
import 'package:komet/core/utils/text_format.dart';
import 'package:komet/frontend/widgets/animated_text_swap.dart';
import 'package:komet/frontend/widgets/directional_drag_recognizer.dart';
import 'package:komet/frontend/widgets/glass/glass_capsule.dart';
import 'package:komet/frontend/widgets/glass/ios_glass.dart';
import 'package:komet/frontend/widgets/glass/ios_symbols.dart';
import 'package:komet/frontend/widgets/glass/ios_typography.dart';
import 'package:komet/frontend/widgets/liquid_glass.dart';
import 'package:komet/frontend/widgets/message_actions_overlay.dart'
    show
        MessageActionsController,
        MessageActionsInteraction,
        MessageReader,
        ReactionEmoji,
        showMessageActions;
import 'package:komet/frontend/widgets/rich_message_controller.dart';
import 'package:komet/frontend/widgets/selection_check_circle.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:komet/main.dart' show animojiModule;
import 'package:komet/models/animoji.dart' show Animoji;

class SwipeToReply extends StatefulWidget {
  final Widget child;
  final bool isMe;
  final VoidCallback onReply;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.isMe,
    required this.onReply,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  late final AnimationController _springBack;
  double _dragX = 0.0;
  double _rawX = 0.0;
  bool _triggered = false;

  double get _trigger => widget.isMe
      ? IosMotion.replyTriggerOutgoing
      : IosMotion.replyTriggerIncoming;

  @override
  void initState() {
    super.initState();
    _springBack = AnimationController.unbounded(vsync: this);
    _springBack.addListener(() => setState(() => _dragX = _springBack.value));
  }

  @override
  void dispose() {
    _springBack.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_springBack.isAnimating) {
      _springBack.stop();
      _rawX = _dragX;
    }
    var raw = _rawX + d.delta.dx;
    if (raw > 0) raw = 0;
    _rawX = raw;
    var visual = raw;
    if (IosMotion.reduceMotionOf(context)) {
      if (visual < -IosMotion.replyMaxVisual) {
        visual = -IosMotion.replyMaxVisual;
      }
    } else {
      visual = IosMotion.rubberBand(
        offset: raw,
        bandingStart: IosMotion.replyBandingStart,
        range: IosMotion.replyMaxVisual - IosMotion.replyBandingStart,
        coefficient: 0.45,
      );
      if (visual < -IosMotion.replyMaxVisual) {
        visual = -IosMotion.replyMaxVisual;
      }
    }
    final wasTriggered = _triggered;
    _triggered = raw <= -_trigger;
    if (_triggered && !wasTriggered) {
      if (IosGlass.of(context)) {
        IosHaptics.swipeToReplyThreshold();
      } else {
        Haptics.medium();
      }
    }
    setState(() => _dragX = visual);
  }

  void _onDragEnd(DragEndDetails d) {
    if (_triggered) widget.onReply();
    _settle();
  }

  void _onDragCancel() => _settle();

  void _settle() {
    _triggered = false;
    _rawX = 0;
    if (IosMotion.reduceMotionOf(context)) {
      setState(() => _dragX = 0);
      return;
    }
    _springBack.value = _dragX;
    animateSpring(_springBack, target: 0, spring: IosMotion.dismissSnap);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (-_dragX / _trigger).clamp(0.0, 1.0);
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        LeftwardDragRecognizer:
            GestureRecognizerFactoryWithHandlers<LeftwardDragRecognizer>(
              () => LeftwardDragRecognizer(debugOwner: this),
              (instance) {
                instance
                  ..onUpdate = _onDragUpdate
                  ..onEnd = _onDragEnd
                  ..onCancel = _onDragCancel;
              },
            ),
      },
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Positioned(
            right: 16,
            child: Opacity(
              opacity: progress,
              child: Transform.scale(
                scale: 0.6 + 0.4 * progress,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IosSymbols.reply(context),
                    size: 20,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(offset: Offset(_dragX, 0), child: widget.child),
        ],
      ),
    );
  }
}

class PinnedMessageBanner extends StatelessWidget {
  final String? text;
  final bool isPreview;
  final VoidCallback onTap;
  final VoidCallback? onUnpin;
  final bool floating;
  final bool frosted;
  final bool liquid;
  final BorderRadius? borderRadius;
  final BackdropKey? backdropKey;

  const PinnedMessageBanner({
    super.key,
    required this.text,
    required this.isPreview,
    required this.onTap,
    this.onUnpin,
    this.floating = false,
    this.borderRadius,
    this.frosted = false,
    this.liquid = false,
    this.backdropKey,
  });

  BorderRadius get _radius => borderRadius ?? BorderRadius.circular(16);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ios = IosGlass.of(context);
    final content = Material(
      color: ios
          ? Colors.transparent
          : frosted
          ? AppFrost.glassTint(cs)
          : floating
          ? cs.surfaceContainerHigh.withValues(alpha: 0.92)
          : cs.surfaceContainerHigh,
      borderRadius: floating ? _radius : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: ios ? 5 : 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: ios ? 28 : 34,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.pinnedMessageTitle,
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: ios ? IosTypography.callout : 14,
                        height: ios ? 1.15 : null,
                      ),
                    ),
                    SizedBox(height: ios ? 1 : 2),
                    PinnedMessageText(
                      text: text,
                      isPreview: isPreview,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              if (onUnpin != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    IosSymbols.close(context),
                    color: cs.onSurfaceVariant,
                  ),
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  onPressed: onUnpin,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final bottomBorder = Border(bottom: AppFrost.hairline(cs));

    if (ios) {
      return GlassCapsule(
        key: const ValueKey('ios-pinned-banner'),
        allowNative: false,
        borderRadius: floating
            ? (borderRadius ?? BorderRadius.circular(20))
            : BorderRadius.zero,
        shadow: floating,
        child: ClipRRect(
          borderRadius: floating
              ? (borderRadius ?? BorderRadius.circular(20))
              : BorderRadius.zero,
          child: content,
        ),
      );
    }

    if (frosted) {
      return GlassSurface(
        liquid: liquid,
        borderRadius: floating ? BorderRadius.circular(16) : BorderRadius.zero,
        frostTint: Colors.transparent,
        border: floating ? null : bottomBorder,
        backdropKey: backdropKey,
        child: content,
      );
    }

    if (!floating) {
      return DecoratedBox(
        decoration: BoxDecoration(border: bottomBorder),
        child: content,
      );
    }
    return content;
  }
}

class PinnedMessageText extends StatefulWidget {
  final String? text;
  final bool isPreview;
  final Color color;

  const PinnedMessageText({
    super.key,
    required this.text,
    required this.isPreview,
    required this.color,
  });

  @override
  State<PinnedMessageText> createState() => _PinnedMessageTextState();
}

class _PinnedMessageTextState extends State<PinnedMessageText> {
  late String? _primaryText;
  late bool _primaryIsPreview;
  late String? _secondaryText;
  late bool _secondaryIsPreview;
  bool _showSecondary = false;

  @override
  void initState() {
    super.initState();
    _primaryText = widget.text;
    _primaryIsPreview = widget.isPreview;
    _secondaryText = widget.text;
    _secondaryIsPreview = widget.isPreview;
  }

  @override
  void didUpdateWidget(covariant PinnedMessageText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text == oldWidget.text &&
        widget.isPreview == oldWidget.isPreview) {
      return;
    }
    if (_showSecondary) {
      _primaryText = widget.text;
      _primaryIsPreview = widget.isPreview;
    } else {
      _secondaryText = widget.text;
      _secondaryIsPreview = widget.isPreview;
    }
    _showSecondary = !_showSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedTextSwap(
        showAlternate: _showSecondary,
        alternate: _buildText(context, _secondaryText, _secondaryIsPreview),
        child: _buildText(context, _primaryText, _primaryIsPreview),
      ),
    );
  }

  Widget _buildText(BuildContext context, String? text, bool isPreview) {
    final label = text == null || text.isEmpty
        ? AppLocalizations.of(context)!.msgActionsNoText
        : text;
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: widget.color,
        fontSize: IosGlass.of(context) ? IosTypography.listSubtitle : 14,
      ),
    );
  }
}

class SelectableMessageRow extends StatefulWidget {
  final Widget child;
  final CachedMessage message;
  final bool isMe;
  final ValueListenable<Set<String>> selectedIds;
  final Animation<double> selectionAnim;
  final bool Function() isSelectionActive;
  final VoidCallback onToggleSelection;
  final VoidCallback onEnterSelection;
  final void Function(Offset globalPosition) onStartTextSelection;
  final void Function(Offset? globalPosition) onDragTextSelection;
  final VoidCallback onDelete;
  final bool allowDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final bool allowCopy;
  final VoidCallback? onMarkUnread;
  final VoidCallback? onPin;
  final VoidCallback? onCopyLink;
  final bool Function() isPinned;
  final Future<List<MessageReader>> Function()? loadReadBy;
  final void Function(int userId)? onReaderTap;
  final Future<List<({int id, String title})>> Function()? loadReportReasons;
  final Future<bool> Function(int reasonId)? onReport;
  final void Function(String emoji)? onReact;
  final ValueListenable<Map<String, dynamic>?>? reactions;
  final ValueListenable<double>? composerHeight;

  const SelectableMessageRow({
    super.key,
    required this.child,
    required this.message,
    required this.isMe,
    required this.selectedIds,
    required this.selectionAnim,
    required this.isSelectionActive,
    required this.onToggleSelection,
    required this.onEnterSelection,
    required this.onStartTextSelection,
    required this.onDragTextSelection,
    required this.onDelete,
    this.allowDelete = true,
    this.onEdit,
    this.onReply,
    this.onForward,
    this.allowCopy = true,
    this.onMarkUnread,
    this.onPin,
    this.onCopyLink,
    required this.isPinned,
    this.loadReadBy,
    this.onReaderTap,
    this.loadReportReasons,
    this.onReport,
    this.onReact,
    this.reactions,
    this.composerHeight,
  });

  @override
  State<SelectableMessageRow> createState() => _SelectableMessageRowState();
}

class _SelectableMessageRowState extends State<SelectableMessageRow> {
  static const double _gutterWidth = 40;

  final GlobalKey _boundaryKey = GlobalKey();
  Offset? _lastTapDown;
  Timer? _openTimer;

  bool _isPinnedNow() => widget.isPinned();

  @override
  void dispose() {
    _openTimer?.cancel();
    super.dispose();
  }

  void _openMenu() {
    final ctx = _boundaryKey.currentContext;
    if (ctx == null) return;
    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return;

    final origin = renderObject.localToGlobal(Offset.zero);
    final rect = origin & renderObject.size;
    final rawDpr = MediaQuery.of(ctx).devicePixelRatio;
    final dpr = rawDpr > 2.0 ? 2.0 : rawDpr;

    final ui.Image snapshot;
    try {
      snapshot = renderObject.toImageSync(pixelRatio: dpr);
    } catch (_) {
      return;
    }

    Haptics.tap();

    final controller = MessageActionsController();
    showMessageActions(
      context: ctx,
      snapshot: snapshot,
      originRect: rect,
      tapPoint: _lastTapDown ?? rect.center,
      isMe: widget.isMe,
      bottomReservedSpace: widget.composerHeight?.value ?? 0,
      messageText: widget.message.text,
      copyText: MessageDecryptionCache.instance.readableText(widget.message),
      controller: controller,
      style: AppMessageActionsStyle.current.value,
      interaction: MessageActionsInteraction.tap,
      editHistory: widget.message.editHistory,
      infoRows: _infoRows(),
      loadReadBy: widget.loadReadBy,
      onReaderTap: widget.onReaderTap,
      loadReportReasons: widget.loadReportReasons,
      onReport: widget.onReport,
      onDelete: widget.onDelete,
      allowDelete: widget.allowDelete,
      onEdit: widget.onEdit,
      onReply: widget.onReply,
      onForward: widget.onForward,
      allowCopy: widget.allowCopy,
      onMarkUnread: widget.onMarkUnread,
      onPin: widget.onPin,
      onCopyLink: widget.onCopyLink,
      isPinned: _isPinnedNow(),
      onReact: widget.onReact,
      selectedReaction: widget.reactions?.value?['yourReaction']?.toString(),
      quickReactions: _quickReactionEmojis(),
      loadReactionEmojis: () async {
        await animojiModule.ensureLoaded();
        return _animojiReactionEmojis();
      },
      onDispose: controller.dispose,
    );
  }

  // #***! панель «Info» живёт под тем же тумблером, что и остальные
  // техподробности в интерфейсе
  List<MessageInfoRow>? _infoRows() => AppShowExtraInfo.current.value
      ? buildMessageInfoRows(widget.message)
      : null;

  List<ReactionEmoji> _quickReactionEmojis() {
    final quick = animojiModule.quickAnimojis;
    if (quick.isEmpty) {
      return AnimojiModule.fallbackReactions
          .map((e) => ReactionEmoji(emoji: e))
          .toList();
    }
    return quick.map(_toReactionEmoji).toList();
  }

  List<ReactionEmoji> _animojiReactionEmojis() {
    final list = animojiModule.animojis;
    if (list.isEmpty) {
      return AnimojiModule.fallbackReactions
          .map((e) => ReactionEmoji(emoji: e))
          .toList();
    }
    return list.map(_toReactionEmoji).toList();
  }

  ReactionEmoji _toReactionEmoji(Animoji a) => ReactionEmoji(
    emoji: a.emoji,
    animationUrl: a.lottieUrl,
    staticUrl: a.iconUrl,
  );

  void _onSecondaryTapDown(TapDownDetails details) {
    final ctx = _boundaryKey.currentContext;
    if (ctx == null) return;
    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return;

    final origin = renderObject.localToGlobal(Offset.zero);
    final rect = origin & renderObject.size;

    final controller = MessageActionsController();
    showMessageActions(
      context: ctx,
      originRect: rect,
      tapPoint: details.globalPosition,
      isMe: widget.isMe,
      bottomReservedSpace: widget.composerHeight?.value ?? 0,
      messageText: widget.message.text,
      copyText: MessageDecryptionCache.instance.readableText(widget.message),
      controller: controller,
      style: MessageActionsStyle.list,
      interaction: MessageActionsInteraction.click,
      editHistory: widget.message.editHistory,
      infoRows: _infoRows(),
      loadReadBy: widget.loadReadBy,
      onReaderTap: widget.onReaderTap,
      loadReportReasons: widget.loadReportReasons,
      onReport: widget.onReport,
      onDelete: widget.onDelete,
      allowDelete: widget.allowDelete,
      onEdit: widget.onEdit,
      onReply: widget.onReply,
      onForward: widget.onForward,
      allowCopy: widget.allowCopy,
      onMarkUnread: widget.onMarkUnread,
      onPin: widget.onPin,
      onCopyLink: widget.onCopyLink,
      isPinned: _isPinnedNow(),
      onDispose: controller.dispose,
    );
  }

  void _handleTap() {
    if (widget.isSelectionActive()) {
      widget.onToggleSelection();
      return;
    }
    final react = widget.onReact;
    if (react != null && (_openTimer?.isActive ?? false)) {
      _openTimer?.cancel();
      _openTimer = null;
      Haptics.tap();
      react('❤️');
      return;
    }
    _openTimer?.cancel();
    _openTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted && !widget.isSelectionActive()) _openMenu();
    });
  }

  bool _textSelectionPress = false;

  void _handleLongPressMove(Offset globalPosition) {
    if (!_textSelectionPress) return;
    widget.onDragTextSelection(globalPosition);
  }

  void _handleLongPressEnd() {
    if (!_textSelectionPress) return;
    _textSelectionPress = false;
    widget.onDragTextSelection(null);
  }

  void _handleLongPressStart(Offset globalPosition) {
    _textSelectionPress = false;
    if (!widget.isSelectionActive()) {
      widget.onEnterSelection();
      return;
    }
    final selected = widget.selectedIds.value.contains(widget.message.id);
    final hasText = widget.message.selectableText != null;
    if (selected && hasText && !widget.message.isControl) {
      _textSelectionPress = true;
      widget.onStartTextSelection(globalPosition);
    } else {
      widget.onToggleSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isControl) return widget.child;
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: widget.selectionAnim,
      builder: (context, _) {
        final t = Curves.easeOut.transform(
          widget.selectionAnim.value.clamp(0.0, 1.0),
        );
        return ValueListenableBuilder<Set<String>>(
          valueListenable: widget.selectedIds,
          builder: (context, selected, _) {
            final isSelected = selected.contains(widget.message.id);
            final active = selected.isNotEmpty;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _lastTapDown = d.globalPosition,
              onTap: _handleTap,
              onLongPressStart: (d) => _handleLongPressStart(d.globalPosition),
              onLongPressMoveUpdate: (d) =>
                  _handleLongPressMove(d.globalPosition),
              onLongPressEnd: (_) => _handleLongPressEnd(),
              onLongPressCancel: _handleLongPressEnd,
              onSecondaryTapDown: active ? null : _onSecondaryTapDown,
              child: ColoredBox(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.10)
                    : Colors.transparent,
                child: Stack(
                  children: [
                    RepaintBoundary(
                      key: _boundaryKey,
                      child: IgnorePointer(
                        ignoring: active,
                        child: Padding(
                          padding: EdgeInsets.only(left: _gutterWidth * t),
                          child: widget.child,
                        ),
                      ),
                    ),
                    if (t > 0)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final rowHeight = constraints.maxHeight;
                            final diameter = SelectionCheckCircle.diameterFor(
                              rowHeight,
                            );
                            return Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: 8,
                                bottom: SelectionCheckCircle.bottomInsetFor(
                                  rowHeight,
                                  diameter,
                                ),
                              ),
                              child: Align(
                                alignment: AlignmentDirectional.bottomStart,
                                child: Opacity(
                                  opacity: t,
                                  child: SelectionCheckCircle(
                                    selected: isSelected,
                                    diameter: diameter,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class DeletingMessageAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onComplete;

  const DeletingMessageAnimation({
    super.key,
    required this.child,
    required this.onComplete,
  });

  @override
  State<DeletingMessageAnimation> createState() =>
      _DeletingMessageAnimationState();
}

class _DeletingMessageAnimationState extends State<DeletingMessageAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<double> _collapse;
  bool _fired = false;

  static const Duration _duration = Duration(milliseconds: 280);
  static const Duration _iosDuration = Duration(milliseconds: 260);

  @override
  void initState() {
    super.initState();
    final ios = AppIosGlass.active.value;
    _ctrl = AnimationController(
      vsync: this,
      duration: ios ? _iosDuration : _duration,
    );
    final vanish = ios
        ? const Interval(0.0, 0.58, curve: Curves.easeInOut)
        : const Interval(0.0, 0.6);
    _opacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: vanish));
    _scale = Tween<double>(
      begin: 1,
      end: ios ? 0.1 : 0.82,
    ).animate(CurvedAnimation(parent: _ctrl, curve: vanish));
    _collapse = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: ios
            ? const Interval(0.45, 1.0, curve: Curves.easeInOut)
            : const Interval(0.35, 1.0, curve: Curves.easeInOut),
      ),
    );
    _ctrl.forward().whenComplete(() {
      if (_fired) return;
      _fired = true;
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _collapse,
      alignment: AlignmentDirectional.centerStart,
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

class SentMessageAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onComplete;

  const SentMessageAnimation({
    super.key,
    required this.child,
    required this.onComplete,
  });

  @override
  State<SentMessageAnimation> createState() => _SentMessageAnimationState();
}

class _SentMessageAnimationState extends State<SentMessageAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    final ios = AppIosGlass.active.value;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ios ? 200 : 220),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(
      begin: ios ? 0 : 16,
      end: 0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

class EditMessageSheet extends StatefulWidget {
  final String text;
  final Iterable<FormatRange> formatRanges;
  final Widget Function(
    RichMessageController controller,
    BuildContext context,
    EditableTextState editableState,
  )
  contextMenuBuilder;

  const EditMessageSheet({
    super.key,
    required this.text,
    required this.formatRanges,
    required this.contextMenuBuilder,
  });

  @override
  State<EditMessageSheet> createState() => _EditMessageSheetState();
}

class _EditMessageSheetState extends State<EditMessageSheet> {
  late final RichMessageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RichMessageController(text: widget.text)
      ..setFormatRanges(widget.formatRanges);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Изменить сообщение',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: displayFontOf(context),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 1,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: cs.onSurface),
            contextMenuBuilder: (ctx, state) =>
                widget.contextMenuBuilder(_controller, ctx, state),
            decoration: InputDecoration(
              hintText: 'Текст сообщения',
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(_controller.buildContent()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
