import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_bubble_behavior.dart';
import '../../../core/config/app_bubble_shape.dart';
import '../../../core/utils/bubble_radius.dart';
import '../../motion/ios_haptics.dart';
import '../attachment/bubbles/ios_bubble_metrics.dart';
import 'ios_metrics.dart';
import 'ios_palette.dart';
import 'ios_tappable.dart';
import 'ios_typography.dart';
import 'screen_gradient_bubble.dart';

class IosTileOption<T> {
  final T value;
  final IconData icon;
  final String label;

  const IosTileOption({
    required this.value,
    required this.icon,
    required this.label,
  });
}

class IosTilePicker<T> extends StatelessWidget {
  final List<IosTileOption<T>> options;
  final T? value;
  final ValueChanged<T> onChanged;

  const IosTilePicker({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _IosTile(
              option: options[i],
              selected: options[i].value == value,
              onTap: () {
                if (options[i].value == value) return;
                IosHaptics.selectionChange();
                onChanged(options[i].value);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _IosTile<T> extends StatelessWidget {
  final IosTileOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  const _IosTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : IosPalette.secondaryLabel(cs);
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      value: selected ? 'Выбрано' : 'Не выбрано',
      onTap: onTap,
      child: ExcludeSemantics(
        child: IosTappable(
          onTap: onTap,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? IosPalette.settingsCard(cs)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: selected
                      ? null
                      : Border.all(color: IosPalette.separator(cs)),
                ),
                child: Icon(option.icon, size: 26, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                option.label,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: IosTypography.regular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IosSectionHeader extends StatelessWidget {
  final String title;

  const IosSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: IosPalette.secondaryLabel(cs),
          fontSize: IosTypography.sectionHeader,
          fontWeight: IosTypography.regular,
        ),
      ),
    );
  }
}

class IosHelperText extends StatelessWidget {
  final String text;

  const IosHelperText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        text,
        style: TextStyle(
          color: IosPalette.secondaryLabel(cs),
          fontSize: 13,
          height: 1.3,
        ),
      ),
    );
  }
}

class IosControlCard extends StatelessWidget {
  final List<Widget> children;
  final double separatorIndent;

  const IosControlCard({
    super.key,
    required this.children,
    this.separatorIndent = 16,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: IosPalette.settingsCard(cs),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Padding(
                padding: EdgeInsets.only(left: separatorIndent),
                child: Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: IosPalette.separator(cs),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class IosCheckOption<T> {
  final T value;
  final String label;
  final String? detail;
  final IconData? icon;
  final Widget? trailing;

  const IosCheckOption({
    required this.value,
    required this.label,
    this.detail,
    this.icon,
    this.trailing,
  });
}

class IosCheckList<T> extends StatelessWidget {
  final List<IosCheckOption<T>> options;
  final T? value;
  final ValueChanged<T> onChanged;

  const IosCheckList({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasIcon = options.any((option) => option.icon != null);
    return IosControlCard(
      separatorIndent: hasIcon ? 54 : 16,
      children: [
        for (final option in options)
          _IosCheckRow<T>(
            option: option,
            selected: option.value == value,
            onTap: () {
              if (option.value == value) return;
              IosHaptics.selectionChange();
              onChanged(option.value);
            },
          ),
      ],
    );
  }
}

class _IosCheckRow<T> extends StatelessWidget {
  final IosCheckOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  const _IosCheckRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      value: selected ? 'Выбрано' : 'Не выбрано',
      onTap: onTap,
      child: ExcludeSemantics(
        child: IosTappable(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: IosMetrics.minHitTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (option.icon != null) ...[
                    Icon(option.icon, size: 22, color: IosPalette.label(cs)),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.label,
                          softWrap: true,
                          style: TextStyle(
                            color: IosPalette.label(cs),
                            fontSize: IosTypography.body,
                            fontWeight: IosTypography.regular,
                          ),
                        ),
                        if (option.detail != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            option.detail!,
                            softWrap: true,
                            style: TextStyle(
                              color: IosPalette.secondaryLabel(cs),
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.check_mark,
                    size: 18,
                    color: selected ? cs.primary : Colors.transparent,
                  ),
                  if (option.trailing != null) option.trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IosToggleItem {
  final String label;
  final String? detail;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const IosToggleItem({
    required this.label,
    required this.value,
    required this.onChanged,
    this.detail,
    this.enabled = true,
  });
}

class IosToggleCard extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? helper;

  const IosToggleCard({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IosControlCard(
          children: [
            _IosSwitchRow(label: label, value: value, onChanged: onChanged),
          ],
        ),
        if (helper != null) IosHelperText(helper!),
      ],
    );
  }
}

class IosToggleGroup extends StatelessWidget {
  final List<IosToggleItem> items;

  const IosToggleGroup({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return IosControlCard(
      children: [
        for (final item in items)
          _IosSwitchRow(
            label: item.label,
            detail: item.detail,
            value: item.value,
            enabled: item.enabled,
            onChanged: item.onChanged,
          ),
      ],
    );
  }
}

class _IosSwitchRow extends StatelessWidget {
  final String label;
  final String? detail;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const _IosSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.detail,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = enabled && onChanged != null;
    return Opacity(
      opacity: active ? 1 : 0.4,
      child: Semantics(
        label: label,
        toggled: value,
        value: value ? 'Включено' : 'Выключено',
        onTap: active ? () => onChanged!(!value) : null,
        child: ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: IosMetrics.minHitTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          softWrap: true,
                          style: TextStyle(
                            color: IosPalette.label(cs),
                            fontSize: IosTypography.body,
                            fontWeight: IosTypography.regular,
                          ),
                        ),
                        if (detail != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            detail!,
                            softWrap: true,
                            style: TextStyle(
                              color: IosPalette.secondaryLabel(cs),
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ExcludeSemantics(
                    child: CupertinoSwitch(
                      value: value,
                      activeTrackColor: cs.primary,
                      onChanged: active
                          ? (next) {
                              IosHaptics.toggle();
                              onChanged!(next);
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IosValueEntry {
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool enabled;

  const IosValueEntry({
    required this.label,
    this.value,
    this.onTap,
    this.enabled = true,
  });
}

class IosValueCard extends StatelessWidget {
  final List<IosValueEntry> entries;

  const IosValueCard({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return IosControlCard(
      children: [for (final entry in entries) _IosValueRow(entry: entry)],
    );
  }
}

class _IosValueRow extends StatelessWidget {
  final IosValueEntry entry;

  const _IosValueRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tappable = entry.enabled && entry.onTap != null;
    return Opacity(
      opacity: entry.enabled ? 1 : 0.4,
      child: Semantics(
        button: tappable,
        label: entry.label,
        value: entry.value,
        onTap: tappable ? entry.onTap : null,
        child: ExcludeSemantics(
          child: IosTappable(
            onTap: tappable ? entry.onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: IosMetrics.minHitTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.label,
                        softWrap: true,
                        style: TextStyle(
                          color: IosPalette.label(cs),
                          fontSize: IosTypography.body,
                          fontWeight: IosTypography.regular,
                        ),
                      ),
                    ),
                    if (entry.value != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          entry.value!,
                          textAlign: TextAlign.end,
                          softWrap: true,
                          style: TextStyle(
                            color: IosPalette.secondaryLabel(cs),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: IosPalette.secondaryLabel(cs),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IosSteppedSlider extends StatelessWidget {
  final double value;
  final List<double> steps;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String? semanticLabel;
  final String? semanticValue;

  const IosSteppedSlider({
    super.key,
    required this.value,
    required this.steps,
    required this.onChanged,
    this.onChangeEnd,
    this.semanticLabel,
    this.semanticValue,
  });

  static double snap(double value, List<double> steps) {
    if (steps.isEmpty) return value;
    var best = steps.first;
    for (final step in steps) {
      if ((step - value).abs() < (best - value).abs()) best = step;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    return IosTrackSlider(
      value: value,
      min: steps.first,
      max: steps.last,
      steps: steps,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      semanticLabel: semanticLabel,
      semanticValue: semanticValue,
      marks: true,
    );
  }
}

class IosTrackSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final List<double>? steps;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String? semanticLabel;
  final String? semanticValue;
  final bool marks;

  const IosTrackSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.steps,
    this.onChanged,
    this.onChangeEnd,
    this.semanticLabel,
    this.semanticValue,
    this.marks = false,
  });

  @override
  State<IosTrackSlider> createState() => _IosTrackSliderState();
}

class _IosTrackSliderState extends State<IosTrackSlider> {
  double? _drag;

  double get _shown {
    final raw = _drag ?? widget.value;
    final steps = widget.steps;
    if (steps != null && steps.isNotEmpty) {
      return IosSteppedSlider.snap(raw, steps);
    }
    return raw.clamp(widget.min, widget.max);
  }

  double _valueAt(double dx, double width) {
    const inset = 14.0;
    final track = math.max(1.0, width - inset * 2);
    final fraction = ((dx - inset) / track).clamp(0.0, 1.0);
    final steps = widget.steps;
    if (steps != null && steps.isNotEmpty) {
      final raw = steps.first + (steps.last - steps.first) * fraction;
      return IosSteppedSlider.snap(raw, steps);
    }
    return widget.min + (widget.max - widget.min) * fraction;
  }

  void _emit(double next, {required bool end}) {
    final previous = _shown;
    if (next != previous) {
      setState(() => _drag = next);
      if (widget.steps != null) IosHaptics.selectionChange();
      widget.onChanged?.call(next);
    } else if (_drag != next) {
      setState(() => _drag = next);
    }
    if (end) {
      widget.onChangeEnd?.call(next);
      setState(() => _drag = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final current = _shown;
    final enabled = widget.onChanged != null;
    return Semantics(
      slider: true,
      enabled: enabled,
      label: widget.semanticLabel,
      value: widget.semanticValue ?? current.toStringAsFixed(2),
      child: Row(
        children: [
          if (widget.marks) ...[
            ExcludeSemantics(
              child: Text(
                'А',
                style: TextStyle(
                  fontSize: 14,
                  color: IosPalette.secondaryLabel(cs),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: enabled
                      ? (details) => _emit(
                          _valueAt(
                            details.localPosition.dx,
                            constraints.maxWidth,
                          ),
                          end: true,
                        )
                      : null,
                  onHorizontalDragUpdate: enabled
                      ? (details) => _emit(
                          _valueAt(
                            details.localPosition.dx,
                            constraints.maxWidth,
                          ),
                          end: false,
                        )
                      : null,
                  onHorizontalDragEnd: enabled
                      ? (_) => _emit(_shown, end: true)
                      : null,
                  child: SizedBox(
                    height: IosMetrics.minHitTarget,
                    child: CustomPaint(
                      painter: _IosTrackPainter(
                        min: widget.min,
                        max: widget.max,
                        value: current,
                        steps: widget.steps,
                        active: cs.primary,
                        inactive: IosPalette.separator(cs),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.marks) ...[
            const SizedBox(width: 8),
            ExcludeSemantics(
              child: Text(
                'А',
                style: TextStyle(fontSize: 24, color: IosPalette.label(cs)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IosTrackPainter extends CustomPainter {
  final double min;
  final double max;
  final double value;
  final List<double>? steps;
  final Color active;
  final Color inactive;

  _IosTrackPainter({
    required this.min,
    required this.max,
    required this.value,
    required this.steps,
    required this.active,
    required this.inactive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 14.0;
    final y = size.height / 2;
    final span = math.max(0.0, max - min);
    final track = math.max(1.0, size.width - inset * 2);
    double xOf(double step) {
      if (span == 0) return size.width / 2;
      return inset + ((step - min) / span) * track;
    }

    final thumbX = xOf(value);
    canvas.drawLine(
      Offset(inset, y),
      Offset(size.width - inset, y),
      Paint()
        ..color = inactive
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(inset, y),
      Offset(thumbX, y),
      Paint()
        ..color = active
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    final ticks = steps;
    if (ticks != null) {
      for (final step in ticks) {
        canvas.drawCircle(
          Offset(xOf(step), y),
          2.5,
          Paint()..color = step <= value + 0.0001 ? active : inactive,
        );
      }
    }
    final thumb = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(thumbX, y), width: 28, height: 16),
      const Radius.circular(8),
    );
    canvas.drawRRect(thumb, Paint()..color = active);
  }

  @override
  bool shouldRepaint(_IosTrackPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.min != min ||
      oldDelegate.max != max;
}

class IosTextScalePreview extends StatelessWidget {
  final double scale;

  const IosTextScalePreview({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppBubbleShape.current,
        AppBubbleBehavior.current,
      ]),
      builder: (context, _) {
        return Column(
          children: [
            _IosPreviewBubble(text: 'Привет!', isMe: true, scale: scale),
            const SizedBox(height: 8),
            _IosPreviewBubble(text: 'Как дела?', isMe: false, scale: scale),
          ],
        );
      },
    );
  }
}

class _IosPreviewBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final double scale;

  const _IosPreviewBubble({
    required this.text,
    required this.isMe,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = computeBubbleRadius(
      isMe: isMe,
      isTop: true,
      isBottom: true,
      style: AppBubbleShape.current.value,
      behavior: AppBubbleBehavior.current.value,
      ios: true,
    );
    final bubble = ScreenGradientBubble(
      colors: IosPalette.bubbleGradient(cs, isMe: isMe).colors,
      borderRadius: radius,
      rim: IosPalette.bubbleRim(cs),
      child: Padding(
        padding: IosBubbleMetrics.textPadding,
        child: Text(
          text,
          style: TextStyle(
            fontSize: IosBubbleMetrics.textSize * scale,
            height: IosBubbleMetrics.textHeight,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    );
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }
}

class IosCapsuleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const IosCapsuleButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return Center(
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Semantics(
          button: true,
          enabled: enabled,
          label: label,
          onTap: onPressed,
          child: ExcludeSemantics(
            child: IosTappable(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(IosMetrics.capsuleRadius),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: IosMetrics.minHitTarget,
                  minWidth: 120,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: IosPalette.searchFill(cs),
                    borderRadius: BorderRadius.circular(
                      IosMetrics.capsuleRadius,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: IosPalette.secondaryLabel(cs),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
