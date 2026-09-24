import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/calls/call_admin.dart';
import '../../../core/calls/call_session.dart';
import '../../widgets/animated_slash_icon.dart';
import '../../widgets/custom_notification.dart';
import '../../widgets/komet_avatar.dart';
import '../../widgets/prompt_dialog.dart';
import '../../widgets/sheet_helpers.dart';
import '../../../core/config/app_fonts.dart';
import '../../widgets/glass/ios_sheet.dart';
import '../../widgets/glass/ios_symbols.dart';

class CallParticipantView {
  final String name;
  final String? avatarUrl;

  const CallParticipantView({required this.name, this.avatarUrl});
}

typedef CallParticipantResolver =
    CallParticipantView Function(CallParticipant participant);

Future<void> showCallParticipantsSheet(
  BuildContext context, {
  required CallSession session,
  required ColorScheme scheme,
  required CallParticipantResolver resolve,
}) {
  return showIosSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: scheme.surfaceContainerHigh,
    shape: kSheetShape,
    builder: (_) => Theme(
      data: Theme.of(context).copyWith(colorScheme: scheme),
      child: _ParticipantsSheet(session: session, resolve: resolve),
    ),
  );
}

class _ParticipantsSheet extends StatefulWidget {
  final CallSession session;
  final CallParticipantResolver resolve;

  const _ParticipantsSheet({required this.session, required this.resolve});

  @override
  State<_ParticipantsSheet> createState() => _ParticipantsSheetState();
}

class _ParticipantsSheetState extends State<_ParticipantsSheet> {
  final Map<CallOption, bool> _options = {};
  final Map<CallFeature, Set<CallRoleName>> _features = {};
  bool _recording = false;
  StreamSubscription<void>? _infoSub;

  @override
  void initState() {
    super.initState();
    _infoSub = widget.session.infoUpdates.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _infoSub?.cancel();
    super.dispose();
  }

  CallParticipant? get _self {
    for (final p in widget.session.participants) {
      if (p.isSelf) return p;
    }
    return null;
  }

  Future<bool> _run(Future<void> Function(CallAdmin admin) action) async {
    final admin = widget.session.admin;
    if (admin == null) {
      showCustomNotification(context, 'Нет связи с сервером звонка');
      return false;
    }
    try {
      await action(admin);
      return true;
    } catch (e) {
      if (mounted) showCustomNotification(context, 'Не удалось: $e');
      return false;
    }
  }

  CallParticipantRef _ref(CallParticipant p) => CallParticipantRef(p.id);

  void _participantActions(CallParticipant p) {
    final cs = Theme.of(context).colorScheme;
    final view = widget.resolve(p);
    final isAdmin = p.isAdmin;
    final isSpeaker = p.isSpeaker;

    showIosSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: cs.surfaceContainerHigh,
      shape: kSheetShape,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(
                  view.name,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: displayFontOf(context),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  p.roles.isEmpty ? 'Участник' : p.roles.join(' · '),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ),
              _action(cs, IosSymbols.micOff(context), 'Выключить микрофон', () {
                Navigator.pop(sheetContext);
                _run((a) => a.muteMicrophone(_ref(p)));
              }),
              _action(cs, IosSymbols.videocamOff(context), 'Запросить камеру', () {
                Navigator.pop(sheetContext);
                _run(
                  (a) =>
                      a.requestMedia({CallMedia.video}, participant: _ref(p)),
                );
              }),
              _action(
                cs,
                isAdmin ? IosSymbols.removeModerator(context) : IosSymbols.shieldPerson(context),
                isAdmin ? 'Снять администратора' : 'Назначить администратором',
                () {
                  Navigator.pop(sheetContext);
                  _run(
                    (a) => a.setRoles(_ref(p), [
                      CallRoleName.admin,
                    ], revoke: isAdmin),
                  );
                },
              ),
              _action(
                cs,
                isSpeaker ? IosSymbols.voiceOverOff(context) : IosSymbols.recordVoiceOver(context),
                isSpeaker ? 'Убрать из спикеров' : 'Сделать спикером',
                () {
                  Navigator.pop(sheetContext);
                  _run(
                    (a) => a.setRoles(_ref(p), [
                      CallRoleName.speaker,
                    ], revoke: isSpeaker),
                  );
                },
              ),
              _action(cs, IosSymbols.arrowUpward(context), 'Повысить (promote)', () {
                Navigator.pop(sheetContext);
                _run((a) => a.setPromoted(_ref(p), true));
              }),
              _action(cs, IosSymbols.arrowDownward(context), 'Понизить (demote)', () {
                Navigator.pop(sheetContext);
                _run((a) => a.setPromoted(_ref(p), false));
              }),
              _action(cs, IosSymbols.pin(context), 'Закрепить', () {
                Navigator.pop(sheetContext);
                _run((a) => a.setPinned(_ref(p), true));
              }),
              _action(cs, IosSymbols.pinOff(context), 'Открепить', () {
                Navigator.pop(sheetContext);
                _run((a) => a.setPinned(_ref(p), false));
              }),
              _action(cs, IosSymbols.personRemove(context), 'Удалить из звонка', () {
                Navigator.pop(sheetContext);
                _run((a) => a.removeParticipant(_ref(p)));
              }, destructive: true),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions() {
    final cs = Theme.of(context).colorScheme;
    showIosSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cs.surfaceContainerHigh,
      shape: kSheetShape,
      builder: (_) => Theme(
        data: Theme.of(context).copyWith(colorScheme: cs),
        child: StatefulBuilder(
          builder: (_, setSheet) => SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sheetTitle(cs, 'Настройки звонка'),
                  for (final option in CallOption.values)
                    SwitchListTile(
                      value: _options[option] ?? false,
                      title: Text(
                        _optionLabel(option),
                        style: TextStyle(color: cs.onSurface, fontSize: 15),
                      ),
                      subtitle: Text(
                        option.wire,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      onChanged: (value) async {
                        setSheet(() => _options[option] = value);
                        final ok = await _run(
                          (a) => a.setOptions({option: value}),
                        );
                        if (!ok) setSheet(() => _options[option] = !value);
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFeatures() {
    final cs = Theme.of(context).colorScheme;
    showIosSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cs.surfaceContainerHigh,
      shape: kSheetShape,
      builder: (_) => Theme(
        data: Theme.of(context).copyWith(colorScheme: cs),
        child: StatefulBuilder(
          builder: (_, setSheet) => SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sheetTitle(cs, 'Кому доступны функции'),
                  for (final feature in CallFeature.values)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _featureLabel(feature),
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final role in CallRoleName.values)
                                FilterChip(
                                  label: Text(role.wire),
                                  selected:
                                      _features[feature]?.contains(role) ??
                                      false,
                                  onSelected: (selected) {
                                    final set = _features.putIfAbsent(
                                      feature,
                                      () => <CallRoleName>{},
                                    );
                                    setSheet(() {
                                      selected
                                          ? set.add(role)
                                          : set.remove(role);
                                    });
                                    _run(
                                      (a) => a.enableFeatureForRoles(
                                        feature,
                                        set.toList(),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addByLink() async {
    final link = await showTextInputDialog(
      context,
      title: 'Добавить участника',
      description: 'Ссылка-приглашение участника',
      confirmLabel: 'Добавить',
    );
    if (link == null || link.trim().isEmpty || !mounted) return;
    await _run((a) => a.addParticipantByLink(link.trim()));
  }

  String _optionLabel(CallOption option) => switch (option) {
    CallOption.requireAuthToJoin => 'Только авторизованные',
    CallOption.waitingHall => 'Зал ожидания',
    CallOption.recurring => 'Повторяющийся звонок',
    CallOption.feedback => 'Сбор отзывов',
    CallOption.audienceMode => 'Режим зрителей',
    CallOption.asr => 'Расшифровка речи',
    CallOption.waitForAdmin => 'Ждать администратора',
    CallOption.adminIsHere => 'Администратор на месте',
  };

  String _featureLabel(CallFeature feature) => switch (feature) {
    CallFeature.addParticipant => 'Добавлять участников',
    CallFeature.admin => 'Права администратора',
    CallFeature.asr => 'Расшифровка речи',
    CallFeature.movieShare => 'Совместный просмотр',
    CallFeature.record => 'Запись звонка',
    CallFeature.speaker => 'Быть спикером',
  };

  Widget _sheetTitle(ColorScheme cs, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
    child: Text(
      text,
      style: TextStyle(
        color: cs.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: displayFontOf(context),
      ),
    ),
  );

  Widget _action(
    ColorScheme cs,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool destructive = false,
  }) {
    final color = destructive ? cs.error : cs.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontSize: 16)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final participants = widget.session.participants;
    final self = _self;
    final handRaised = self?.handRaised ?? false;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetTitle(cs, 'Участники · ${participants.length}'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(cs, IosSymbols.micOff(context), 'Заглушить всех', () {
                  _run((a) => a.muteEveryone());
                }),
                _chip(cs, IosSymbols.doNotTouch(context), 'Опустить руки', () {
                  _run((a) => a.lowerAllHands());
                }),
                _chip(
                  cs,
                  handRaised ? IosSymbols.backHand(context) : IosSymbols.handRaised(context),
                  handRaised ? 'Опустить руку' : 'Поднять руку',
                  () => _run((a) => a.setHandRaised(!handRaised)),
                  active: handRaised,
                ),
                _chip(
                  cs,
                  _recording
                      ? IosSymbols.stopCircle(context)
                      : IosSymbols.radioChecked(context),
                  _recording ? 'Остановить запись' : 'Начать запись',
                  () async {
                    final next = !_recording;
                    setState(() => _recording = next);
                    final ok = await _run(
                      (a) => next
                          ? a.startRecord(name: 'Запись звонка')
                          : a.stopRecord(),
                    );
                    if (!ok && mounted) setState(() => _recording = !next);
                  },
                  active: _recording,
                ),
                _chip(cs, IosSymbols.tune(context), 'Настройки', _showOptions),
                _chip(cs, IosSymbols.shieldPerson(context), 'Права ролей', _showFeatures),
                _chip(cs, IosSymbols.personAdd(context), 'Добавить по ссылке', _addByLink),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: participants.length,
              itemBuilder: (_, i) => _tile(cs, participants[i]),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _chip(
    ColorScheme cs,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return ActionChip(
      avatar: Icon(
        icon,
        size: 18,
        color: active ? cs.onPrimary : cs.onSurfaceVariant,
      ),
      label: Text(label),
      labelStyle: TextStyle(color: active ? cs.onPrimary : cs.onSurface),
      backgroundColor: active ? cs.primary : cs.surfaceContainerHighest,
      side: BorderSide.none,
      onPressed: onTap,
    );
  }

  Widget _tile(ColorScheme cs, CallParticipant p) {
    final view = widget.resolve(p);
    final subtitle = <String>[
      if (p.isCreator) 'Создатель' else if (p.isAdmin) 'Администратор',
      if (p.isSpeaker) 'Спикер',
      if (p.handRaised) 'Поднял руку',
    ];

    return ListTile(
      leading: KometAvatar(name: view.name, imageUrl: view.avatarUrl, size: 40),
      title: Text(
        view.name,
        style: TextStyle(color: cs.onSurface, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle.join(' · '),
              style: TextStyle(color: cs.primary, fontSize: 13),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (p.screenSharing)
            Icon(IosSymbols.screenShare(context), size: 18, color: cs.primary),
          if (p.videoEnabled)
            Icon(IosSymbols.videocam(context), size: 18, color: cs.onSurfaceVariant),
          AnimatedSlashIcon(
            icon: IosSymbols.mic(context),
            slashedIcon: IosSymbols.micOff(context),
            slashed: !p.audioEnabled,
            size: 18,
            color: p.audioEnabled ? cs.onSurfaceVariant : cs.error,
          ),
        ],
      ),
      onTap: p.isSelf ? null : () => _participantActions(p),
    );
  }
}
