import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/config/debug_test.dart';
import '../../../core/contacts/contact_labels.dart';
import '../../../core/contacts/device_contacts_service.dart';
import '../../../core/protocol/opcode_map.dart';
import '../../../core/protocol/packet.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/token_storage.dart';
import '../../../backend/modules/contacts.dart';
import '../../../backend/modules/messages.dart' show ContactCache;
import '../../../main.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/contact_info.dart';
import '../../widgets/komet_avatar.dart';
import '../../widgets/connection_status.dart';
import '../../widgets/sheet_helpers.dart';
import '../../widgets/small_spinner.dart';
import '../../widgets/spectrum_tint.dart';
import '../chats/chat_info_screen.dart';
import 'nfc_exchange_sheet.dart';
import 'open_contact_profile.dart';
import '../../../core/config/app_frost.dart';
import '../../../core/config/app_fonts.dart';
import '../../widgets/glass/ios_glass.dart';
import '../../widgets/glass/ios_sheet.dart';
import '../../widgets/glass/ios_route.dart';
import '../../widgets/glass/ios_typography.dart';
import '../../widgets/glass/ios_palette.dart';
import '../../widgets/glass/ios_symbols.dart';
import '../../widgets/glass/ios_tappable.dart';
import '../../widgets/glass/ios_empty_state.dart';
import '../../widgets/glass/ios_metrics.dart';
import '../../widgets/glass/glass_controls.dart';
import '../../widgets/glass/ios_settings_scaffold.dart';
import '../../../core/native/native_list_bridge.dart';
import '../../native/native_list_view.dart';

enum _SearchMode { phone, id }

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> with SpectrumSurface {
  List<CachedContact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    ContactsModule.revision.addListener(_loadContacts);
    _loadDeviceContacts();
  }

  Future<void> _loadDeviceContacts() async {
    final changed = await DeviceContactsService.ensureLoadedInteractive();
    if (changed && mounted) setState(() {});
  }

  @override
  void dispose() {
    ContactsModule.revision.removeListener(_loadContacts);
    super.dispose();
  }

  Future<void> _openNfcExchange() async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: AppFrost.scrim(),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => const Align(
        alignment: Alignment.topCenter,
        child: NfcExchangeSheet(),
      ),
      transitionBuilder: (_, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  Future<void> _openSearchById() async {
    final cs = Theme.of(context).colorScheme;
    await showIosSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surfaceContainerHigh,
      shape: kSheetShape,
      builder: (_) => const _SearchContactSheet(),
    );
  }

  Future<void> _loadContacts() async {
    if (DebugTest.enabled) {
      final debug = ContactsModule.debugContacts()
        ..sort((a, b) => a.firstName.compareTo(b.firstName));
      if (mounted) {
        setState(() {
          _contacts = debug;
          _isLoading = false;
        });
      }
      return;
    }

    final p = await AppDatabase.loadActiveProfile();
    if (p == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final contacts = await ContactsModule.getContacts(p.id);
    contacts.sort((a, b) => a.firstName.compareTo(b.firstName));
    if (mounted) {
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    }
  }

  Widget _buildContactItem(
    BuildContext context,
    ColorScheme cs,
    CachedContact contact,
  ) {
    final ios = IosGlass.of(context);
    final text = _contactText(contact);
    final nameToDisplay = text.title;
    final subtitle = text.subtitle;

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: KometAvatar(
              name: nameToDisplay,
              imageUrl: contact.baseUrl,
              size: 48,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        nameToDisplay,
                        style: TextStyle(
                          color: ios ? IosPalette.label(cs) : cs.onSurface,
                          fontSize: ios ? IosTypography.listTitle : 16,
                          fontWeight: ios ? IosType.name : FontWeight.w600,
                          letterSpacing: ios
                              ? IosTypography.letterSpacing(
                                  IosTypography.listTitle,
                                )
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (contact.isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(
                        IosSymbols.verified(context),
                        color: cs.primary,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return IosTappable(
      onTap: () => openContactDialogProfile(
        context,
        contactId: contact.id,
        name: nameToDisplay,
        avatarUrl: contact.baseUrl,
      ),
      child: row,
    );
  }

  ({String title, String? subtitle}) _contactText(CachedContact contact) {
    final labels = contactLabels(
      idLabel: AppLocalizations.of(context)!.contactIdFallback('${contact.id}'),
      firstName: contact.firstName,
      lastName: contact.lastName,
      phone: contact.phone,
    );
    return (
      title: labels.title,
      subtitle: contact.updateTime > 0 ? 'Был(а) недавно' : labels.subtitle,
    );
  }

  static String _sectionLetter(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return '#';
    final letter = trimmed.characters.first.toUpperCase();
    return letter.toLowerCase() != letter ? letter : '#';
  }

  List<NativeListSection> _nativeSections() {
    final groups = <String, List<NativeListRow>>{};
    for (final contact in _contacts) {
      final text = _contactText(contact);
      groups
          .putIfAbsent(_sectionLetter(text.title), () => [])
          .add(
            NativeListRow(
              id: 'contact:${contact.id}',
              title: text.title,
              verified: contact.isVerified,
              subtitle: text.subtitle ?? '',
              avatarUrl: contact.baseUrl ?? '',
              avatarSeed: contact.id,
            ),
          );
    }
    final letters = groups.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });
    return [
      for (final letter in letters)
        NativeListSection(id: letter, title: letter, rows: groups[letter]!),
    ];
  }

  void _onNativeTap(String rowId) {
    final id = int.tryParse(rowId.substring('contact:'.length));
    if (id == null) return;
    for (final contact in _contacts) {
      if (contact.id != id) continue;
      openContactDialogProfile(
        context,
        contactId: contact.id,
        name: _contactText(contact).title,
        avatarUrl: contact.baseUrl,
      );
      return;
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
            'title': 'Контакты',
            'largeTitle': true,
            'search': 'Поиск',
            'index': true,
            'loading': _isLoading,
            'emptyText': 'Нет контактов',
            'buttons': const [
              {'id': 'find', 'symbol': 'person.badge.plus'},
            ],
            'accent': cs.primary.toARGB32(),
            'bottomInset': 100.0,
          },
          callbacks: NativeListCallbacks(
            onTap: _onNativeTap,
            onButton: (id, _) => unawaited(_openSearchById()),
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
    final ios = IosGlass.of(context);
    final bg = ios ? IosPalette.grouped(cs) : spectrumSurfaceColor(cs);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, ios ? 8 : 16, 12, ios ? 8 : 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Контакты',
                          style: TextStyle(
                            color: ios ? IosPalette.label(cs) : cs.onSurface,
                            fontSize: ios ? IosTypography.largeTitle : 24,
                            fontWeight: ios
                                ? IosType.largeTitle
                                : FontWeight.w700,
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
                  ContactsNfcExchangeButton(onPressed: _openNfcExchange),
                  if (!ios)
                    IconButton(
                      icon: Icon(IosSymbols.search(context), color: cs.onSurface),
                      onPressed: _openSearchById,
                    ),
                ],
              ),
            ),
            if (ios)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: IosFlatSearchBar(
                  hint: 'Поиск',
                  onTap: _openSearchById,
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: SmallSpinner(size: 36))
                  : _contacts.isEmpty
                  ? IosEmptyState(
                      icon: IosSymbols.personCropCircle(context),
                      message: 'Нет контактов',
                    )
                  : ListView.builder(
                      key: const PageStorageKey<String>('contacts-list'),
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        return _buildContactItem(context, cs, contact);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchContactSheet extends StatefulWidget {
  const _SearchContactSheet();

  @override
  State<_SearchContactSheet> createState() => _SearchContactSheetState();
}

class _SearchContactSheetState extends State<_SearchContactSheet> {
  final _controller = TextEditingController();
  _SearchMode _mode = _SearchMode.phone;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setMode(_SearchMode mode) {
    if (_mode == mode || _loading) return;
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_mode == _SearchMode.phone) {
      await _submitPhone();
    } else {
      await _submitId();
    }
  }

  String? _phoneCandidate(String query) {
    if (!RegExp(r'^[+\d\s\-()]+$').hasMatch(query)) return null;
    final digits = query.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 5) return null;
    return query;
  }

  Future<void> _submitPhone() async {
    final query = _phoneCandidate(_controller.text.trim());
    if (query == null) {
      setState(() => _error = 'Введите корректный номер телефона');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ContactsModule.findByPhone(api, query);
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _loading = false;
          _error = 'Контакт с таким номером не найден';
        });
        return;
      }
      final navigator = Navigator.of(context);
      final accountId = await TokenStorage.getActiveAccountId();
      final existing = accountId == null
          ? null
          : await AppDatabase.findDialogChatByParticipant(accountId, result.id);
      final chatId = existing ?? ((accountId ?? 0) ^ result.id);
      if (!mounted) return;
      navigator.pop();
      navigator.push(
        iosPageRoute(context,
          builder: (routeContext) => ChatInfoScreen(
            chatId: chatId,
            name:
                ContactCache.get(result.id) ??
                result.name ??
                AppLocalizations.of(routeContext)!.userFallbackName(result.id),
            imageUrl: result.avatarUrl ?? '',
            chatType: 'DIALOG',
            dialogPeerId: result.id,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Ошибка: $e';
        });
      }
    }
  }

  Future<void> _submitId() async {
    final raw = _controller.text.trim();
    final id = int.tryParse(raw);
    if (id == null) {
      setState(() => _error = 'Введите числовой ID');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final packet = await api.sendRequest(Opcode.contactInfo, {
        'contactIds': [id],
      });
      final contacts = (packet.payload as Map?)?['contacts'] as List?;
      if (contacts == null || contacts.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Контакт с таким ID не найден';
          });
        }
        return;
      }
      final raw = Map<String, dynamic>.from(contacts.first as Map);
      final info = ContactInfo.fromMap(raw);
      ContactsModule.primeContactCache(raw);
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final accountId = await TokenStorage.getActiveAccountId();
      final existing = accountId == null
          ? null
          : await AppDatabase.findDialogChatByParticipant(accountId, id);
      final chatId = existing ?? ((accountId ?? 0) ^ id);
      if (!mounted) return;
      navigator.pop();
      navigator.push(
        iosPageRoute(context,
          builder: (routeContext) => ChatInfoScreen(
            chatId: chatId,
            name:
                ContactCache.get(id) ??
                info.displayName ??
                AppLocalizations.of(routeContext)!.userFallbackName(id),
            imageUrl: info.avatarUrl ?? '',
            chatType: 'DIALOG',
            dialogPeerId: id,
          ),
        ),
      );
    } on PacketError catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Ошибка: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Найти контакт',
                      style: TextStyle(
                        color: IosGlass.of(context)
                            ? IosPalette.label(cs)
                            : cs.onSurface,
                        fontSize: IosGlass.of(context)
                            ? IosTypography.headerTitle
                            : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      IosSymbols.close(context),
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              IosSegmentedControl<_SearchMode>(
                groupValue: _mode,
                onValueChanged: (m) {
                  if (m != null) _setMode(m);
                },
                children: const {
                  _SearchMode.phone: Text('Номер'),
                  _SearchMode.id: Text('ID'),
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: _mode == _SearchMode.phone
                    ? TextInputType.phone
                    : TextInputType.number,
                enabled: !_loading,
                onSubmitted: (_) => _submit(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: IosGlass.of(context) ? IosTypography.body : 16,
                ),
                decoration: InputDecoration(
                  hintText: _mode == _SearchMode.phone
                      ? 'Введите номер телефона'
                      : 'Введите ID контакта',
                  hintStyle: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: IosGlass.of(context) ? IosTypography.body : 16,
                  ),
                  prefixIcon: Icon(
                    _mode == _SearchMode.phone
                        ? IosSymbols.phone(context)
                        : IosSymbols.number(context),
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        IosSymbols.error(context),
                        size: 18,
                        color: cs.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: cs.onErrorContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _loading
                  ? const SizedBox(
                      height: IosMetrics.minHitTarget,
                      child: Center(child: SmallSpinner(size: 20)),
                    )
                  : IosSettingsButton(
                      label: 'Найти',
                      onPressed: _submit,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactsNfcExchangeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ContactsNfcExchangeButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (IosGlass.of(context)) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      key: const ValueKey('contacts-nfc-exchange'),
      icon: Icon(IosSymbols.personAdd(context), color: cs.onSurface),
      onPressed: onPressed,
    );
  }
}
