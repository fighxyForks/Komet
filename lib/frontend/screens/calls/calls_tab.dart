import 'dart:async';

import 'package:flutter/material.dart';
import '../../../main.dart' show api, accountModule;
import '../../../backend/modules/account.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/format.dart';
import '../../../core/calls/call_controller.dart';
import '../../../backend/modules/calls.dart';
import '../../widgets/komet_avatar.dart';
import '../../widgets/connection_status.dart';
import '../../widgets/reload_on_reconnect.dart';
import '../../widgets/custom_notification.dart';
import '../../widgets/chat_menu_overlay.dart';
import '../../widgets/small_spinner.dart';
import '../../widgets/prompt_dialog.dart';
import '../../widgets/call_link_handler.dart';
import '../../widgets/spectrum_tint.dart';
import '../../../l10n/app_localizations.dart';
import 'call_link_sheet.dart';
import 'call_screen.dart';
import '../../../core/native/native_list_bridge.dart';
import '../../native/native_list_view.dart';
import '../../../core/config/app_fonts.dart';
import '../../widgets/glass/ios_glass.dart';
import '../../widgets/glass/ios_route.dart';
import '../../widgets/glass/ios_typography.dart';
import '../../widgets/glass/ios_palette.dart';
import '../../widgets/glass/ios_symbols.dart';
import '../../widgets/glass/ios_tappable.dart';
import '../../widgets/glass/ios_empty_state.dart';

class CallsTab extends StatefulWidget {
  const CallsTab({super.key});

  @override
  State<CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends State<CallsTab>
    with ReloadOnReconnect, SpectrumSurface {
  List<CallLogEntry> _calls = [];
  final Set<String> _removing = {};
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0 for 'Все', 1 for 'Пропущенные'
  StreamSubscription<LoginStatus>? _loginSub;

  @override
  void initState() {
    super.initState();
    if (accountModule.isLoggedIn) {
      _loadHistory();
    } else {
      _loginSub = accountModule.loginStatusStream.listen((status) {
        if (status == LoginStatus.success) {
          _loginSub?.cancel();
          _loginSub = null;
          _loadHistory();
        }
      });
    }
  }

  @override
  void dispose() {
    _loginSub?.cancel();
    super.dispose();
  }

  @override
  void reloadAfterReconnect() {
    if (accountModule.isLoggedIn) _loadHistory();
  }

  Future<void> _loadHistory() async {
    final p = await AppDatabase.loadActiveProfile();
    if (p == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final callsModule = CallsModule(api);
    List<CallLogEntry> calls;
    try {
      calls = await callsModule.fetchHistory(p.id, p.id);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final List<CallLogEntry> grouped = [];
    for (final call in calls) {
      if (grouped.isNotEmpty &&
          grouped.last.peerId == call.peerId &&
          grouped.last.status == call.status &&
          _isSameDay(grouped.last.time, call.time)) {
        final last = grouped.removeLast();
        grouped.add(
          CallLogEntry(
            id: last.id,
            accountId: last.accountId,
            peerId: last.peerId,
            name: last.name,
            avatarUrl: last.avatarUrl,
            status: last.status,
            time: last.time,
            count: last.count + 1,
            isGroup: last.isGroup,
          ),
        );
      } else {
        grouped.add(call);
      }
    }

    if (mounted) {
      setState(() {
        _calls = grouped;
        _isLoading = false;
      });
    }
  }

  bool _isSameDay(int time1, int time2) {
    if (time1 == 0 || time2 == 0) return false;
    final d1 = DateTime.fromMillisecondsSinceEpoch(time1);
    final d2 = DateTime.fromMillisecondsSinceEpoch(time2);
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.day} ${kRuMonthsShort[dt.month - 1]}';
  }

  Widget _buildCallItem(
    BuildContext context,
    ColorScheme cs,
    CallLogEntry call,
  ) {
    final bool isMissed = call.status == CallStatus.missed;

    final ios = IosGlass.of(context);
    final String statusText;
    final IconData statusIcon;
    switch (call.status) {
      case CallStatus.missed:
        statusText = 'Пропущенный';
        statusIcon = IosSymbols.phoneMissed(context);
        break;
      case CallStatus.canceled:
        statusText = 'Отменённый';
        statusIcon = IosSymbols.phoneDisabled(context);
        break;
      case CallStatus.outgoing:
        statusText = 'Исходящий';
        statusIcon = IosSymbols.callOutgoing(context);
        break;
      case CallStatus.incoming:
        statusText = 'Входящий';
        statusIcon = IosSymbols.callIncoming(context);
        break;
    }

    final String displayName = call.count > 1
        ? '${call.name} (${call.count})'
        : call.name;

    final secondary = ios
        ? IosPalette.secondaryLabel(cs)
        : cs.onSurfaceVariant;

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: call.isGroup ? cs.primaryContainer : null,
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: call.isGroup
                ? Icon(
                    IosSymbols.people(context),
                    color: cs.onPrimaryContainer,
                    size: 26,
                  )
                : KometAvatar(
                    name: call.name,
                    imageUrl: call.avatarUrl,
                    size: 48,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: isMissed
                        ? cs.error
                        : (ios ? IosPalette.label(cs) : cs.onSurface),
                    fontSize: ios ? IosTypography.listTitle : 16,
                    fontWeight: ios ? IosType.title : FontWeight.w500,
                    letterSpacing: ios
                        ? IosTypography.letterSpacing(IosTypography.listTitle)
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(statusIcon, size: 14, color: secondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: secondary,
                          fontSize:
                              ios ? IosTypography.listSubtitle : 14,
                          letterSpacing: ios
                              ? IosTypography.letterSpacing(
                                  IosTypography.listSubtitle,
                                )
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDate(call.time),
            style: TextStyle(
              color: secondary.withValues(alpha: 0.85),
              fontSize: ios ? IosTypography.callLabel : 12,
            ),
          ),
          const SizedBox(width: 4),
          Builder(
            builder: (btnContext) => IconButton(
              icon: Icon(
                IosSymbols.ellipsis(context),
                color: secondary,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              onPressed: () => _showCallMenu(btnContext, call),
            ),
          ),
        ],
      ),
    );

    return IosTappable(
      onTap: call.isGroup ? null : () => _callBack(call),
      child: row,
    );
  }

  void _showCallMenu(BuildContext anchorContext, CallLogEntry call) {
    final box = anchorContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final anchorRect = box.localToGlobal(Offset.zero) & box.size;
    showChatMenu(
      context: context,
      anchorRect: anchorRect,
      items: [
        ChatMenuItem(
          icon: IosSymbols.delete(context),
          label: 'Удалить',
          destructive: true,
          onTap: () => _deleteCall(call),
        ),
        if (!call.isGroup)
          ChatMenuItem(
            icon: IosSymbols.phone(context),
            label: 'Перезвонить',
            onTap: () => _callBack(call),
          ),
      ],
    );
  }

  void _deleteCall(CallLogEntry call) {
    if (_removing.contains(call.id)) return;
    setState(() => _removing.add(call.id));
    final historyId = int.tryParse(call.id);
    if (historyId != null) {
      unawaited(CallsModule(api).deleteHistory([historyId]));
    }
  }

  void _onRemovalComplete(String id) {
    if (!mounted) return;
    setState(() {
      _calls.removeWhere((c) => c.id == id);
      _removing.remove(id);
    });
  }

  Future<void> _callBack(CallLogEntry call) async {
    if (call.peerId <= 0) {
      showCustomNotification(context, 'Не удалось определить собеседника');
      return;
    }
    final navigator = Navigator.of(context);
    final avatarUrl = (call.avatarUrl?.isNotEmpty ?? false)
        ? call.avatarUrl
        : null;
    final active = CallController.instance.activeSession;
    if (active != null) {
      await navigator.push(
        iosPageRoute(context,
          builder: (_) => CallScreen(
            name: call.name,
            avatarUrl: avatarUrl,
            session: active,
          ),
        ),
      );
      return;
    }
    try {
      final session = await CallController.instance.startOutgoing(call.peerId);
      if (!mounted) return;
      await navigator.push(
        iosPageRoute(context,
          builder: (_) => CallScreen(
            name: call.name,
            avatarUrl: avatarUrl,
            session: session,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showCustomNotification(context, 'Не удалось начать звонок');
    }
  }

  Widget _buildLinkAction(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool alignEnd = false,
  }) {
    final ios = IosGlass.of(context);
    final text = Text(
      label,
      style: TextStyle(
        color: cs.primary,
        fontSize: ios ? IosTypography.listTitle : 16,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: ios ? TextOverflow.visible : TextOverflow.ellipsis,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisAlignment: alignEnd
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary, size: 24),
            const SizedBox(width: 12),
            Flexible(
              child: ios
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: alignEnd
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: text,
                    )
                  : text,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createGroupCall() async {
    final controller = CallController.instance;
    if (controller.isBusy) {
      showCustomNotification(context, 'Звонок уже идёт');
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    CreatedCall created;
    try {
      created = await controller.createConference();
    } catch (e) {
      if (mounted) {
        showCustomNotification(context, '${l10n.callLinkCreateFailed}: $e');
      }
      return;
    }
    if (!mounted) return;

    final start = await showCreatedCallSheet(context, call: created);
    if (!start || !mounted) return;

    final navigator = Navigator.of(context);
    final name = created.callName ?? l10n.callLinkGroupCall;
    try {
      final session = await controller.joinByLink(created.joinToken);
      if (!mounted) return;
      await navigator.push(
        iosPageRoute(context,
          builder: (_) =>
              CallScreen(name: name, session: session, isGroup: true),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showCustomNotification(context, 'Не удалось начать звонок: $e');
    }
  }

  Future<void> _joinGroupCall() async {
    if (CallController.instance.isBusy) {
      showCustomNotification(context, 'Звонок уже идёт');
      return;
    }

    final url = await showTextInputDialog(
      context,
      title: 'Присоединиться к звонку',
      description: 'Вставьте ссылку-приглашение',
      hint: 'https://max.ru/joincall/...',
      confirmLabel: 'Присоединиться',
      keyboardType: TextInputType.url,
    );
    if (url == null || url.trim().isEmpty || !mounted) return;

    final handled = await tryHandleCallLink(context, url.trim());
    if (!handled && mounted) {
      showCustomNotification(context, 'Это не ссылка на звонок');
    }
  }

  Widget _buildTabItem(String label, int index, ColorScheme cs) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? cs.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? cs.primary
                : (IosGlass.of(context)
                    ? IosPalette.secondaryLabel(cs)
                    : cs.onSurfaceVariant),
            fontSize: IosGlass.of(context) ? IosTypography.body : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static String _callSymbol(CallStatus status) => switch (status) {
    CallStatus.missed => 'phone.down.fill',
    CallStatus.canceled => 'phone.down',
    CallStatus.outgoing => 'phone.arrow.up.right',
    CallStatus.incoming => 'phone.arrow.down.left',
  };

  static String _callStatusText(CallStatus status) => switch (status) {
    CallStatus.missed => 'Пропущенный',
    CallStatus.canceled => 'Отменённый',
    CallStatus.outgoing => 'Исходящий',
    CallStatus.incoming => 'Входящий',
  };

  CallLogEntry? _callById(String id) {
    for (final call in _calls) {
      if (call.id == id) return call;
    }
    return null;
  }

  List<NativeListSection> _nativeSections() {
    final calls = _selectedTabIndex == 1
        ? _calls.where((c) => c.status == CallStatus.missed)
        : _calls;
    return [
      const NativeListSection(
        id: 'actions',
        rows: [
          NativeListRow(
            id: 'action:create',
            style: NativeListRowStyle.action,
            title: 'Создать звонок',
            symbol: 'link',
          ),
          NativeListRow(
            id: 'action:join',
            style: NativeListRowStyle.action,
            title: 'Присоединиться',
            symbol: 'person.badge.plus',
          ),
        ],
      ),
      NativeListSection(
        id: 'calls',
        rows: [
          for (final call in calls)
            if (!_removing.contains(call.id))
              NativeListRow(
                id: 'call:${call.id}',
                title: call.count > 1
                    ? '${call.name} (${call.count})'
                    : call.name,
                alert: call.status == CallStatus.missed,
                subtitle: _callStatusText(call.status),
                subtitleSymbol: _callSymbol(call.status),
                trailing: _formatDate(call.time),
                avatarUrl: call.avatarUrl ?? '',
                avatarSeed: call.peerId,
                avatarSymbol: call.isGroup ? 'person.2.fill' : null,
                menu: [
                  if (!call.isGroup)
                    const NativeListAction(
                      id: 'callback',
                      title: 'Перезвонить',
                      symbol: 'phone',
                    ),
                  const NativeListAction(
                    id: 'delete',
                    title: 'Удалить',
                    symbol: 'trash',
                    destructive: true,
                  ),
                ],
              ),
        ],
      ),
    ];
  }

  void _onNativeTap(String rowId) {
    switch (rowId) {
      case 'action:create':
        unawaited(_createGroupCall());
      case 'action:join':
        unawaited(_joinGroupCall());
      default:
        final call = _callById(rowId.substring('call:'.length));
        if (call != null && !call.isGroup) unawaited(_callBack(call));
    }
  }

  void _onNativeMenu(String rowId, String actionId) {
    final call = _callById(rowId.substring('call:'.length));
    if (call == null) return;
    switch (actionId) {
      case 'callback':
        unawaited(_callBack(call));
      case 'delete':
        _deleteCall(call);
        _onRemovalComplete(call.id);
    }
  }

  Widget _buildNative(ColorScheme cs) {
    return Scaffold(
      backgroundColor: IosPalette.background(cs),
      body: SafeArea(
        bottom: false,
        child: NativeListView(
          sections: _isLoading ? const [] : _nativeSections(),
          chrome: {
            'title': 'Звонки',
            'segments': const ['Все', 'Пропущенные'],
            'segment': _selectedTabIndex,
            'loading': _isLoading,
            'emptyText': 'Нет звонков',
            'accent': cs.primary.toARGB32(),
            'bottomInset': 100.0,
          },
          callbacks: NativeListCallbacks(
            onTap: _onNativeTap,
            onMenu: _onNativeMenu,
            onSegment: (index) => setState(() => _selectedTabIndex = index),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NativeListBridge.eligibility,
      builder: (context, _) =>
          IosGlass.of(context) && NativeListBridge.isEligible
          ? _buildNative(Theme.of(context).colorScheme)
          : _buildFlutter(context),
    );
  }

  Widget _buildFlutter(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final filteredCalls = _selectedTabIndex == 1
        ? _calls.where((c) => c.status == CallStatus.missed).toList()
        : _calls;

    final ios = IosGlass.of(context);
    final bg = ios ? IosPalette.grouped(cs) : spectrumSurfaceColor(cs);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, ios ? 8 : 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Звонки',
                    style: TextStyle(
                      color: ios ? IosPalette.label(cs) : cs.onSurface,
                      fontSize: ios ? IosTypography.largeTitle : 24,
                      fontWeight:
                          ios ? IosType.largeTitle : FontWeight.w700,
                      fontFamily: displayFontOf(context),
                      letterSpacing: ios
                          ? IosTypography.letterSpacing(
                              IosTypography.largeTitle,
                            )
                          : null,
                    ),
                  ),
                  const ConnectionStatusLine(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLinkAction(
                      cs,
                      icon: IosSymbols.link(context),
                      label: ios ? l10n.callsActionCreate : 'Создать звонок',
                      onTap: _createGroupCall,
                    ),
                  ),
                  Expanded(
                    child: _buildLinkAction(
                      cs,
                      icon: IosSymbols.personAddGroup(context),
                      label: ios ? l10n.callsActionJoin : 'Присоединиться',
                      onTap: _joinGroupCall,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  _buildTabItem('Все', 0, cs),
                  const SizedBox(width: 8),
                  _buildTabItem('Пропущенные', 1, cs),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: SmallSpinner(size: 36))
                  : filteredCalls.isEmpty
                  ? IosEmptyState(
                      icon: IosSymbols.phone(context),
                      message: 'Нет звонков',
                    )
                  : ListView.builder(
                      key: const PageStorageKey<String>('calls-list'),
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: filteredCalls.length,
                      itemBuilder: (context, index) {
                        final call = filteredCalls[index];
                        return _RemovableCallEntry(
                          key: ValueKey(call.id),
                          removing: _removing.contains(call.id),
                          onDismissed: () => _onRemovalComplete(call.id),
                          child: _buildCallItem(context, cs, call),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemovableCallEntry extends StatefulWidget {
  final bool removing;
  final VoidCallback onDismissed;
  final Widget child;

  const _RemovableCallEntry({
    required Key key,
    required this.removing,
    required this.onDismissed,
    required this.child,
  }) : super(key: key);

  @override
  State<_RemovableCallEntry> createState() => _RemovableCallEntryState();
}

class _RemovableCallEntryState extends State<_RemovableCallEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1.0,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) widget.onDismissed();
  }

  @override
  void didUpdateWidget(covariant _RemovableCallEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.removing && !oldWidget.removing) _controller.reverse();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: _animation, child: widget.child),
    );
  }
}
