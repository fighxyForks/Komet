import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import '../../widgets/glass/ios_typography.dart';
import '../../widgets/glass/ios_palette.dart';
import '../../widgets/glass/ios_glass.dart';
import '../../widgets/glass/ios_alert.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../../motion/ios_haptics.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/cache/self_presence.dart';
import '../../../core/config/build_profile.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/config/komet_settings.dart';
import '../../../core/config/app_show_extra_info.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/update_checker.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../backend/modules/contacts.dart';
import '../../widgets/animated_slash_icon.dart';
import 'media_devices_screen.dart';
import '../../widgets/avatar_history_screen.dart';
import '../../widgets/avatar_photo_actions.dart';
import '../../widgets/connection_status.dart';
import '../../widgets/glossy_pill.dart';
import '../../widgets/info_action_sheet.dart';
import '../../widgets/komet_avatar.dart';
import '../../widgets/profile_header_scroll.dart';
import '../../widgets/settings_card.dart';
import '../../widgets/sheet_helpers.dart';
import '../../widgets/small_spinner.dart';
import '../../widgets/custom_notification.dart';
import '../../widgets/update_dialog.dart';
import '../../native/native_menu_button.dart';
import '../../widgets/swipe_route.dart';
import '../chats/chat_list_screen.dart' show ChatListScreen, activeNavTab;
import '../chats/chat_screen.dart';
import 'account_switching.dart';
import 'folders_screen.dart';
import '../auth/login_screen.dart';
import '../auth/proxy_settings_sheet.dart';
import '../../../core/config/app_digital_id_mode.dart';
import '../../../core/utils/webview_support.dart';
import '../digital_id/digital_id_screen.dart';
import '../digital_id/digital_id_web_screen.dart';
import '../webapp/web_app_bridge.dart';
import '../webapp/web_app_screen.dart';
import 'avatar_carousel.dart';
import 'cloud_storage_screen.dart';
import 'customization_section.dart';
import 'debug_menu_screen.dart';
import 'devices_screen.dart';
import '../../widgets/spectrum_tint.dart';
import 'edit_profile_screen.dart';
import 'info_screen.dart';
import 'komet_settings_screen.dart';
import 'notifications_screen.dart';
import 'profile_qr_sheet.dart';
import 'security_screen.dart';
import 'spoof_screen.dart';
import '../../native/native_settings_view.dart';
import '../../widgets/media_playback_pill.dart';
import 'app_icon_screen.dart';
import 'appearance_screen.dart';
import 'chat_background_screen.dart';
import 'font_settings_screen.dart';
import 'message_actions_screen.dart';
import 'theme_settings_screen.dart';
import '../../../core/config/app_fonts.dart';
import '../../widgets/glass/ios_sheet.dart';
import '../../widgets/glass/ios_route.dart';
import '../../widgets/glass/ios_symbols.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

const int _settingsTabIndex = 3;
const double _headerVignette = 64;
const int _avatarHistoryPageSize = 50;

class _SettingsTabState extends State<SettingsTab> with SpectrumSurface {
  ProfileData? _profile;
  List<ProfileData> _accounts = const [];
  List<String> _avatarUrls = const [];
  List<int?> _avatarIds = const [];
  List<AvatarPhoto> _avatarPhotos = const [];
  int _avatarIndex = 0;
  bool _avatarForward = true;
  final GlobalKey _avatarMenuKey = GlobalKey();
  final GlobalKey _accountRowKey = GlobalKey();
  bool _isPhoneVisible = false;
  ScrollController? _scrollController;
  double _headerDelta = 0;
  bool _headerEverExpanded = false;
  bool _expandArmed = false;
  bool _headerDragging = false;
  bool _zoneHapticFired = false;
  bool _pastCommitPoint = false;
  String? _appVersionLabel;
  bool _debugMenuVisible = false;
  bool _isCheckingForUpdates = false;
  bool _hapticsEnabled = Haptics.enabled;
  int _versionSecretTapCount = 0;
  Timer? _versionSecretTapResetTimer;
  StreamSubscription? _profileUpdateSub;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadAccounts();
    _loadAppVersion();
    final appState = KometApp.stateOf(context);
    if (appState != null) {
      _profileUpdateSub = appState.profileUpdateStream.listen((_) {
        if (mounted) _loadProfile();
      });
    }
    activeNavTab.addListener(_onNavTabChanged);
  }

  // #***! вкладку не размонтируют, поэтому при открытии сами возвращаемся
  // к шапке: иначе настройки открываются там же, где их закрыли
  void _onNavTabChanged() {
    if (!mounted || activeNavTab.value != _settingsTabIndex) return;
    _resetHeaderScroll();
  }

  void _resetHeaderScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _scrollController;
      if (!mounted || c == null || !c.hasClients) return;
      final target = math.min(_headerDelta, c.position.maxScrollExtent);
      if ((c.offset - target).abs() < 1) return;
      c.jumpTo(target);
    });
  }

  @override
  void dispose() {
    _versionSecretTapResetTimer?.cancel();
    activeNavTab.removeListener(_onNavTabChanged);
    _profileUpdateSub?.cancel();
    _scrollController?.dispose();
    super.dispose();
  }

  void _syncHeaderDelta(double delta) {
    if (_scrollController == null) {
      _scrollController = ScrollController(initialScrollOffset: delta);
      _headerDelta = delta;
      return;
    }
    if (_headerDelta == delta) return;
    final prev = _headerDelta;
    _headerDelta = delta;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _scrollController;
      if (!mounted || c == null || !c.hasClients) return;
      final target = (c.offset + (delta - prev)).clamp(
        0.0,
        c.position.maxScrollExtent,
      );
      c.jumpTo(target);
    });
  }

  bool _handleScrollNotification(ScrollNotification n, double delta) {
    if (n.depth != 0) return false;
    if (n is ScrollStartNotification) {
      _headerDragging = n.dragDetails != null;
      if (n.dragDetails != null) {
        final px = n.metrics.pixels;
        _expandArmed = delta > 0 && px <= delta + 8;
        _zoneHapticFired = px < delta;
        _pastCommitPoint = px < delta / 2;
      }
    } else if (n is ScrollUpdateNotification) {
      if (n.dragDetails != null && delta > 0) {
        final px = n.metrics.pixels;
        if (px < delta) {
          if (!_zoneHapticFired) {
            _zoneHapticFired = true;
            if (IosGlass.of(context)) {
              IosHaptics.selectionChange();
            } else {
              HapticFeedback.lightImpact();
            }
          }
        } else {
          _zoneHapticFired = false;
        }
        final pastCommit = px < delta / 2;
        if (pastCommit != _pastCommitPoint) {
          _pastCommitPoint = pastCommit;
          if (IosGlass.of(context)) {
            IosHaptics.warning();
          } else {
            HapticFeedback.mediumImpact();
          }
        }
      }
    } else if (n is ScrollEndNotification) {
      if (_headerDragging) {
        _headerDragging = false;
        _snapHeader(delta);
      }
    }
    return false;
  }

  void _snapHeader(double delta) {
    final c = _scrollController;
    if (c == null || !c.hasClients || delta <= 0) return;
    final collapsed = math.min(delta, c.position.maxScrollExtent);
    final offset = c.offset;
    if (offset <= 0 || offset >= collapsed) return;
    final target = offset < collapsed / 2 ? 0.0 : collapsed;
    if ((target - offset).abs() < 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !c.hasClients) return;
      c.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _scheduleVersionSecretTapReset() {
    _versionSecretTapResetTimer?.cancel();
    _versionSecretTapResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _versionSecretTapCount = 0);
    });
  }

  void _onVersionLabelTap() {
    if (!BuildProfile.devTools) return;
    _scheduleVersionSecretTapReset();
    setState(() {
      _versionSecretTapCount++;
      if (_versionSecretTapCount >= 7) {
        _versionSecretTapCount = 0;
        _versionSecretTapResetTimer?.cancel();
        _debugMenuVisible = !_debugMenuVisible;
      }
    });
  }

  Future<void> _loadAccounts() async {
    final accounts = await accountModule.listAccounts();
    if (!mounted) return;
    setState(() => _accounts = accounts);
  }

  Future<void> _loadProfile() async {
    final p = await AppDatabase.loadActiveProfile();
    if (!mounted) return;
    // #***! фото могли сменить с другого устройства, тогда список истории
    // в кэше уже неверен и его надо перечитать
    if (p != null && p.photoId != _profile?.photoId) {
      ContactsModule.invalidatePhotos(p.id);
    }
    setState(() {
      _profile = p;
      _rebuildAvatarPhotos();
    });
    await _loadAvatars();
  }

  // #***! список фото нужен вместе с id, а кэшу модуля можно верить:
  // он сам сбрасывается при загрузке и удалении аватарки
  Future<void> _loadAvatars() async {
    final profile = _profile;
    if (profile == null || profile.id <= 0) return;
    final photos =
        ContactsModule.cachedPhotos(profile.id) ??
        await ContactsModule.fetchPhotos(
          api,
          profile.id,
          count: _avatarHistoryPageSize,
        );
    if (!mounted) return;
    final ids = List<int?>.generate(photos.urls.length, (i) => photos.idAt(i));
    if (listEquals(_avatarUrls, photos.urls) && listEquals(_avatarIds, ids)) {
      return;
    }
    setState(() {
      _avatarUrls = photos.urls;
      _avatarIds = ids;
      _rebuildAvatarPhotos();
    });
  }

  // #***! готовый список держим полем: шапка перестраивается на каждом кадре
  // прокрутки, собирать его в build значило бы мусорить каждый кадр
  void _rebuildAvatarPhotos() {
    _avatarPhotos = buildAvatarPhotos(
      urls: _avatarUrls,
      ids: _avatarIds,
      baseUrl: _profile?.baseUrl,
      mainPhotoId: _profile?.photoId,
    );
    _avatarIndex = indexOfMainAvatar(_avatarPhotos, _profile?.photoId);
  }

  int get _fullAvatarCacheWidth {
    final width = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (width * dpr).round().clamp(264, 2048);
  }

  AvatarPhoto? get _currentAvatar {
    if (_avatarPhotos.isEmpty) return null;
    return _avatarPhotos[_avatarIndex
        .clamp(0, _avatarPhotos.length - 1)
        .toInt()];
  }

  void _stepAvatar(int delta) {
    final next = _avatarIndex + delta;
    if (next < 0 || next >= _avatarPhotos.length) return;
    setState(() {
      _avatarForward = delta > 0;
      _avatarIndex = next;
    });
  }

  void _onAvatarSwipe(DragEndDetails details) {
    final vx = details.primaryVelocity ?? 0;
    if (vx.abs() < 120) return;
    _stepAvatar(vx < 0 ? 1 : -1);
  }

  String get _fullName {
    final profile = _profile;
    if (profile == null) return '';
    final last = profile.lastName;
    return last == null || last.isEmpty
        ? profile.firstName
        : '${profile.firstName} $last';
  }

  Future<void> _openAvatarViewer() async {
    final profile = _profile;
    final current = _currentAvatar;
    if (profile == null || current == null) return;
    final updated = await AvatarHistoryScreen.open(
      context,
      contactId: profile.id,
      name: _fullName,
      currentAvatarUrl: profile.baseUrl,
      initialUrl: current.url,
      initialPhotoId: current.id,
      mainPhotoId: profile.photoId,
      allowDelete: true,
    );
    if (updated != null && mounted) await _applyProfileAfterDeletion(updated);
  }

  void _openAvatarMenu() {
    final rect = anchorRectOf(_avatarMenuKey);
    final current = _currentAvatar;
    if (rect == null || current == null) return;
    final id = current.id;
    showAvatarMenu(
      context: context,
      anchorRect: rect,
      onSave: () => saveAvatarPhoto(context, current.url),
      onDelete: id == null ? null : () => _deleteAvatar(id),
    );
  }

  Future<void> _deleteAvatar(int id) async {
    if (!await confirmAvatarDeletion(context)) return;
    if (!mounted) return;
    try {
      final profile = await accountModule.removeProfilePhoto(id);
      if (!mounted) return;
      await _applyProfileAfterDeletion(profile);
      if (mounted) showCustomNotification(context, 'Фото удалено');
    } catch (e) {
      if (mounted)
        showCustomNotification(context, 'Не удалось удалить фото: $e');
    }
  }

  // #***! сервер сам назначает новую основную, к ней и перелистываем.
  // Старый список уже неверен: удалённое фото в нём ещё есть, и показывать его
  // нельзя — до перезагрузки списка живём одной аватаркой из свежего профиля
  Future<void> _applyProfileAfterDeletion(ProfileData profile) async {
    setState(() {
      _profile = profile;
      _avatarUrls = const [];
      _avatarIds = const [];
      _avatarForward = false;
      _rebuildAvatarPhotos();
    });
    await _loadAvatars();
    if (mounted) KometApp.stateOf(context)?.notifyProfileUpdate();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersionLabel = 'Версия ${info.version} (${info.buildNumber})';
    });
  }

  void _openNotifications() {
    Navigator.push(
      context,
      iosPageRoute(context, builder: (context) => const NotificationsScreen()),
    ).then((_) {
      if (!mounted) return;
      setState(() => _hapticsEnabled = Haptics.enabled);
    });
  }

  Future<void> _setHaptics(bool value) async {
    await Haptics.setEnabled(value);
    if (!mounted) return;
    setState(() => _hapticsEnabled = value);
    if (!value) return;
    if (IosGlass.of(context)) {
      IosHaptics.success();
    } else {
      Haptics.success();
    }
  }

  Future<void> _checkForUpdates() async {
    if (!BuildProfile.selfUpdate || _isCheckingForUpdates) return;
    setState(() => _isCheckingForUpdates = true);

    final result = await UpdateChecker.checkNow();
    if (!mounted) return;
    setState(() => _isCheckingForUpdates = false);

    switch (result.status) {
      case UpdateCheckStatus.updateAvailable:
        await showUpdateDialog(context, result.update!);
        return;
      case UpdateCheckStatus.upToDate:
        showCustomNotification(
          context,
          AppLocalizations.of(context)!.updateUpToDate,
        );
        return;
      case UpdateCheckStatus.failed:
        showCustomNotification(
          context,
          AppLocalizations.of(context)!.updateCheckFailed,
        );
        return;
    }
  }

  Future<void> _openCloudStorage(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final ok = await showInfoActionSheet(
      context,
      headerIcon: Symbols.cloud,
      title: 'Облачное хранилище',
      subtitle: 'Через МАХ',
      items: [
        const InfoActionSheetItem(
          icon: Symbols.cloud_done,
          title: 'Работает при белых списках',
          body: 'Вы сможете передать файл даже при ограниченном интернете.',
        ),
        const InfoActionSheetItem(
          icon: Symbols.inventory_2,
          title: 'Файлы до 4ГБ, безлимитное количество.',
          body: 'Можете хранить массивный обьем информации.',
        ),
        InfoActionSheetItem(
          icon: Symbols.gpp_maybe,
          title: 'Не обеспечивается конфединциальность файлов',
          body:
              'Облачное хранилище работает через ваш аккаунт на сервере МАХ, '
              'нужные люди всё равно могут его посмотреть.',
          titleColor: cs.error,
        ),
      ],
      confirmLabel: 'ОК',
      confirmDelay: const Duration(seconds: 3),
      seenKey: 'cloud_storage_intro_seen',
    );
    if (!ok || !context.mounted) return;
    await Navigator.push(
      context,
      iosPageRoute(context, builder: (_) => const CloudStorageScreen()),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showIosAlert<bool>(
      context: context,
      title: 'Выйти из аккаунта?',
      message: 'Данные аккаунта будут удалены с этого устройства.',
      actions: const [
        IosAlertAction(
          id: 'cancel',
          label: 'Отмена',
          result: false,
          isCancel: true,
        ),
        IosAlertAction(
          id: 'logout',
          label: 'Выйти',
          result: true,
          isDestructive: true,
        ),
      ],
    );
    if (confirmed != true || !mounted) return;
    await _doLogout();
  }

  Future<void> _doLogout() async {
    final navState = KometApp.navigatorKey.currentState;
    try {
      await accountModule.logout();
    } catch (e) {
      if (mounted) showCustomNotification(context, 'Не удалось выйти: $e');
      return;
    }
    await resetDigitalIdSession();
    try {
      // #***! вышли из аккаунта — дальше экран входа по телефону, прошлая версия
      await api.connect(authenticated: false);
    } catch (_) {}
    if (!mounted || navState == null || !navState.mounted) return;
    await navState.pushAndRemoveUntil(
      iosPageRoute(context, builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (_profile == null) {
      return const Center(child: SmallSpinner(size: 36));
    }

    final String fullName =
        '${_profile!.firstName}${_profile!.lastName != null ? ' ${_profile!.lastName}' : ''}';
    final String phone = _profile!.phone == 0
        ? l10n.profilePhoneRegenFailed
        : '+${_profile!.phone}';

    final size = MediaQuery.sizeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final hasPhoto = (_profile!.baseUrl ?? '').isNotEmpty;

    return ValueListenableBuilder<bool>(
      valueListenable: KometSettings.selfOnlineCheck,
      builder: (context, statusEnabled, _) {
        if (IosGlass.of(context)) {
          return ListenableBuilder(
            listenable: Listenable.merge([
              SelfPresence.isOnline,
              SelfPresence.lastSeenSeconds,
              AppShowExtraInfo.current,
            ]),
            builder: (context, _) =>
                _nativeSettingsScaffold(context, cs, l10n, fullName, phone),
          );
        }
        final collapsedH = topPad + (statusEnabled ? 268.0 : 242.0);
        final expandedH = hasPhoto
            ? math.max(collapsedH, math.min(size.width, size.height * 0.65))
            : collapsedH;
        final delta = expandedH - collapsedH;
        _syncHeaderDelta(delta);
        return Scaffold(
          backgroundColor: IosGlass.of(context)
              ? IosPalette.grouped(cs)
              : spectrumSurfaceColor(cs),
          body: NotificationListener<ScrollNotification>(
            onNotification: (n) => _handleScrollNotification(n, delta),
            child: CustomScrollView(
              key: ValueKey(delta),
              controller: _scrollController ??= ScrollController(
                initialScrollOffset: delta,
              ),
              physics: HeaderPullScrollPhysics(
                delta: delta,
                isArmed: () => _expandArmed,
                parent: const BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPersistentHeader(
                  delegate: MorphHeaderDelegate(
                    collapsedExtent: collapsedH,
                    expandedExtent: expandedH,
                    headerBuilder: (ctx, t) =>
                        _buildHeader(ctx, cs, fullName, phone, t),
                  ),
                ),
                SliverToBoxAdapter(child: _buildBioCard(cs, l10n)),
                const SliverToBoxAdapter(
                  child: MediaPlaybackPill(
                    margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: AppShowExtraInfo.current,
                      builder: (context, showExtraInfo, _) {
                        return _buildSection(
                          context,
                          items: [
                            if (BuildProfile.digitalId)
                              _SettingsItem(
                                icon: Symbols.badge,
                                label: 'Цифровой ID',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    iosPageRoute(
                                      context,
                                      builder: (context) =>
                                          AppDigitalIdNative.current.value ||
                                              !webViewSupported
                                          ? const DigitalIdScreen()
                                          : const DigitalIdWebScreen(),
                                    ),
                                  );
                                },
                              ),
                            _SettingsItem(
                              icon: Symbols.language,
                              label: 'Войти в Сферум',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  iosPageRoute(
                                    context,
                                    builder: (context) => WebAppScreen(
                                      title: 'Сферум',
                                      entryPoint: WebAppEntryPoint.settings,
                                      loader: () => webAppModule.fetchSferum(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            _SettingsItem(
                              icon: Symbols.bookmark,
                              label: 'Избранное',
                              onTap: _openSavedMessages,
                            ),
                            _accountItem(context),
                            if (showExtraInfo)
                              _SettingsItem(
                                icon: Symbols.info,
                                label: AppLocalizations.of(context)!.infoTitle,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    iosPageRoute(
                                      context,
                                      builder: (context) => const InfoScreen(),
                                    ),
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: CustomizationSection(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildSection(
                      context,
                      items: [
                        _SettingsItem(
                          icon: Symbols.folder,
                          label: 'Папки',
                          onTap: () => Navigator.push(
                            context,
                            iosPageRoute(
                              context,
                              builder: (context) => const FoldersScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildSection(
                      context,
                      items: [
                        _SettingsItem(
                          icon: Symbols.vibration,
                          label: 'Тактильный отклик',
                          subtitle: 'Виброотклик при действиях в приложении',
                          toggleValue: _hapticsEnabled,
                          onToggle: (value) => unawaited(_setHaptics(value)),
                        ),
                        _SettingsItem(
                          icon: Symbols.notifications_active,
                          label: 'Уведомления',
                          onTap: _openNotifications,
                        ),
                        _SettingsItem(
                          icon: Symbols.videocam,
                          label: 'Камера и микрофон',
                          onTap: () {
                            Navigator.push(
                              context,
                              iosPageRoute(
                                context,
                                builder: (context) =>
                                    const MediaDevicesScreen(),
                              ),
                            );
                          },
                        ),
                        _SettingsItem(
                          icon: Symbols.cloud,
                          label: 'Облачное хранилище [BETA]',
                          onTap: () => _openCloudStorage(context),
                        ),
                        _SettingsItem(
                          icon: Symbols.vpn_lock,
                          label: 'Прокси',
                          onTap: () {
                            final cs = Theme.of(context).colorScheme;
                            showIosSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: cs.surfaceContainerHigh,
                              shape: kSheetShape,
                              builder: (_) {
                                return SafeArea(
                                  child: const ProxySettingsSheet(),
                                );
                              },
                            );
                          },
                        ),
                        if (BuildProfile.spoofUi)
                          _SettingsItem(
                            icon: Symbols.shield_lock,
                            label: AppLocalizations.of(
                              context,
                            )!.profileMenuSpoof,
                            onTap: () {
                              Navigator.push(
                                context,
                                iosPageRoute(
                                  context,
                                  builder: (context) => const SpoofScreen(),
                                ),
                              );
                            },
                          ),
                        _SettingsItem(
                          icon: Symbols.lock,
                          label: 'Безопасность',
                          onTap: () {
                            Navigator.push(
                              context,
                              iosPageRoute(
                                context,
                                settings: const RouteSettings(
                                  name: 'SecurityScreen',
                                ),
                                builder: (context) => const SecurityScreen(),
                              ),
                            );
                          },
                        ),
                        _SettingsItem(
                          icon: Symbols.devices,
                          label: 'Устройства',
                          onTap: () {
                            Navigator.push(
                              context,
                              iosPageRoute(
                                context,
                                builder: (context) => const DevicesScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 340),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: animation.value.clamp(0.0, 1.0),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                      );
                    },
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        clipBehavior: Clip.none,
                        children: <Widget>[...previousChildren, ?currentChild],
                      );
                    },
                    child: _debugMenuVisible
                        ? KeyedSubtree(
                            key: const ValueKey('developers_settings_row'),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: _buildSection(
                                context,
                                items: [
                                  _SettingsItem(
                                    icon: Symbols.construction,
                                    label: 'Для разработчиков',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        iosPageRoute(
                                          context,
                                          builder: (context) =>
                                              const DebugMenuScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('developers_settings_hidden'),
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildSection(
                      context,
                      items: [
                        if (BuildProfile.selfUpdate)
                          _SettingsItem(
                            icon: Symbols.system_update,
                            label: _isCheckingForUpdates
                                ? l10n.updateChecking
                                : l10n.updateCheck,
                            onTap: _isCheckingForUpdates
                                ? null
                                : _checkForUpdates,
                          ),
                        _SettingsItem(
                          leading: Image.asset(
                            'assets/komet.png',
                            width: 22,
                            height: 22,
                            color: cs.onSurfaceVariant,
                          ),
                          label: 'Komet',
                          onTap: () {
                            Navigator.push(
                              context,
                              iosPageRoute(
                                context,
                                builder: (context) =>
                                    const KometSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _SettingsItem(
                          icon: Symbols.logout,
                          label: 'Выйти из аккаунта',
                          tintColor: cs.error,
                          onTap: _confirmLogout,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_appVersionLabel != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                      child: Center(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _onVersionLabelTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            child: Text(
                              _appVersionLabel!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.75,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _nativeSettingsScaffold(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    String name,
    String phone,
  ) {
    final online =
        KometSettings.selfOnlineCheck.value && SelfPresence.isOnline.value;
    final seen = SelfPresence.lastSeenSeconds.value;
    final status = !KometSettings.selfOnlineCheck.value
        ? ''
        : online
        ? 'онлайн'
        : (seen != null ? 'Был(-а) ${_formatSelfSeen(seen)}' : 'офлайн');
    final others = [
      for (final account in _accounts)
        if (account.id != _profile?.id) account,
    ];
    return Scaffold(
      backgroundColor: IosPalette.grouped(cs),
      body: Column(
        children: [
          const MediaPlaybackPill(margin: EdgeInsets.fromLTRB(16, 8, 16, 0)),
          Expanded(
            child: NativeSettingsView(
              name: name,
              status: status,
              online: online,
              phone: phone,
              bio: _profile?.description ?? '',
              avatarUrl: _profile?.baseUrl ?? '',
              canEditAvatar: _currentAvatar != null,
              version: _appVersionLabel ?? '',
              topInset: MediaQuery.paddingOf(context).top,
              sections: _nativeSettingsSections(context, l10n, others),
              onTap: (id) => _onNativeSettingsTap(context, id),
              onToggle: (id, value) {
                if (id == 'haptics') unawaited(_setHaptics(value));
              },
              onHeader: _onNativeSettingsHeader,
            ),
          ),
        ],
      ),
    );
  }

  List<List<NativeSettingsRow>> _nativeSettingsSections(
    BuildContext context,
    AppLocalizations l10n,
    List<ProfileData> others,
  ) {
    final showExtra = AppShowExtraInfo.current.value;
    final account = others.isEmpty
        ? const NativeSettingsRow(
            id: 'account',
            title: 'Добавить профиль',
            symbol: 'person.badge.plus',
          )
        : NativeSettingsRow(
            id: 'account',
            title: _accountName(others.first),
            symbol: 'person.crop.circle',
          );
    return [
      [
        if (BuildProfile.digitalId)
          const NativeSettingsRow(
            id: 'digital-id',
            title: 'Цифровой ID',
            symbol: 'person.text.rectangle',
          ),
        const NativeSettingsRow(
          id: 'sferum',
          title: 'Войти в Сферум',
          symbol: 'globe',
        ),
        const NativeSettingsRow(
          id: 'saved',
          title: 'Избранное',
          symbol: 'bookmark',
        ),
        account,
        if (showExtra)
          NativeSettingsRow(
            id: 'info',
            title: l10n.infoTitle,
            symbol: 'info.circle',
          ),
      ],
      const [
        NativeSettingsRow(id: 'theme', title: 'Тема', symbol: 'moon'),
        NativeSettingsRow(
          id: 'appearance',
          title: 'Внешний вид',
          symbol: 'paintbrush',
        ),
        NativeSettingsRow(id: 'wallpaper', title: 'Фон чатов', symbol: 'photo'),
        NativeSettingsRow(id: 'fonts', title: 'Шрифты', symbol: 'textformat'),
        NativeSettingsRow(
          id: 'actions',
          title: 'Меню действий',
          symbol: 'ellipsis.circle',
        ),
        NativeSettingsRow(
          id: 'icon',
          title: 'Иконка приложения',
          symbol: 'app.badge',
        ),
      ],
      const [
        NativeSettingsRow(id: 'folders', title: 'Папки', symbol: 'folder'),
      ],
      [
        NativeSettingsRow(
          id: 'haptics',
          title: 'Тактильный отклик',
          symbol: 'waveform',
          switchValue: _hapticsEnabled,
        ),
        const NativeSettingsRow(
          id: 'notifications',
          title: 'Уведомления',
          symbol: 'bell',
        ),
        const NativeSettingsRow(
          id: 'media',
          title: 'Камера и микрофон',
          symbol: 'video',
        ),
        const NativeSettingsRow(
          id: 'cloud',
          title: 'Облачное хранилище [BETA]',
          symbol: 'cloud',
        ),
        const NativeSettingsRow(
          id: 'proxy',
          title: 'Прокси',
          symbol: 'network',
        ),
        if (BuildProfile.spoofUi)
          NativeSettingsRow(
            id: 'spoof',
            title: l10n.profileMenuSpoof,
            symbol: 'lock.shield',
          ),
        const NativeSettingsRow(
          id: 'security',
          title: 'Безопасность',
          symbol: 'lock',
        ),
        const NativeSettingsRow(
          id: 'devices',
          title: 'Устройства',
          symbol: 'iphone',
        ),
      ],
      if (_debugMenuVisible)
        const [
          NativeSettingsRow(
            id: 'developers',
            title: 'Для разработчиков',
            symbol: 'hammer',
          ),
        ],
      [
        if (BuildProfile.selfUpdate)
          NativeSettingsRow(
            id: 'update',
            title: _isCheckingForUpdates
                ? l10n.updateChecking
                : l10n.updateCheck,
            symbol: 'arrow.down.circle',
            enabled: !_isCheckingForUpdates,
          ),
        const NativeSettingsRow(
          id: 'komet',
          title: 'Komet',
          symbol: 'sparkles',
        ),
        const NativeSettingsRow(
          id: 'logout',
          title: 'Выйти из аккаунта',
          symbol: 'rectangle.portrait.and.arrow.right',
          destructive: true,
        ),
      ],
    ];
  }

  void _onNativeSettingsTap(BuildContext context, String id) {
    switch (id) {
      case 'digital-id':
        Navigator.push(
          context,
          iosPageRoute(
            context,
            builder: (context) =>
                AppDigitalIdNative.current.value || !webViewSupported
                ? const DigitalIdScreen()
                : const DigitalIdWebScreen(),
          ),
        );
      case 'sferum':
        Navigator.push(
          context,
          iosPageRoute(
            context,
            builder: (context) => WebAppScreen(
              title: 'Сферум',
              entryPoint: WebAppEntryPoint.settings,
              loader: () => webAppModule.fetchSferum(),
            ),
          ),
        );
      case 'saved':
        _openSavedMessages();
      case 'account':
        if (_accounts.where((account) => account.id != _profile?.id).isEmpty) {
          unawaited(startAddAccount(context));
        } else {
          showAccountSwitcherAt(
            context,
            MediaQuery.sizeOf(context).center(Offset.zero),
          );
        }
      case 'info':
        Navigator.push(
          context,
          iosPageRoute(context, builder: (context) => const InfoScreen()),
        );
      case 'theme':
        Navigator.push(
          context,
          iosPageRoute(
            context,
            builder: (context) => const ThemeSettingsScreen(),
          ),
        );
      case 'appearance':
        Navigator.push(
          context,
          iosPageRoute(context, builder: (context) => const AppearanceScreen()),
        );
      case 'wallpaper':
        Navigator.push(
          context,
          iosPageRoute(
            context,
            builder: (context) => const ChatBackgroundScreen(),
          ),
        );
      case 'fonts':
        Navigator.push(
          context,
          iosPageRoute(
            context,
            builder: (context) => const FontSettingsScreen(),
          ),
        );
      case 'actions':
        Navigator.push(
          context,
          iosPageRoute(
            context,
            builder: (context) => const MessageActionsScreen(),
          ),
        );
      case 'icon':
        Navigator.push(
          context,
          iosPageRoute(context, builder: (context) => const AppIconScreen()),
        );
      case 'folders':
        Navigator.push(
          context,
          iosPageRoute(context, builder: (context) => const FoldersScreen()),
        );
      case 'notifications':
        _openNotifications();
      case 'media':
        Navigator.push(
          context,
          iosPageRoute(
            context,
            builder: (context) => const MediaDevicesScreen(),
          ),
        );
      case 'cloud':
        unawaited(_openCloudStorage(context));
      case 'proxy':
        final cs = Theme.of(context).colorScheme;
        showIosSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: cs.surfaceContainerHigh,
          shape: kSheetShape,
          builder: (_) => const SafeArea(child: ProxySettingsSheet()),
        );
      case 'spoof':
        Navigator.push(
          context,
          iosPageRoute(context, builder: (context) => const SpoofScreen()),
        );
      case 'security':
        Navigator.push(
          context,
          iosPageRoute(
            context,
            settings: const RouteSettings(name: 'SecurityScreen'),
            builder: (context) => const SecurityScreen(),
          ),
        );
      case 'devices':
        Navigator.push(
          context,
          iosPageRoute(context, builder: (context) => const DevicesScreen()),
        );
      case 'developers':
        Navigator.push(
          context,
          iosPageRoute(context, builder: (context) => const DebugMenuScreen()),
        );
      case 'update':
        unawaited(_checkForUpdates());
      case 'komet':
        Navigator.push(
          context,
          iosPageRoute(
            context,
            builder: (context) => const KometSettingsScreen(),
          ),
        );
      case 'logout':
        unawaited(_confirmLogout());
    }
  }

  void _onNativeSettingsHeader(String action, Rect rect) {
    switch (action) {
      case 'qr':
        showProfileQrSheet(
          context,
          name: _fullName,
          avatarUrl: _profile?.baseUrl,
        );
      case 'avatar':
        unawaited(_openAvatarViewer());
      case 'menu':
        final current = _currentAvatar;
        if (current == null) return;
        final id = current.id;
        showAvatarMenu(
          context: context,
          anchorRect: rect,
          onSave: () => saveAvatarPhoto(context, current.url),
          onDelete: id == null ? null : () => _deleteAvatar(id),
        );
      case 'edit':
      case 'bio':
        Navigator.push(
          context,
          iosPageRoute(
            context,
            builder: (context) => const EditProfileScreen(),
          ),
        );
      case 'version':
        _onVersionLabelTap();
    }
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme cs,
    String name,
    String phone,
    double t,
  ) {
    final topPad = MediaQuery.paddingOf(context).top;
    final hasPhoto = (_profile?.baseUrl ?? '').isNotEmpty;
    final phoneMissing = (_profile?.phone ?? 0) == 0;
    final pt = hasPhoto ? t : 0.0;
    if (pt > 0) _headerEverExpanded = true;

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          const avatarSize = 88.0;
          final avatarRect = Rect.lerp(
            Rect.fromLTWH(
              (w - avatarSize) / 2,
              topPad + 68,
              avatarSize,
              avatarSize,
            ),
            Rect.fromLTWH(0, 0, w, h),
            pt,
          )!;
          final radius = lerpDouble(avatarSize / 2, 0, pt)!;
          final iconColor = Color.lerp(cs.onSurfaceVariant, Colors.white, pt)!;
          final nameColor = Color.lerp(cs.onSurface, Colors.white, pt)!;
          final subColor = Color.lerp(
            cs.onSurfaceVariant,
            Colors.white.withValues(alpha: 0.85),
            pt,
          )!;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fromRect(
                rect: avatarRect,
                child: GestureDetector(
                  onTap: _openAvatarViewer,
                  child: _buildMorphAvatar(cs, name, radius, pt),
                ),
              ),
              if (hasPhoto)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: topPad + 72,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: pt,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black38, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (hasPhoto)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 150,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: pt,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // #***! виньетка как на чужом профиле: развёрнутое фото уводим
              // в цвет фона, чтобы не обрывалось резкой границей
              if (hasPhoto)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _headerVignette,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: pt,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              spectrumSurfaceColor(cs).withValues(alpha: 0),
                              spectrumSurfaceColor(cs).withValues(alpha: 0.55),
                              spectrumSurfaceColor(cs),
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 8,
                right: 8,
                top: topPad + 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        IosSymbols.qrCode(context),
                        color: iconColor,
                        size: 26,
                        weight: 400,
                      ),
                      onPressed: () => showProfileQrSheet(
                        context,
                        name: name,
                        avatarUrl: _profile?.baseUrl,
                      ),
                    ),
                    Expanded(
                      child: Opacity(
                        opacity: 1 - pt,
                        child: const ConnectionStatusLine(
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: _avatarMenuKey,
                          icon: Icon(
                            IosSymbols.moreVert(context),
                            color: iconColor,
                            size: 22,
                            weight: 400,
                          ),
                          onPressed: _currentAvatar == null
                              ? null
                              : _openAvatarMenu,
                        ),
                        IconButton(
                          icon: Icon(
                            IosSymbols.edit(context),
                            color: iconColor,
                            size: 22,
                            weight: 400,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              iosPageRoute(
                                context,
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: lerpDouble(20, 14, pt)!,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _headerAligned(
                      pt,
                      Text(
                        name,
                        style: TextStyle(
                          color: nameColor,
                          fontSize: IosGlass.of(context)
                              ? lerpDouble(IosTypography.headerTitle, 28, pt)
                              : lerpDouble(20, 26, pt),
                          fontWeight: FontWeight.w700,
                          fontFamily: displayFontOf(context),
                          letterSpacing: IosGlass.of(context)
                              ? IosTypography.letterSpacing(
                                  IosTypography.headerTitle,
                                )
                              : null,
                        ),
                      ),
                    ),
                    _headerAligned(
                      pt,
                      _buildOnlineStatus(cs, textColor: subColor),
                    ),
                    const SizedBox(height: 6),
                    _headerAligned(
                      pt,
                      phoneMissing
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                phone,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: subColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  height: 1.3,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _isPhoneVisible = !_isPhoneVisible,
                                  ),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: _PhoneSpoiler(
                                      text: phone,
                                      isVisible: _isPhoneVisible,
                                      style: TextStyle(
                                        color: subColor,
                                        fontSize: IosGlass.of(context)
                                            ? IosTypography.listSubtitle
                                            : 14,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: IosGlass.of(context)
                                            ? IosTypography.letterSpacing(
                                                IosTypography.listSubtitle,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                AnimatedSlashIcon(
                                  icon: Symbols.visibility,
                                  slashedIcon: Symbols.visibility_off,
                                  slashed: !_isPhoneVisible,
                                  size: 14,
                                  color: Color.lerp(
                                    cs.mutedText,
                                    Colors.white70,
                                    pt,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _headerAligned(double t, Widget child) {
    return Align(
      alignment: Alignment.lerp(Alignment.center, Alignment.centerLeft, t)!,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: lerpDouble(12, 18, t)!),
        child: child,
      ),
    );
  }

  Widget _buildMorphAvatar(
    ColorScheme cs,
    String name,
    double radius,
    double pt,
  ) {
    final photos = _avatarPhotos;
    final index = _avatarIndex.clamp(0, math.max(0, photos.length - 1)).toInt();
    final base = photos.isEmpty ? null : photos[index].url;
    final borderOpacity = (1 - pt * 2).clamp(0.0, 1.0);
    if (base == null || base.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.5),
            width: 2.5,
          ),
        ),
        child: KometAvatar(name: name, size: 88, fontSize: 32),
      );
    }
    final letterFallback = ColoredBox(
      color: cs.primaryContainer,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: cs.onPrimaryContainer,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    final isMain = photos[index].id == _profile?.photoId;
    final rawUrl = _profile?.baseRawUrl;
    final arrowOpacity = ((pt - 0.35) / 0.35).clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          // #***! свайп по самой аватарке, без вложенного скролла:
          // шапка морфится и ломала бы пейджеру размер вьюпорта
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: photos.length > 1 ? _onAvatarSwipe : null,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final incoming = child.key == ValueKey(base);
                final dx = (_avatarForward ? 1.0 : -1.0) * (incoming ? 1 : -1);
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(dx, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, ?current],
              ),
              child: Stack(
                key: ValueKey(base),
                fit: StackFit.expand,
                children: [
                  // #***! уменьшенный кадр показываем сразу, поверх него
                  // догружается полноразмерный — иначе в развёрнутой шапке мыло
                  CachedNetworkImage(
                    imageUrl: base,
                    fit: BoxFit.cover,
                    memCacheWidth: 264,
                    memCacheHeight: 264,
                    placeholder: (_, _) => letterFallback,
                    errorWidget: (_, _, _) => letterFallback,
                  ),
                  if (_headerEverExpanded)
                    CachedNetworkImage(
                      imageUrl: isMain && rawUrl != null && rawUrl.isNotEmpty
                          ? rawUrl
                          : base,
                      fit: BoxFit.cover,
                      // #***! шире экрана декодировать незачем
                      memCacheWidth: _fullAvatarCacheWidth,
                      fadeInDuration: const Duration(milliseconds: 250),
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (photos.length > 1 && arrowOpacity > 0) ...[
          if (index > 0)
            _avatarArrow(
              alignLeft: true,
              opacity: arrowOpacity,
              onTap: () => _stepAvatar(-1),
            ),
          if (index < photos.length - 1)
            _avatarArrow(
              alignLeft: false,
              opacity: arrowOpacity,
              onTap: () => _stepAvatar(1),
            ),
        ],
        if (borderOpacity > 0)
          IgnorePointer(
            child: Opacity(
              opacity: borderOpacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.5),
                    width: 2.5,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // #***! био показываем карточкой как на чужом профиле, тап ведёт в редактор
  Widget _buildBioCard(ColorScheme cs, AppLocalizations l10n) {
    final bio = _profile?.description ?? '';
    if (bio.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          iosPageRoute(
            context,
            builder: (context) => const EditProfileScreen(),
          ),
        ),
        child: GlossyPill(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          depth: 6,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.editProfileBio,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  bio,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: IosGlass.of(context)
                        ? IosTypography.listTitle
                        : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarArrow({
    required bool alignLeft,
    required double opacity,
    required VoidCallback onTap,
  }) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: alignLeft ? 6 : null,
      right: alignLeft ? null : 6,
      child: Center(
        child: Opacity(
          opacity: opacity,
          child: Material(
            color: Colors.black.withValues(alpha: 0.35),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  alignLeft
                      ? IosSymbols.chevronLeft(context)
                      : IosSymbols.chevronRight(context),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatSelfSeen(int seconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    final now = DateTime.now();
    final time = formatClock(dt);
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) return time;
    final datePart = dt.year == now.year
        ? '${dt.day} ${kRuMonthsShort[dt.month - 1]}'
        : '${dt.day} ${kRuMonthsShort[dt.month - 1]} ${dt.year}';
    return '$datePart, $time';
  }

  Widget _buildOnlineStatus(ColorScheme cs, {Color? textColor}) {
    return ValueListenableBuilder<bool>(
      valueListenable: KometSettings.selfOnlineCheck,
      builder: (context, enabled, _) {
        if (!enabled) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: ValueListenableBuilder<bool>(
            valueListenable: SelfPresence.isOnline,
            builder: (context, online, _) => ValueListenableBuilder<int?>(
              valueListenable: SelfPresence.lastSeenSeconds,
              builder: (context, seen, _) {
                final label = online
                    ? 'онлайн'
                    : (seen != null
                          ? 'Был(-а) ${_formatSelfSeen(seen)}'
                          : 'офлайн');
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      IosSymbols.checkCircle(context),
                      fill: 1,
                      size: 15,
                      color: online ? kSuccessGreen : cs.mutedText,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor ?? cs.onSurfaceVariant,
                        fontSize: IosGlass.of(context)
                            ? IosTypography.listSubtitle
                            : 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required List<_SettingsItem> items,
  }) {
    return SettingsCard(
      children: List.generate(items.length, (index) {
        final item = items[index];
        if (item.onToggle != null && item.toggleValue != null) {
          return SettingsToggleTile(
            icon: item.icon ?? Symbols.vibration,
            label: item.label,
            subtitle: item.subtitle,
            value: item.toggleValue!,
            onChanged: item.onToggle!,
          );
        }
        final tile = SettingsNavTile(
          icon: item.icon,
          leading: item.leading,
          label: item.label,
          tintColor: item.tintColor,
          onTap: item.onTap,
          isLast: index == items.length - 1,
        );
        return item.wrap?.call(tile) ?? tile;
      }),
    );
  }

  void _openSavedMessages() {
    if (ChatListScreen.openSavedMessages()) return;
    pushSwipeable(
      context,
      (_) => const ChatScreen(
        chatId: 0,
        name: 'Избранное',
        imageUrl: '',
        chatType: 'DIALOG',
      ),
    );
  }

  _SettingsItem _accountItem(BuildContext context) {
    final activeId = _profile?.id;
    final others = [
      for (final account in _accounts)
        if (account.id != activeId) account,
    ];
    if (others.isEmpty) {
      return _SettingsItem(
        icon: Symbols.person_add,
        label: 'Добавить профиль',
        onTap: () => unawaited(startAddAccount(context)),
      );
    }
    final other = others.first;
    return _SettingsItem(
      leading: KometAvatar(
        name: _accountName(other),
        imageUrl: other.baseUrl,
        size: IosGlass.of(context) ? 30 : 24,
      ),
      label: _accountName(other),
      onTap: _showAccountFallbackMenu,
      wrap: (tile) => KeyedSubtree(
        key: _accountRowKey,
        child: NativeMenuButton.supported
            ? NativeMenuButton(
                items: _accountMenuItems(),
                onSelected: _onAccountMenuSelected,
                onFallback: (rect) =>
                    showAccountSwitcherAt(context, rect.center),
                child: tile,
              )
            : tile,
      ),
    );
  }

  static String _accountName(ProfileData account) {
    final name = [
      account.firstName,
      account.lastName ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ');
    return name.isEmpty ? '+${account.phone}' : name;
  }

  List<NativeMenuItem> _accountMenuItems() {
    final activeId = _profile?.id;
    final ordered = [
      ..._accounts.where((a) => a.id == activeId),
      ..._accounts.where((a) => a.id != activeId),
    ];
    return [
      for (final account in ordered)
        NativeMenuItem(
          id: '${account.id}',
          title: _accountName(account),
          subtitle: '+${account.phone}',
          imageUrl: account.baseUrl,
          symbol: 'person.crop.circle',
          checked: account.id == activeId,
        ),
      const NativeMenuItem.separator(),
      const NativeMenuItem(
        id: _addAccountMenuId,
        title: 'Добавить профиль',
        symbol: 'plus',
      ),
    ];
  }

  void _onAccountMenuSelected(String id) {
    if (id == _addAccountMenuId) {
      unawaited(startAddAccount(context));
      return;
    }
    final accountId = int.tryParse(id);
    if (accountId == null || accountId == _profile?.id) return;
    unawaited(switchToAccount(context, accountId));
  }

  void _showAccountFallbackMenu() {
    final box = _accountRowKey.currentContext?.findRenderObject() as RenderBox?;
    final point = box != null && box.hasSize
        ? box.localToGlobal(box.size.center(Offset.zero))
        : MediaQuery.sizeOf(context).center(Offset.zero);
    showAccountSwitcherAt(context, point);
  }
}

const _addAccountMenuId = 'add';

class _SettingsItem {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;
  final Color? tintColor;
  final Widget Function(Widget tile)? wrap;

  const _SettingsItem({
    this.icon,
    this.leading,
    required this.label,
    this.subtitle,
    this.onTap,
    this.toggleValue,
    this.onToggle,
    this.tintColor,
    this.wrap,
  });
}

class _PhoneSpoiler extends StatefulWidget {
  final String text;
  final bool isVisible;
  final TextStyle style;

  const _PhoneSpoiler({
    required this.text,
    required this.isVisible,
    required this.style,
  });

  @override
  State<_PhoneSpoiler> createState() => _PhoneSpoilerState();
}

class _PhoneSpoilerState extends State<_PhoneSpoiler>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (!widget.isVisible) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _PhoneSpoiler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible == oldWidget.isVisible) return;
    if (widget.isVisible) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState: widget.isVisible
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: SizedBox(
        child: CustomPaint(
          size: const Size(110, 16),
          painter: _SpoilerPainter(_controller, widget.style.color!),
        ),
      ),
      secondChild: Text(widget.text, style: widget.style),
    );
  }
}

class _SpoilerPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _SpoilerPainter(this.animation, this.color) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      paint,
    );

    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 60; i++) {
      double dx = (i * 17.5 + animation.value * 20) % size.width;
      double dy = (i * 13.7 + animation.value * 15) % size.height;
      double opacity = (0.2 + 0.3 * (i % 5) / 5.0).clamp(0.0, 1.0);
      particlePaint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(dx, dy), 1.2, particlePaint);
    }
  }

  @override
  bool shouldRepaint(_SpoilerPainter oldDelegate) => true;
}
