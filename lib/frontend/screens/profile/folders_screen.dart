import 'package:flutter/material.dart';

import '../../../backend/models/chat_folder.dart';
import '../../../backend/modules/folders.dart';
import '../../../core/storage/token_storage.dart';
import '../../widgets/glass/ios_settings_scaffold.dart';
import '../../widgets/glass/ios_symbols.dart';
import '../../widgets/section_header.dart';
import '../../widgets/settings_card.dart';
import '../chats/folder_action_sheet.dart';
import '../chats/folder_edit_sheet.dart';

typedef FoldersLoader = Future<List<ChatFolder>> Function();

Future<List<ChatFolder>> _loadActiveAccountFolders() async {
  final accountId = await TokenStorage.getActiveAccountId();
  if (accountId == null) return const [];
  return FoldersModule.loadFolders(accountId);
}

class FoldersScreen extends StatefulWidget {
  final FoldersLoader loader;

  const FoldersScreen({super.key, this.loader = _loadActiveAccountFolders});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<ChatFolder>? _folders;

  @override
  void initState() {
    super.initState();
    FoldersModule.revision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    FoldersModule.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final folders = await widget.loader();
    if (!mounted) return;
    setState(() {
      _folders = [
        for (final folder in folders)
          if (!FoldersModule.isAllChatsFolder(folder)) folder,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final folders = _folders;
    return IosSettingsScaffold(
      title: 'Папки',
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            SettingsCard(
              children: [
                SettingsNavTile(
                  key: const ValueKey('folders-create'),
                  icon: IosSymbols.createNewFolder(context),
                  label: 'Создать папку',
                  onTap: () => showFolderEditSheet(context),
                ),
              ],
            ),
            if (folders != null && folders.isNotEmpty) ...[
              const SizedBox(height: 20),
              const SectionHeader(
                'Мои папки',
                padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                fontSize: 14,
              ),
              SettingsCard(
                children: [
                  for (var i = 0; i < folders.length; i++)
                    SettingsNavTile(
                      key: ValueKey('folder-${folders[i].id}'),
                      icon: IosSymbols.folder(context),
                      leading: _emojiGlyph(folders[i]),
                      label: folders[i].title,
                      isLast: i == folders.length - 1,
                      onTap: () =>
                          showFolderActionSheet(context, folder: folders[i]),
                    ),
                ],
              ),
            ],
            const _Footer(
              'Папки делят чаты на группы: личные, рабочие, каналы. '
              'Переключаться между ними можно вкладками над списком чатов.',
            ),
          ],
        ),
      ),
    );
  }
}

Widget? _emojiGlyph(ChatFolder folder) {
  final emoji = folder.emoji;
  if (emoji == null || emoji.isEmpty) return null;
  return SizedBox(
    width: 30,
    height: 30,
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
  );
}

class _Footer extends StatelessWidget {
  final String text;

  const _Footer(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Text(
        text,
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
      ),
    );
  }
}
