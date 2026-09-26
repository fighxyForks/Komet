import 'package:flutter/material.dart';

import '../../../backend/modules/chats.dart';
import '../../../core/native/native_search_session.dart';
import '../../../core/storage/app_database.dart';
import '../../../main.dart';
import '../../native/native_search_view.dart';
import '../../widgets/swipe_route.dart';
import '../contacts/open_contact_profile.dart';
import 'chat_screen.dart';

class NativeSearchPage extends StatefulWidget {
  const NativeSearchPage({super.key});

  @override
  State<NativeSearchPage> createState() => _NativeSearchPageState();
}

class _NativeSearchPageState extends State<NativeSearchPage> {
  late final NativeSearchSession _session = NativeSearchSession(
    NativeSearchSources(
      accountId: () async => (await AppDatabase.loadActiveProfile())?.id,
      contacts: AppDatabase.searchContacts,
      chats: AppDatabase.searchChatsByTitle,
      publicChannels: (query, {required from, required count}) =>
          chats.searchPublic(api, query, from: from, count: count),
      serverMessages: (query) => chats.searchMessages(api, query),
      localMessages: AppDatabase.searchLocalMessages,
    ),
  );

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  Future<void> _open(String id) async {
    NativeSearchHit? hit;
    for (final item in _session.snapshot.hits) {
      if (item.id == id) hit = item;
    }
    final selected = hit;
    if (selected == null || !mounted) return;
    final target = selected.targetId;
    if (target == null) return;
    if (selected.kind == NativeSearchKind.contact) {
      await openContactDialogProfile(
        context,
        contactId: target,
        name: selected.title,
        avatarUrl: selected.avatarUrl.isEmpty ? null : selected.avatarUrl,
      );
      return;
    }
    if (!mounted) return;
    await pushSwipeable(
      context,
      (_) => ChatScreen(
          chatId: target,
          name: selected.kind == NativeSearchKind.message ? 'Чат' : selected.title,
          imageUrl: selected.avatarUrl,
          chatType: selected.type.isEmpty ? 'CHAT' : selected.type,
          initialMessageId: selected.messageId,
          initialMessageTime: selected.messageTime,
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _session,
        builder: (context, _) => NativeSearchView(
          hits: _session.snapshot.hits,
          onQuery: _session.setQuery,
          onClose: () => Navigator.of(context).pop(),
          onOpen: (id) => _open(id),
          onMore: _session.moreChannels,
        ),
      ),
    );
  }
}
