import 'package:flutter/material.dart';
import '../../widgets/glass/ios_settings_scaffold.dart';
import 'package:komet/frontend/widgets/glass/ios_symbols.dart';

import '../../../core/config/build_profile.dart';
import '../../../core/config/komet_settings.dart';
import '../../../core/plugins/plugin_availability.dart';
import '../../../main.dart';
import '../../widgets/section_header.dart';
import '../../widgets/settings_card.dart';
import 'plugins_screen.dart';
import '../../widgets/glass/ios_route.dart';

class KometSettingsScreen extends StatelessWidget {
  const KometSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IosSettingsScaffold(
      title: 'Komet',
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            const SectionHeader(
              'Сообщения',
              padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              fontSize: 14,
            ),
            SettingsCard(
              children: [
                if (kPluginsCompiled)
                  SettingsNavTile(
                    icon: IosSymbols.extension(context),
                    label: 'Плагины',
                    onTap: () => Navigator.push(
                      context,
                      iosPageRoute(
                        context,
                        builder: (_) => const PluginsScreen(),
                      ),
                    ),
                  ),
                if (BuildProfile.hiddenContentViewers) ...[
                  ValueListenableBuilder<bool>(
                    valueListenable: KometSettings.viewDeleted,
                    builder: (context, value, _) => SettingsToggleTile(
                      icon: IosSymbols.deleteHistory(context),
                      label: 'View deleted message',
                      subtitle: 'Показывать удалённые сообщения',
                      value: value,
                      onChanged: KometSettings.setViewDeleted,
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: KometSettings.viewRedacted,
                    builder: (context, value, _) => SettingsToggleTile(
                      icon: IosSymbols.historyEdu(context),
                      label: 'View redacted message history',
                      subtitle:
                          'Показывать историю у редактированных сообщений',
                      value: value,
                      onChanged: KometSettings.setViewRedacted,
                    ),
                  ),
                ],
                ValueListenableBuilder<bool>(
                  valueListenable: KometSettings.fullTimestamp,
                  builder: (context, value, _) => SettingsToggleTile(
                    icon: IosSymbols.schedule(context),
                    label: 'View full timestamp',
                    subtitle: 'Показывать время в секундах у сообщений',
                    value: value,
                    onChanged: KometSettings.setFullTimestamp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SectionHeader(
              'Папки',
              padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              fontSize: 14,
            ),
            SettingsCard(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: KometSettings.hideAllChatsFolder,
                  builder: (context, value, _) => SettingsToggleTile(
                    icon: IosSymbols.folderOff(context),
                    label: 'Hide "All" folder',
                    subtitle:
                        'Скрыть папку «Все», когда есть другие папки. '
                        'Чаты сортируются только по вашим папкам',
                    value: value,
                    onChanged: KometSettings.setHideAllChatsFolder,
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: KometSettings.showHiddenChats,
                  builder: (context, value, _) => SettingsToggleTile(
                    icon: IosSymbols.visibilityLock(context),
                    label: 'Show hidden chats',
                    subtitle:
                        'Показывать скрытые чаты, которые обычно не '
                        'отображаются в списке: от групповых звонков, '
                        'закрытые каналы и покинутые чаты',
                    value: value,
                    onChanged: KometSettings.setShowHiddenChats,
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: KometSettings.archiveOnPull,
                  builder: (context, value, _) => SettingsToggleTile(
                    icon: IosSymbols.archive(context),
                    label: 'Pull-down archive',
                    subtitle:
                        'Прятать архив и показывать его, если потянуть '
                        'список чатов вниз, после историй',
                    value: value,
                    onChanged: KometSettings.setArchiveOnPull,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SectionHeader(
              'Ghost Mode',
              padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              fontSize: 14,
            ),
            SettingsCard(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: KometSettings.ghostMode,
                  builder: (context, value, _) => SettingsToggleTile(
                    icon: IosSymbols.visibilityOff(context),
                    label: 'Ghost Mode',
                    subtitle: 'Вас не видно в сети',
                    value: value,
                    onChanged: _setGhostMode,
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: KometSettings.antiRead,
                  builder: (context, value, _) => SettingsToggleTile(
                    icon: IosSymbols.markChatRead(context),
                    label: 'Anti read',
                    subtitle: 'Нечиталка сообщений',
                    value: value,
                    onChanged: KometSettings.setAntiRead,
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: KometSettings.selfOnlineCheck,
                  builder: (context, value, _) => SettingsToggleTile(
                    icon: IosSymbols.radar(context),
                    label: 'Self Online Check',
                    subtitle:
                        'Каждые ~10 секунд сверяет, когда вы были онлайн. '
                        'Полезно для проверки ghost mode',
                    value: value,
                    onChanged: KometSettings.setSelfOnlineCheck,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SectionHeader(
              'Отладка',
              padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              fontSize: 14,
            ),
            SettingsCard(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: KometSettings.recordDebugLogs,
                  builder: (context, value, _) => SettingsToggleTile(
                    icon: IosSymbols.bugReport(context),
                    label: 'Запись отладочных логов',
                    subtitle:
                        'Пишет трафик протокола в файл на устройстве — '
                        'помогает диагностировать баги при репортах',
                    value: value,
                    onChanged: KometSettings.setRecordDebugLogs,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setGhostMode(bool value) async {
    await KometSettings.setGhostMode(value);
    api.sendPing(interactive: !value);
  }
}
