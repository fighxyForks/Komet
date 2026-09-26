import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../widgets/glass/ios_settings_scaffold.dart';
import 'package:komet/frontend/widgets/glass/ios_symbols.dart';

import '../../widgets/color_wheel_picker.dart';

import '../../../core/config/app_bubble_behavior.dart';
import '../../../core/config/app_bubble_shape.dart';
import '../../../core/config/app_pill_gradient.dart';
import '../../../core/config/app_fonts.dart';
import '../../../core/config/app_ios_glass.dart';
import '../../../core/config/app_theme_mode.dart';
import '../../../core/config/app_wallpaper_tint.dart';
import '../../../core/config/app_visual_style.dart';
import '../../../core/config/app_chat_chrome.dart';
import '../../../core/config/app_composer_background.dart';
import '../../../core/config/app_composer_style.dart';
import '../../../core/config/app_nav_pill_style.dart';
import '../../../core/config/app_spectrum_background.dart';
import '../../../core/utils/bubble_radius.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/utils/haptics.dart';
import '../../motion/ios_haptics.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../widgets/glass/glass_controls.dart';
import '../../widgets/glass/ios_glass.dart';
import '../../widgets/glass/ios_palette.dart';
import '../../widgets/glass/ios_route.dart';
import '../../widgets/glass/ios_settings_controls.dart';
import '../../widgets/glass/ios_tappable.dart';
import 'chat_background_screen.dart';
import 'theme_settings_screen.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/settings_card.dart';
import '../../widgets/glass/ios_typography.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  static const _fallback = Color(0xFFC1C4FF);

  final ValueNotifier<Color> _color = ValueNotifier(_fallback);
  final ValueNotifier<bool> _isSystem = ValueNotifier(false);
  bool _initialized = false;
  bool _accentExpanded = false;
  final _debounce = Debouncer(const Duration(milliseconds: 350));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final seed = KometApp.stateOf(context)?.accentSeed.value;
      _isSystem.value = seed == null;
      _color.value = seed ?? _fallback;
    }
  }

  @override
  void dispose() {
    _debounce.dispose();
    _color.dispose();
    _isSystem.dispose();
    super.dispose();
  }

  void _onColorChanged(Color color) {
    _color.value = color;
    _isSystem.value = false;
    _debounce.run(() {
      if (mounted) KometApp.stateOf(context)?.applyAccentColor(color);
    });
  }

  void _resetToSystem() {
    if (IosGlass.of(context)) {
      IosHaptics.selectionChange();
    } else {
      Haptics.selection();
    }
    _debounce.cancel();
    _isSystem.value = true;
    _color.value = _fallback;
    KometApp.stateOf(context)?.applyAccentColor(null);
  }

  void _toggleAccentExpanded() {
    if (IosGlass.of(context)) {
      IosHaptics.itemActivate();
    } else {
      Haptics.tap();
    }
    setState(() => _accentExpanded = !_accentExpanded);
  }

  void _onStyleChanged(BubbleStyle style) {
    if (IosGlass.of(context)) {
      IosHaptics.selectionChange();
    } else {
      Haptics.selection();
    }
    AppBubbleShape.save(style);
  }

  void _onBehaviorChanged(BubbleBehavior behavior) {
    if (IosGlass.of(context)) {
      IosHaptics.selectionChange();
    } else {
      Haptics.selection();
    }
    AppBubbleBehavior.save(behavior);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final ios = IosGlass.of(context);
    final gap = ios ? 20.0 : 12.0;
    final blocks = <Widget>[
      _ColorPickerCard(
        color: _color,
        isSystem: _isSystem,
        expanded: _accentExpanded,
        onToggle: _toggleAccentExpanded,
        onColorChanged: _onColorChanged,
        onReset: _resetToSystem,
      ),
      SizedBox(height: gap),
      _BubbleShapeCard(onChanged: _onStyleChanged),
      SizedBox(height: gap),
      _BubbleBehaviorCard(onChanged: _onBehaviorChanged),
      SizedBox(height: gap),
      const _VisualStyleCard(),
      SizedBox(height: gap),
      const _ChatChromeCard(),
      SizedBox(height: gap),
      const _ComposerBarCard(),
      SizedBox(height: gap),
      const _NavPillStyleCard(),
      SizedBox(height: gap),
      if (ios)
        const _IosEffectToggles()
      else ...[
        const _GradientToggleCard(),
        SizedBox(height: gap),
        const _SpectrumToggleCard(),
      ],
    ];

    return IosSettingsScaffold(
      title: l10n.appearanceTitle,
      body: SafeArea(
        top: false,
        child: ios
            ? ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  _PreviewSection(color: _color, isSystem: _isSystem),
                  const SizedBox(height: 20),
                  const _IosThemeBlock(),
                  const SizedBox(height: 20),
                  const _IosTextSizeBlock(),
                  const SizedBox(height: 20),
                  ...blocks,
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _PreviewSection(color: _color, isSystem: _isSystem),
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      children: blocks,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _IosChoice<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final T value;
  final List<IosCheckOption<T>> options;
  final ValueChanged<T> onChanged;
  final Widget? footer;

  const _IosChoice({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IosSectionHeader(title),
        IosCheckList<T>(value: value, options: options, onChanged: onChanged),
        IosHelperText(subtitle),
        if (footer != null) ...[const SizedBox(height: 16), footer!],
      ],
    );
  }
}

class _IosThemeBlock extends StatelessWidget {
  const _IosThemeBlock();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppThemeModeConfig.current,
        AppWallpaperTint.current,
      ]),
      builder: (context, _) {
        final custom = AppWallpaperTint.current.value;
        final current = AppThemeModeConfig.current.value;
        final schedule = !custom && current == AppThemeMode.schedule;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IosSectionHeader('Тема'),
            IosTilePicker<AppThemeMode>(
              value: custom || schedule ? null : current,
              options: const [
                IosTileOption(
                  value: AppThemeMode.system,
                  icon: CupertinoIcons.circle_lefthalf_fill,
                  label: 'Система',
                ),
                IosTileOption(
                  value: AppThemeMode.light,
                  icon: CupertinoIcons.sun_max_fill,
                  label: 'День',
                ),
                IosTileOption(
                  value: AppThemeMode.dark,
                  icon: CupertinoIcons.moon_fill,
                  label: 'Ночь',
                ),
              ],
              onChanged: (mode) {
                if (custom) unawaited(AppWallpaperTint.save(false));
                KometApp.stateOf(
                  context,
                )?.applyThemeModeWithReveal(mode, Offset.zero);
              },
            ),
            const SizedBox(height: 16),
            IosValueCard(
              entries: [
                IosValueEntry(
                  label: 'По расписанию',
                  value: schedule ? 'Включено' : null,
                  onTap: () {
                    Navigator.of(context).push(
                      iosPageRoute(
                        context,
                        builder: (context) => const ThemeSettingsScreen(),
                      ),
                    );
                  },
                ),
                IosValueEntry(
                  label: 'Обои',
                  onTap: () {
                    Navigator.of(context).push(
                      iosPageRoute(
                        context,
                        builder: (context) => const ChatBackgroundScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _IosTextSizeBlock extends StatelessWidget {
  const _IosTextSizeBlock();

  @override
  Widget build(BuildContext context) {
    final app = KometApp.stateOf(context);
    if (app == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<double>(
      valueListenable: app.fontScale,
      builder: (context, scale, _) {
        final steps = [
          for (
            var step = AppFonts.minScale;
            step <= AppFonts.maxScale + 0.001;
            step += 0.05
          )
            double.parse(step.toStringAsFixed(2)),
        ];
        final isDefault = (scale - AppFonts.defaultScale).abs() < 0.001;
        final cs = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IosSectionHeader('Размер текста'),
            DecoratedBox(
              decoration: BoxDecoration(
                color: IosPalette.settingsCard(cs),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    IosSteppedSlider(
                      value: scale,
                      steps: steps,
                      semanticLabel: 'Размер текста',
                      semanticValue: '${(scale * 100).round()}%',
                      onChanged: (v) => app.applyFontScale(v, persist: false),
                      onChangeEnd: app.applyFontScale,
                    ),
                    const SizedBox(height: 12),
                    IosTextScalePreview(scale: scale),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            IosCapsuleButton(
              label: l10n.fontSettingsReset,
              onPressed: isDefault
                  ? null
                  : () => app.applyFontScale(AppFonts.defaultScale),
            ),
          ],
        );
      },
    );
  }
}

class _IosGlassToggle extends StatelessWidget {
  const _IosGlassToggle();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<bool>(
      valueListenable: AppIosGlass.enabled,
      builder: (context, enabled, _) => IosToggleCard(
        label: l10n.appearanceIosGlassTitle,
        helper: l10n.appearanceIosGlassSubtitle,
        value: enabled,
        onChanged: (value) {
          unawaited(GlassSuppression.during(() => AppIosGlass.save(value)));
        },
      ),
    );
  }
}

class _IosEffectToggles extends StatelessWidget {
  const _IosEffectToggles();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppPillGradient.current,
        AppSpectrumBackground.current,
      ]),
      builder: (context, _) => IosToggleGroup(
        items: [
          IosToggleItem(
            label: l10n.appearanceGradientTitle,
            detail: l10n.appearanceGradientSubtitle,
            value: AppPillGradient.current.value,
            onChanged: (value) {
              unawaited(AppPillGradient.save(value));
            },
          ),
          IosToggleItem(
            label: l10n.appearanceSpectrumTitle,
            detail: l10n.appearanceSpectrumSubtitle,
            value: AppSpectrumBackground.current.value,
            onChanged: (value) {
              unawaited(AppSpectrumBackground.save(value));
            },
          ),
        ],
      ),
    );
  }
}

void _applyVisualStyle(VisualStyle style) {
  AppVisualStyle.save(style);
  if (style == VisualStyle.liquidGlass) {
    if (AppNavPillStyle.current.value != NavPillStyle.auto) {
      AppNavPillStyle.save(NavPillStyle.liquidGlass);
    }
    AppComposerBackground.save(ComposerBackground.liquidGlass);
    AppChatChrome.save(ChatChromeStyle.liquidGlass);
    return;
  }
  if (AppNavPillStyle.current.value == NavPillStyle.liquidGlass) {
    AppNavPillStyle.save(NavPillStyle.frostBlur);
  }
  if (AppComposerBackground.current.value == ComposerBackground.liquidGlass) {
    AppComposerBackground.save(ComposerBackground.frostBlur);
  }
  if (AppChatChrome.current.value == ChatChromeStyle.liquidGlass) {
    AppChatChrome.save(ChatChromeStyle.transparent);
  }
}

class _VisualStyleCard extends StatelessWidget {
  const _VisualStyleCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (IosGlass.of(context)) {
      return ValueListenableBuilder<VisualStyle>(
        valueListenable: AppVisualStyle.current,
        builder: (context, current, _) {
          final selectable =
              current == VisualStyle.liquidGlass && !LiquidGlass.isSupported
              ? VisualStyle.glossy
              : current;
          return _IosChoice<VisualStyle>(
            title: l10n.appearanceVisualStyleTitle,
            subtitle: l10n.appearanceVisualStyleSubtitle,
            value: selectable,
            onChanged: _applyVisualStyle,
            options: [
              IosCheckOption(
                value: VisualStyle.materialYou,
                label: l10n.appearanceVisualStyleMaterialYou,
              ),
              IosCheckOption(
                value: VisualStyle.glossy,
                label: l10n.appearanceVisualStyleGlossy,
              ),
              if (LiquidGlass.isSupported)
                IosCheckOption(
                  value: VisualStyle.liquidGlass,
                  label: l10n.appearanceVisualStyleLiquidGlass,
                ),
            ],
            footer: AppIosGlass.supported ? const _IosGlassToggle() : null,
          );
        },
      );
    }
    final cs = Theme.of(context).colorScheme;
    return SettingsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.appearanceVisualStyleTitle,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: IosGlass.of(context) ? IosTypography.listTitle : 16,
              fontWeight: IosGlass.of(context)
                  ? IosTypography.semibold
                  : FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.appearanceVisualStyleSubtitle,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<VisualStyle>(
            valueListenable: AppVisualStyle.current,
            builder: (context, current, _) {
              final selectable =
                  current == VisualStyle.liquidGlass && !LiquidGlass.isSupported
                  ? VisualStyle.glossy
                  : current;
              return IosSegmentedControl<VisualStyle>(
                groupValue: selectable,
                children: {
                  VisualStyle.materialYou: Text(
                    l10n.appearanceVisualStyleMaterialYou,
                    textAlign: TextAlign.center,
                  ),
                  VisualStyle.glossy: Text(
                    l10n.appearanceVisualStyleGlossy,
                    textAlign: TextAlign.center,
                  ),
                  if (LiquidGlass.isSupported)
                    VisualStyle.liquidGlass: Text(
                      l10n.appearanceVisualStyleLiquidGlass,
                      textAlign: TextAlign.center,
                    ),
                },
                onValueChanged: (v) {
                  if (v != null) _applyVisualStyle(v);
                },
              );
            },
          ),
          if (AppIosGlass.supported) ...[
            const SizedBox(height: 16),
            const IosGlassToggleRow(),
          ],
        ],
      ),
    );
  }
}

class IosGlassToggleRow extends StatelessWidget {
  const IosGlassToggleRow({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<bool>(
      valueListenable: AppIosGlass.enabled,
      builder: (context, enabled, _) => MergeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _toggle(context, !enabled),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appearanceIosGlassTitle,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.appearanceIosGlassSubtitle,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GlassSwitch(
                key: const ValueKey('ios-glass-switch'),
                value: enabled,
                onChanged: (v) => _toggle(context, v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggle(BuildContext context, bool value) {
    if (!IosGlass.of(context)) {
      Haptics.selection();
    }
    unawaited(GlassSuppression.during(() => AppIosGlass.save(value)));
  }
}

class _ChatChromeCard extends StatelessWidget {
  const _ChatChromeCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (IosGlass.of(context)) {
      return ValueListenableBuilder<ChatChromeStyle>(
        valueListenable: AppChatChrome.current,
        builder: (context, current, _) {
          final selectable =
              current == ChatChromeStyle.liquidGlass && !LiquidGlass.isSupported
              ? ChatChromeStyle.transparent
              : current;
          return _IosChoice<ChatChromeStyle>(
            title: l10n.appearanceChatChromeTitle,
            subtitle: l10n.appearanceChatChromeSubtitle,
            value: selectable,
            onChanged: (value) => unawaited(AppChatChrome.save(value)),
            options: [
              IosCheckOption(
                value: ChatChromeStyle.color,
                label: l10n.appearanceChatChromeColor,
              ),
              IosCheckOption(
                value: ChatChromeStyle.blur,
                label: l10n.appearanceChatChromeBlur,
              ),
              IosCheckOption(
                value: ChatChromeStyle.none,
                label: l10n.appearanceChatChromeNone,
              ),
              IosCheckOption(
                value: ChatChromeStyle.transparent,
                label: l10n.appearanceChatChromeTransparent,
              ),
              if (LiquidGlass.isSupported)
                IosCheckOption(
                  value: ChatChromeStyle.liquidGlass,
                  label: l10n.appearanceGlassMaterial,
                ),
            ],
          );
        },
      );
    }
    final cs = Theme.of(context).colorScheme;
    return SettingsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.appearanceChatChromeTitle,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: IosGlass.of(context) ? IosTypography.listTitle : 16,
              fontWeight: IosGlass.of(context)
                  ? IosTypography.semibold
                  : FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.appearanceChatChromeSubtitle,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<ChatChromeStyle>(
            valueListenable: AppChatChrome.current,
            builder: (context, current, _) {
              final selectable =
                  current == ChatChromeStyle.liquidGlass &&
                      !LiquidGlass.isSupported
                  ? ChatChromeStyle.transparent
                  : current;
              return IosSegmentedControl<ChatChromeStyle>(
                groupValue: selectable,
                onValueChanged: (v) {
                  if (v != null) AppChatChrome.save(v);
                },
                children: {
                  ChatChromeStyle.color: Text(
                    l10n.appearanceChatChromeColor,
                    textAlign: TextAlign.center,
                  ),
                  ChatChromeStyle.blur: Text(
                    l10n.appearanceChatChromeBlur,
                    textAlign: TextAlign.center,
                  ),
                  ChatChromeStyle.none: Text(
                    l10n.appearanceChatChromeNone,
                    textAlign: TextAlign.center,
                  ),
                  ChatChromeStyle.transparent: Text(
                    l10n.appearanceChatChromeTransparent,
                    textAlign: TextAlign.center,
                  ),
                  if (LiquidGlass.isSupported)
                    ChatChromeStyle.liquidGlass: Text(
                      l10n.appearanceGlassMaterial,
                      textAlign: TextAlign.center,
                    ),
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ComposerBarCard extends StatelessWidget {
  const _ComposerBarCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (IosGlass.of(context)) {
      return ValueListenableBuilder<ComposerStyle>(
        valueListenable: AppComposerStyle.current,
        builder: (context, current, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IosChoice<ComposerStyle>(
                title: l10n.appearanceComposerTitle,
                subtitle: l10n.appearanceComposerSubtitle,
                value: current,
                onChanged: (value) => unawaited(AppComposerStyle.save(value)),
                options: [
                  IosCheckOption(
                    value: ComposerStyle.auto,
                    label: l10n.appearanceStyleAuto,
                  ),
                  IosCheckOption(
                    value: ComposerStyle.glossy,
                    label: l10n.appearanceVisualStyleGlossy,
                  ),
                  IosCheckOption(
                    value: ComposerStyle.materialYou,
                    label: l10n.appearanceVisualStyleMaterialYou,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<ComposerBackground>(
                valueListenable: AppComposerBackground.current,
                builder: (context, background, _) {
                  final selectable =
                      background == ComposerBackground.liquidGlass &&
                          !LiquidGlass.isSupported
                      ? ComposerBackground.frostBlur
                      : background;
                  return _IosChoice<ComposerBackground>(
                    title: 'Фон панели',
                    subtitle: l10n.appearanceComposerSubtitle,
                    value: selectable,
                    onChanged: (value) =>
                        unawaited(AppComposerBackground.save(value)),
                    options: [
                      IosCheckOption(
                        value: ComposerBackground.standard,
                        label: l10n.appearanceComposerBackgroundStandard,
                      ),
                      IosCheckOption(
                        value: ComposerBackground.frostBlur,
                        label: l10n.appearanceComposerBackgroundFrost,
                      ),
                      if (LiquidGlass.isSupported)
                        IosCheckOption(
                          value: ComposerBackground.liquidGlass,
                          label: l10n.appearanceGlassMaterial,
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      );
    }
    final cs = Theme.of(context).colorScheme;
    return SettingsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.appearanceComposerTitle,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: IosGlass.of(context) ? IosTypography.listTitle : 16,
              fontWeight: IosGlass.of(context)
                  ? IosTypography.semibold
                  : FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.appearanceComposerSubtitle,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<ComposerStyle>(
            valueListenable: AppComposerStyle.current,
            builder: (context, current, _) {
              return IosSegmentedControl<ComposerStyle>(
                groupValue: current,
                onValueChanged: (v) {
                  if (v != null) AppComposerStyle.save(v);
                },
                children: {
                  ComposerStyle.auto: Text(
                    l10n.appearanceStyleAuto,
                    textAlign: TextAlign.center,
                  ),
                  ComposerStyle.glossy: Text(
                    l10n.appearanceVisualStyleGlossy,
                    textAlign: TextAlign.center,
                  ),
                  ComposerStyle.materialYou: Text(
                    l10n.appearanceVisualStyleMaterialYou,
                    textAlign: TextAlign.center,
                  ),
                },
              );
            },
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<ComposerBackground>(
            valueListenable: AppComposerBackground.current,
            builder: (context, current, _) {
              final selectable =
                  current == ComposerBackground.liquidGlass &&
                      !LiquidGlass.isSupported
                  ? ComposerBackground.frostBlur
                  : current;
              return IosSegmentedControl<ComposerBackground>(
                groupValue: selectable,
                onValueChanged: (v) {
                  if (v != null) AppComposerBackground.save(v);
                },
                children: {
                  ComposerBackground.standard: Text(
                    l10n.appearanceComposerBackgroundStandard,
                    textAlign: TextAlign.center,
                  ),
                  ComposerBackground.frostBlur: Text(
                    l10n.appearanceComposerBackgroundFrost,
                    textAlign: TextAlign.center,
                  ),
                  if (LiquidGlass.isSupported)
                    ComposerBackground.liquidGlass: Text(
                      l10n.appearanceGlassMaterial,
                      textAlign: TextAlign.center,
                    ),
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavPillStyleCard extends StatelessWidget {
  const _NavPillStyleCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (IosGlass.of(context)) {
      return ValueListenableBuilder<NavPillStyle>(
        valueListenable: AppNavPillStyle.current,
        builder: (context, current, _) {
          final selectable =
              current == NavPillStyle.liquidGlass && !LiquidGlass.isSupported
              ? NavPillStyle.frostBlur
              : current;
          return _IosChoice<NavPillStyle>(
            title: l10n.appearanceNavPillTitle,
            subtitle: l10n.appearanceNavPillSubtitle,
            value: selectable,
            onChanged: (value) => unawaited(AppNavPillStyle.save(value)),
            options: [
              IosCheckOption(
                value: NavPillStyle.auto,
                label: l10n.appearanceStyleAuto,
              ),
              IosCheckOption(
                value: NavPillStyle.glossy,
                label: l10n.appearanceNavPillGlossy,
              ),
              IosCheckOption(
                value: NavPillStyle.frostBlur,
                label: l10n.appearanceNavPillFrost,
              ),
              if (LiquidGlass.isSupported)
                IosCheckOption(
                  value: NavPillStyle.liquidGlass,
                  label: l10n.appearanceGlassMaterial,
                ),
            ],
          );
        },
      );
    }
    final cs = Theme.of(context).colorScheme;
    return SettingsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.appearanceNavPillTitle,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: IosGlass.of(context) ? IosTypography.listTitle : 16,
              fontWeight: IosGlass.of(context)
                  ? IosTypography.semibold
                  : FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.appearanceNavPillSubtitle,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<NavPillStyle>(
            valueListenable: AppNavPillStyle.current,
            builder: (context, current, _) {
              final selectable =
                  current == NavPillStyle.liquidGlass &&
                      !LiquidGlass.isSupported
                  ? NavPillStyle.frostBlur
                  : current;
              return IosSegmentedControl<NavPillStyle>(
                groupValue: selectable,
                onValueChanged: (v) {
                  if (v != null) AppNavPillStyle.save(v);
                },
                children: {
                  NavPillStyle.auto: Text(
                    l10n.appearanceStyleAuto,
                    textAlign: TextAlign.center,
                  ),
                  NavPillStyle.glossy: Text(
                    l10n.appearanceNavPillGlossy,
                    textAlign: TextAlign.center,
                  ),
                  NavPillStyle.frostBlur: Text(
                    l10n.appearanceNavPillFrost,
                    textAlign: TextAlign.center,
                  ),
                  if (LiquidGlass.isSupported)
                    NavPillStyle.liquidGlass: Text(
                      l10n.appearanceGlassMaterial,
                      textAlign: TextAlign.center,
                    ),
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GradientToggleCard extends StatelessWidget {
  const _GradientToggleCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return SettingsPanel(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      child: Row(
        children: [
          Icon(
            IosSymbols.blurOn(context),
            color: cs.onSurface,
            size: 24,
            weight: 500,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appearanceGradientTitle,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.appearanceGradientSubtitle,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: AppPillGradient.current,
            builder: (context, value, _) => GlassSwitch(
              value: value,
              onChanged: (v) {
                if (!IosGlass.of(context)) {
                  Haptics.selection();
                }
                AppPillGradient.save(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SpectrumToggleCard extends StatelessWidget {
  const _SpectrumToggleCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return SettingsPanel(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      child: Row(
        children: [
          Icon(
            IosSymbols.graphicEq(context),
            color: cs.onSurface,
            size: 24,
            weight: 500,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appearanceSpectrumTitle,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.appearanceSpectrumSubtitle,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: AppSpectrumBackground.current,
            builder: (context, value, _) => GlassSwitch(
              value: value,
              onChanged: (v) {
                if (!IosGlass.of(context)) {
                  Haptics.selection();
                }
                AppSpectrumBackground.save(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSection extends StatefulWidget {
  final ValueNotifier<Color> color;
  final ValueNotifier<bool> isSystem;

  const _PreviewSection({required this.color, required this.isSystem});

  @override
  State<_PreviewSection> createState() => _PreviewSectionState();
}

class _PreviewSectionState extends State<_PreviewSection> {
  ColorScheme? _cachedScheme;
  Color? _cachedColor;
  Brightness? _cachedBrightness;

  ColorScheme _schemeFor(Color color, Brightness brightness) {
    if (_cachedScheme != null &&
        _cachedColor == color &&
        _cachedBrightness == brightness) {
      return _cachedScheme!;
    }
    _cachedColor = color;
    _cachedBrightness = brightness;
    _cachedScheme = ColorScheme.fromSeed(
      seedColor: color,
      brightness: brightness,
    );
    return _cachedScheme!;
  }

  @override
  Widget build(BuildContext context) {
    final outerCs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return ValueListenableBuilder<bool>(
      valueListenable: widget.isSystem,
      builder: (context, isSystem, _) {
        if (isSystem) {
          return Theme(
            data: Theme.of(context).copyWith(colorScheme: outerCs),
            child: const _ChatPreview(),
          );
        }
        return ValueListenableBuilder<Color>(
          valueListenable: widget.color,
          builder: (context, color, _) {
            return Theme(
              data: Theme.of(
                context,
              ).copyWith(colorScheme: _schemeFor(color, brightness)),
              child: const _ChatPreview(),
            );
          },
        );
      },
    );
  }
}

class _ChatPreview extends StatelessWidget {
  const _ChatPreview();

  List<_PreviewMsg> _messagesFor(AppLocalizations l10n) => [
    _PreviewMsg(l10n.appearancePreviewHello, true, true, false),
    _PreviewMsg(l10n.appearancePreviewHowIsIt, true, false, true),
    _PreviewMsg(l10n.appearancePreviewHello, false, true, false),
    _PreviewMsg(l10n.appearancePreviewHmm, false, false, false),
    _PreviewMsg(l10n.appearancePreviewNotBad, false, false, true),
  ];

  BorderRadius _radiusFor(
    _PreviewMsg msg,
    BubbleStyle style,
    BubbleBehavior behavior,
  ) {
    return computeBubbleRadius(
      isMe: msg.isMe,
      isTop: msg.isTop,
      isBottom: msg.isBottom,
      style: style,
      behavior: behavior,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final messages = _messagesFor(l10n);

    return ListenableBuilder(
      listenable: Listenable.merge([
        AppBubbleShape.current,
        AppBubbleBehavior.current,
      ]),
      builder: (context, _) {
        final style = AppBubbleShape.current.value;
        final behavior = AppBubbleBehavior.current.value;
        return SettingsPanel(
          color: cs.surfaceContainerLow,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < messages.length; i++) ...[
                if (i > 0) SizedBox(height: messages[i].isTop ? 8 : 2),
                _PreviewBubble(
                  text: messages[i].text,
                  isMe: messages[i].isMe,
                  radius: _radiusFor(messages[i], style, behavior),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PreviewMsg {
  final String text;
  final bool isMe;
  final bool isTop;
  final bool isBottom;
  const _PreviewMsg(this.text, this.isMe, this.isTop, this.isBottom);
}

class _PreviewBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final BorderRadius radius;

  const _PreviewBubble({
    required this.text,
    required this.isMe,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isMe ? cs.primaryContainer : cs.surfaceContainerHighest;
    final fg = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: radius),
        child: Text(
          text,
          style: TextStyle(color: fg, fontSize: 15, height: 1.3),
        ),
      ),
    );
  }
}

class _ColorPickerCard extends StatelessWidget {
  final ValueNotifier<Color> color;
  final ValueNotifier<bool> isSystem;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onReset;

  const _ColorPickerCard({
    required this.color,
    required this.isSystem,
    required this.expanded,
    required this.onToggle,
    required this.onColorChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<bool>(
      valueListenable: isSystem,
      builder: (context, sys, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: color,
          builder: (context, col, _) => _buildBody(context, cs, l10n, col, sys),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    Color col,
    bool sys,
  ) {
    final swatchColor = sys ? cs.primary : col;

    return SettingsPanel(
      child: Column(
        children: [
          IosTappable(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: swatchColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appearanceAccentColorTitle,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sys
                              ? l10n.appearanceAccentColorSystem
                              : l10n.appearanceAccentColorSubtitle,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: expanded ? 0.5 : 0,
                    child: Icon(
                      IosSymbols.expandMore(context),
                      color: cs.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ColorWheelPicker(
                          color: swatchColor,
                          onChanged: onColorChanged,
                        ),
                        const SizedBox(height: 20),
                        if (IosGlass.of(context))
                          IosCapsuleButton(
                            label: sys
                                ? l10n.appearanceAccentColorSystemActive
                                : l10n.appearanceAccentColorReset,
                            onPressed: sys ? null : onReset,
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: IosSettingsButton(
                              filled: false,
                              onPressed: sys ? null : onReset,
                              icon: IosSymbols.autoAwesome(context),
                              label: sys
                                  ? l10n.appearanceAccentColorSystemActive
                                  : l10n.appearanceAccentColorReset,
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _BubbleShapeCard extends StatelessWidget {
  final ValueChanged<BubbleStyle> onChanged;

  const _BubbleShapeCard({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (IosGlass.of(context)) {
      return ValueListenableBuilder<BubbleStyle>(
        valueListenable: AppBubbleShape.current,
        builder: (context, current, _) {
          return _IosChoice<BubbleStyle>(
            title: l10n.appearanceBubbleShapeTitle,
            subtitle: l10n.appearanceBubbleShapeSubtitle,
            value: current,
            onChanged: onChanged,
            options: [
              IosCheckOption(
                value: BubbleStyle.mobile,
                label: l10n.appearanceBubbleShapeMobile,
              ),
              IosCheckOption(
                value: BubbleStyle.desktop,
                label: l10n.appearanceBubbleShapeDesktop,
              ),
            ],
          );
        },
      );
    }
    final cs = Theme.of(context).colorScheme;

    return SettingsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.appearanceBubbleShapeTitle,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: IosGlass.of(context) ? IosTypography.listTitle : 16,
              fontWeight: IosGlass.of(context)
                  ? IosTypography.semibold
                  : FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.appearanceBubbleShapeSubtitle,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<BubbleStyle>(
            valueListenable: AppBubbleShape.current,
            builder: (context, current, _) {
              return IosSegmentedControl<BubbleStyle>(
                groupValue: current,
                children: {
                  BubbleStyle.mobile: Text(
                    l10n.appearanceBubbleShapeMobile,
                    textAlign: TextAlign.center,
                  ),
                  BubbleStyle.desktop: Text(
                    l10n.appearanceBubbleShapeDesktop,
                    textAlign: TextAlign.center,
                  ),
                },
                onValueChanged: (v) {
                  if (v != null) onChanged(v);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BubbleBehaviorCard extends StatelessWidget {
  final ValueChanged<BubbleBehavior> onChanged;

  const _BubbleBehaviorCard({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (IosGlass.of(context)) {
      return ValueListenableBuilder<BubbleBehavior>(
        valueListenable: AppBubbleBehavior.current,
        builder: (context, current, _) {
          return _IosChoice<BubbleBehavior>(
            title: l10n.appearanceBubbleBehaviorTitle,
            subtitle: l10n.appearanceBubbleBehaviorSubtitle,
            value: current,
            onChanged: onChanged,
            options: [
              IosCheckOption(
                value: BubbleBehavior.mutable,
                label: l10n.appearanceBubbleBehaviorMutable,
              ),
              IosCheckOption(
                value: BubbleBehavior.immutable,
                label: l10n.appearanceBubbleBehaviorImmutable,
              ),
            ],
          );
        },
      );
    }
    final cs = Theme.of(context).colorScheme;

    return SettingsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.appearanceBubbleBehaviorTitle,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: IosGlass.of(context) ? IosTypography.listTitle : 16,
              fontWeight: IosGlass.of(context)
                  ? IosTypography.semibold
                  : FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.appearanceBubbleBehaviorSubtitle,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<BubbleBehavior>(
            valueListenable: AppBubbleBehavior.current,
            builder: (context, current, _) {
              return IosSegmentedControl<BubbleBehavior>(
                groupValue: current,
                children: {
                  BubbleBehavior.mutable: Text(
                    l10n.appearanceBubbleBehaviorMutable,
                    textAlign: TextAlign.center,
                  ),
                  BubbleBehavior.immutable: Text(
                    l10n.appearanceBubbleBehaviorImmutable,
                    textAlign: TextAlign.center,
                  ),
                },
                onValueChanged: (v) {
                  if (v != null) onChanged(v);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
