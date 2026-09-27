import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../backend/modules/contacts.dart';
import '../../../backend/modules/messages.dart' show ContactCache;
import '../../../core/protocol/opcode_map.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/token_storage.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/contact_info.dart';
import '../../../main.dart';
import '../../widgets/glass/ios_route.dart';
import '../../widgets/swipe_route.dart';
import '../chats/chat_info_screen.dart';
import 'open_contact_profile.dart';

class NativeContactLookupPage extends StatelessWidget {
  final bool scrim;
  final VoidCallback? onDismiss;

  const NativeContactLookupPage({super.key, this.scrim = false, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return _NativeContactCard(
      mode: 'lookup',
      scrim: scrim,
      onDismiss: onDismiss,
      onFind: (mode, query) => _lookup(context, mode, query, onDismiss),
    );
  }
}

class NativeAddContactPage extends StatelessWidget {
  const NativeAddContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _NativeContactCard(
      mode: 'add',
      onSave: (phone, first, last) => _save(context, phone, first, last),
    );
  }
}

class _NativeContactCard extends StatefulWidget {
  final String mode;
  final bool scrim;
  final VoidCallback? onDismiss;
  final Future<String?> Function(String mode, String query)? onFind;
  final Future<String?> Function(String phone, String first, String last)? onSave;

  const _NativeContactCard({
    required this.mode,
    this.scrim = false,
    this.onDismiss,
    this.onFind,
    this.onSave,
  });

  @override
  State<_NativeContactCard> createState() => _NativeContactCardState();
}

class _NativeContactCardState extends State<_NativeContactCard> {
  static const _type = 'ru.komet.app/native_contact_card';
  MethodChannel? _channel;

  Future<void> _status({String error = '', bool loading = false}) async {
    try {
      await _channel?.invokeMethod<void>('status', {
        'error': error,
        'loading': loading,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  void _created(int viewId) {
    final channel = MethodChannel('$_type/$viewId');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      final args = call.arguments is Map
          ? Map<String, Object?>.from(call.arguments as Map)
          : const <String, Object?>{};
      switch (call.method) {
        case 'close':
          final dismiss = widget.onDismiss;
          if (dismiss != null) {
            dismiss();
          } else if (mounted) {
            Navigator.of(context).pop();
          }
        case 'find':
          final error = await widget.onFind?.call(
            args['mode'] as String? ?? 'phone',
            args['query'] as String? ?? '',
          );
          if (mounted) await _status(error: error ?? '');
        case 'save':
          final error = await widget.onSave?.call(
            args['phone'] as String? ?? '',
            args['first'] as String? ?? '',
            args['last'] as String? ?? '',
          );
          if (mounted) await _status(error: error ?? '');
      }
      return null;
    });
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.mode == 'lookup'
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
      body: UiKitView(
        viewType: _type,
        creationParams: {'mode': widget.mode, 'scrim': widget.scrim},
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _created,
      ),
    );
  }
}

Future<String?> _lookup(
  BuildContext context,
  String mode,
  String query,
  VoidCallback? onDismiss,
) async {
  if (mode == 'id') {
    final id = int.tryParse(query.trim());
    if (id == null) return 'Введите числовой ID';
    try {
      final packet = await api.sendRequest(Opcode.contactInfo, {
        'contactIds': [id],
      });
      final contacts = (packet.payload as Map?)?['contacts'] as List?;
      if (contacts == null || contacts.isEmpty) return 'Не найдено';
      final raw = Map<String, dynamic>.from(contacts.first as Map);
      final info = ContactInfo.fromMap(raw);
      ContactsModule.primeContactCache(raw);
      if (!context.mounted) return null;
      await _openFound(
        context,
        id: id,
        name: ContactCache.get(id) ?? info.displayName,
        avatarUrl: info.avatarUrl,
        onDismiss: onDismiss,
      );
      return null;
    } catch (_) {
      return 'Не найдено';
    }
  }
  final digits = query.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 5) return 'Введите корректный номер телефона';
  final result = await ContactsModule.findByPhone(api, query);
  if (result == null) return 'Не найдено';
  if (!context.mounted) return null;
  await _openFound(
    context,
    id: result.id,
    name: ContactCache.get(result.id) ?? result.name,
    avatarUrl: result.avatarUrl,
    onDismiss: onDismiss,
  );
  return null;
}

/// Dim over the contacts list. Light theme stays in the 0.2–0.4 range.
Color contactLookupScrim(Brightness brightness) =>
    Colors.black.withValues(alpha: brightness == Brightness.dark ? 0.5 : 0.32);

Future<void> _openFound(
  BuildContext context, {
  required int id,
  required String? name,
  required String? avatarUrl,
  VoidCallback? onDismiss,
}) async {
  final navigator = Navigator.of(context);
  final accountId = await TokenStorage.getActiveAccountId();
  final existing = accountId == null
      ? null
      : await AppDatabase.findDialogChatByParticipant(accountId, id);
  final chatId = existing ?? ((accountId ?? 0) ^ id);
  if (!context.mounted) return;
  if (onDismiss != null) {
    onDismiss();
  } else {
    navigator.pop();
  }
  navigator.push(
    iosPageRoute(
      context,
      builder: (routeContext) => ChatInfoScreen(
        chatId: chatId,
        name: name ?? AppLocalizations.of(routeContext)!.userFallbackName(id),
        imageUrl: avatarUrl ?? '',
        chatType: 'DIALOG',
        dialogPeerId: id,
      ),
    ),
  );
}

Future<String?> _save(
  BuildContext context,
  String phone,
  String first,
  String last,
) async {
  if (first.trim().isEmpty) return 'Введите имя';
  final result = await ContactsModule.addContactByPhone(
    api,
    phone: phone,
    firstName: first.trim(),
    lastName: last.trim(),
  );
  if (!context.mounted) return null;
  switch (result.status) {
    case AddContactStatus.added:
      final contact = result.contact;
      Navigator.of(context).pop();
      if (contact != null && context.mounted) {
        final person = (contact.lastName != null && contact.lastName!.isNotEmpty)
            ? '${contact.firstName} ${contact.lastName}'
            : contact.firstName;
        await openContactDialogProfile(
          context,
          contactId: contact.id,
          name: person,
          avatarUrl: contact.baseUrl,
        );
      }
      return null;
    case AddContactStatus.notFound:
      return 'Не найдено';
    case AddContactStatus.error:
      return AppLocalizations.of(context)!.addContactError;
  }
}

Future<void> openNativeContactLookup(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Найти',
    barrierColor: contactLookupScrim(Theme.of(context).brightness),
    pageBuilder: (_, _, _) => const NativeContactLookupPage(),
  );
}

Future<void> openNativeAddContact(BuildContext context) {
  return pushSwipeable(context, (_) => const NativeAddContactPage());
}
