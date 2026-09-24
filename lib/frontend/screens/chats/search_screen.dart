import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../main.dart';
import '../../../backend/modules/chats.dart';
import '../../../backend/modules/contacts.dart';
import '../../../backend/modules/messages.dart' show ContactCache;
import '../../../core/storage/app_database.dart';
import '../../../core/contacts/contact_labels.dart';
import '../../../core/utils/debouncer.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/glass/glass_capsule.dart';
import '../../widgets/glass/ios_glass.dart';
import '../../widgets/glass/ios_palette.dart';
import '../../widgets/glass/ios_typography.dart';
import '../../widgets/glass/ios_symbols.dart';
import '../../widgets/glass/ios_tappable.dart';
import '../../widgets/glass/ios_empty_state.dart';
import '../../widgets/glass/ios_metrics.dart';
import '../../widgets/komet_avatar.dart';
import '../../widgets/small_spinner.dart';
import '../../widgets/swipe_route.dart';
import '../contacts/open_contact_profile.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _debounce = Debouncer(const Duration(milliseconds: 300));
  int _seq = 0;
  int? _accountId;

  bool _loading = false;
  PhoneLookupResult? _phoneResult;
  List<Map<String, dynamic>> _contacts = const [];
  List<Map<String, dynamic>> _chats = const [];
  List<MessageSearchHit> _messages = const [];
  Map<int, Map<String, dynamic>> _msgChatMeta = const {};
  List<ChatSearchHit> _public = const [];

  @override
  void initState() {
    super.initState();
    AppDatabase.loadActiveProfile().then((p) {
      if (mounted) _accountId = p?.id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (value.trim().isEmpty) {
      _debounce.cancel();
      _seq++;
      setState(() {
        _loading = false;
        _phoneResult = null;
        _contacts = const [];
        _chats = const [];
        _messages = const [];
        _msgChatMeta = const {};
        _public = const [];
      });
      return;
    }
    if (_phoneResult != null) {
      setState(() => _phoneResult = null);
    }
    _debounce.run(_runSearch);
  }

  Future<void> _runSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    final token = ++_seq;
    setState(() => _loading = true);

    final accountId = _accountId;
    final phoneQuery = _phoneCandidate(query);
    final results = await Future.wait([
      accountId == null
          ? Future.value(const <Map<String, dynamic>>[])
          : AppDatabase.searchContacts(accountId, query),
      accountId == null
          ? Future.value(const <Map<String, dynamic>>[])
          : AppDatabase.searchChatsByTitle(accountId, query),
      chats.searchMessages(api, query),
      chats.searchPublic(api, query),
      phoneQuery == null
          ? Future<PhoneLookupResult?>.value(null)
          : ContactsModule.findByPhone(api, phoneQuery),
    ]);

    if (!mounted || token != _seq) return;

    final localChats = results[1] as List<Map<String, dynamic>>;
    final messages = results[2] as List<MessageSearchHit>;
    final localChatIds = localChats.map((c) => c['id'] as int).toSet();
    final public = (results[3] as List<ChatSearchHit>)
        .where((c) => !localChatIds.contains(c.id))
        .toList();

    var meta = <int, Map<String, dynamic>>{};
    if (accountId != null && messages.isNotEmpty) {
      final ids = messages.map((m) => m.chatId).toSet().toList();
      final rows = await AppDatabase.loadChatsByIds(accountId, ids);
      meta = {for (final r in rows) r['id'] as int: r};
      if (!mounted || token != _seq) return;
    }

    setState(() {
      _phoneResult = results[4] as PhoneLookupResult?;
      _contacts = results[0] as List<Map<String, dynamic>>;
      _chats = localChats;
      _messages = messages;
      _msgChatMeta = meta;
      _public = public;
      _loading = false;
    });
  }

  ContactLabels _contactLabels(Map<String, dynamic> row) => contactLabels(
    idLabel: AppLocalizations.of(context)!.contactIdFallback('${row['id']}'),
    firstName: row['first_name'],
    lastName: row['last_name'],
    phone: row['phone'],
  );

  String _contactName(Map<String, dynamic> row) {
    final id = row['id'];
    if (id is int) {
      final cached = ContactCache.get(id);
      if (cached != null && cached.isNotEmpty) return cached;
    }
    return _contactLabels(row).title;
  }

  String _phoneResultName(PhoneLookupResult result) {
    return ContactCache.get(result.id) ??
        result.name ??
        AppLocalizations.of(context)!.userFallbackName(result.id);
  }

  ({String name, String? avatar, String type}) _chatIdentity(
    int chatId,
    String? type,
    String? title,
    String? iconUrl,
  ) {
    final fallbackType = type ?? 'CHAT';
    if (chatId == 0) {
      return (name: 'Избранное', avatar: iconUrl, type: fallbackType);
    }
    final me = _accountId ?? 0;
    final peer = me == 0 ? 0 : chatId ^ me;
    if ((type != null && type != 'DIALOG') || peer <= 0) {
      return (name: title ?? '', avatar: iconUrl, type: fallbackType);
    }
    final cachedName = ContactCache.get(peer);
    final cachedAvatar = ContactCache.getAvatar(peer);
    final known = cachedName != null && cachedName.isNotEmpty;
    return (
      name: known ? cachedName : (title ?? ''),
      avatar: (cachedAvatar != null && cachedAvatar.isNotEmpty)
          ? cachedAvatar
          : iconUrl,
      type: known ? 'DIALOG' : fallbackType,
    );
  }

  void _openChat(int chatId, String name, String? avatarUrl, String type) {
    pushSwipeable(
      context,
      (_) => ChatScreen(
        chatId: chatId,
        name: name,
        imageUrl: avatarUrl ?? '',
        chatType: type,
      ),
    );
  }

  void _openContact(Map<String, dynamic> row) {
    unawaited(
      openContactDialogProfile(
        context,
        contactId: row['id'] as int,
        name: _contactName(row),
        avatarUrl: row['base_url'] as String?,
      ),
    );
  }

  String? _phoneCandidate(String query) {
    if (!RegExp(r'^[+\d\s\-()]+$').hasMatch(query)) return null;
    final digits = query.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 5) return null;
    return query;
  }

  void _openPhoneResult(PhoneLookupResult result) {
    unawaited(
      openContactDialogProfile(
        context,
        contactId: result.id,
        name: _phoneResultName(result),
        avatarUrl: result.avatarUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final query = _controller.text.trim();
    final hasResults =
        _phoneResult != null ||
        _contacts.isNotEmpty ||
        _chats.isNotEmpty ||
        _messages.isNotEmpty ||
        _public.isNotEmpty;

    if (IosGlass.of(context)) return _buildIos(cs, query, hasResults);
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Symbols.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          style: TextStyle(color: cs.onSurface, fontSize: 16),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Поиск',
            hintStyle: TextStyle(color: cs.outline, fontSize: 16),
            border: InputBorder.none,
            isDense: true,
          ),
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: Icon(Symbols.close, color: cs.onSurfaceVariant),
              onPressed: _clear,
            ),
        ],
      ),
      body: _buildBody(cs, query, hasResults),
    );
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
    _focusNode.requestFocus();
  }

  Widget _buildIos(ColorScheme cs, String query, bool hasResults) {
    final secondary = IosPalette.secondaryLabel(cs);
    return Scaffold(
      backgroundColor: IosPalette.background(cs),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody(cs, query, hasResults)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: GlassCapsule(
                      key: const ValueKey('ios-search-capsule'),
                      height: IosMetrics.searchBarHeight,
                      padding: const EdgeInsets.only(left: 14, right: 4),
                      child: Row(
                        children: [
                          Icon(
                            IosSymbols.search(context),
                            size: 18,
                            color: secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              onChanged: _onChanged,
                              textInputAction: TextInputAction.search,
                              style: TextStyle(
                                color: IosPalette.label(cs),
                                fontSize: IosTypography.composer,
                                letterSpacing: IosTypography.letterSpacing(
                                  IosTypography.composer,
                                ),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Поиск',
                                hintStyle: TextStyle(
                                  color: secondary,
                                  fontSize: IosTypography.composer,
                                  letterSpacing: IosTypography.letterSpacing(
                                    IosTypography.composer,
                                  ),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (query.isNotEmpty)
                            IconButton(
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).deleteButtonTooltip,
                              icon: Icon(
                                IosSymbols.clearFill(context),
                                size: 20,
                                color: secondary,
                              ),
                              onPressed: _clear,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GlassIconButton(
                    key: const ValueKey('ios-search-close'),
                    icon: IosSymbols.close(context),
                    size: IosMetrics.minHitTarget,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs, String query, bool hasResults) {
    if (query.isEmpty) {
      return _buildHint(cs, IosSymbols.search(context), 'Начните вводить запрос');
    }
    if (!hasResults) {
      if (_loading) {
        return const Center(child: SmallSpinner(size: 36));
      }
      return _buildHint(cs, IosSymbols.searchOff(context), 'Ничего не найдено');
    }
    final phoneResult = _phoneResult;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (phoneResult != null) ...[
          _sectionHeader(cs, 'По номеру'),
          _ResultTile(
            name: _phoneResultName(phoneResult),
            imageUrl: phoneResult.avatarUrl,
            subtitle: query,
            onTap: () => _openPhoneResult(phoneResult),
          ),
        ],
        if (_contacts.isNotEmpty) ...[
          _sectionHeader(cs, 'Контакты'),
          for (final row in _contacts)
            _ResultTile(
              name: _contactName(row),
              imageUrl: row['base_url'] as String?,
              subtitle: _contactLabels(row).subtitle,
              onTap: () => _openContact(row),
            ),
        ],
        if (_chats.isNotEmpty) ...[
          _sectionHeader(cs, 'Чаты'),
          for (final row in _chats) _localChatTile(row),
        ],
        if (_messages.isNotEmpty) ...[
          _sectionHeader(cs, 'Сообщения'),
          for (final hit in _messages) _messageTile(hit),
        ],
        if (_public.isNotEmpty) ...[
          _sectionHeader(cs, 'Глобальный поиск'),
          for (final hit in _public) _chatTile(hit),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _chatTile(ChatSearchHit hit) => _ResultTile(
    name: hit.title ?? '',
    imageUrl: hit.avatarUrl,
    subtitle: hit.subtitle,
    onTap: () => _openChat(hit.id, hit.title ?? '', hit.avatarUrl, hit.type),
  );

  Widget _localChatTile(Map<String, dynamic> row) {
    final chatId = row['id'] as int;
    final identity = _chatIdentity(
      chatId,
      (row['type'] as String?) ?? 'CHAT',
      row['title'] as String?,
      row['icon_url'] as String?,
    );
    return _ResultTile(
      name: identity.name,
      imageUrl: identity.avatar,
      onTap: () =>
          _openChat(chatId, identity.name, identity.avatar, identity.type),
    );
  }

  Widget _messageTile(MessageSearchHit hit) {
    final meta = _msgChatMeta[hit.chatId];
    final identity = _chatIdentity(
      hit.chatId,
      meta?['type'] as String?,
      meta?['title'] as String?,
      meta?['icon_url'] as String?,
    );
    final name = identity.name.isEmpty ? 'Чат' : identity.name;
    return _ResultTile(
      name: name,
      imageUrl: identity.avatar,
      subtitle: hit.text?.trim(),
      onTap: () => _openChat(hit.chatId, name, identity.avatar, identity.type),
    );
  }

  Widget _sectionHeader(ColorScheme cs, String title) {
    final ios = IosGlass.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        ios ? IosTypography.sentenceCase(title) : title,
        style: TextStyle(
          color: ios ? IosPalette.secondaryLabel(cs) : cs.primary,
          fontSize: ios ? IosTypography.sectionHeader : 13,
          fontWeight: FontWeight.w600,
          letterSpacing: ios
              ? IosTypography.letterSpacing(IosTypography.sectionHeader)
              : null,
        ),
      ),
    );
  }

  Widget _buildHint(ColorScheme cs, IconData icon, String text) =>
      IosEmptyState(icon: icon, message: text);
}

class _ResultTile extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String? subtitle;
  final VoidCallback onTap;

  const _ResultTile({
    required this.name,
    required this.onTap,
    this.imageUrl,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ios = IosGlass.of(context);
    final sub = subtitle?.trim();
    return IosTappable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            KometAvatar(name: name, size: 48, imageUrl: imageUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name.isEmpty ? 'Без названия' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ios ? IosPalette.label(cs) : cs.onSurface,
                      fontSize: ios ? IosTypography.listTitle : 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: ios
                          ? IosTypography.letterSpacing(IosTypography.listTitle)
                          : null,
                    ),
                  ),
                  if (sub != null && sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ios
                            ? IosPalette.secondaryLabel(cs)
                            : cs.onSurfaceVariant,
                        fontSize: ios ? IosTypography.listSubtitle : 14,
                        letterSpacing: ios
                            ? IosTypography.letterSpacing(
                                IosTypography.listSubtitle,
                              )
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
