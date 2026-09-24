import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:komet/core/config/countries.dart';
import 'package:komet/l10n/app_localizations.dart';
import 'package:komet/l10n/terms_of_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'code_confirmation_screen.dart';
import 'token_login_screen.dart';
import 'select_country_screen.dart';
import 'phone_input_formatter.dart';
import 'proxy_settings_sheet.dart';
import 'server_settings_sheet.dart';
import '../profile/spoof_screen.dart';
import '../profile/debug_menu_screen.dart';
import '../digital_id/digital_id_web_screen.dart';
import '../../widgets/custom_notification.dart';
import '../../widgets/adaptive_shell.dart';
import '../../widgets/sheet_helpers.dart';
import '../../widgets/small_spinner.dart';
import '../../../backend/api.dart';
import '../../../core/protocol/packet.dart';
import '../../../main.dart';
import '../../../core/config/app_frost.dart';
import '../../../core/config/build_profile.dart';
import '../../../core/config/review_access.dart';
import '../../../core/config/app_shape.dart';
import '../../widgets/glass/ios_sheet.dart';
import '../../widgets/glass/ios_route.dart';
import '../../widgets/glass/ios_alert.dart';
import '../../widgets/glass/ios_glass.dart';
import '../../widgets/glass/ios_auth_chrome.dart';
import '../../widgets/glass/ios_symbols.dart';
import '../../widgets/glass/ios_typography.dart';
import '../../widgets/glass/ios_palette.dart';
import '../../widgets/glass/glass_controls.dart';

class LoginScreen extends StatefulWidget {
  final int? returnToAccountId;

  const LoginScreen({super.key, this.returnToAccountId});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  late CountryName _selectedCountry;
  bool _isPhoneValid = false;
  bool _isTOSRead = false;
  // #***! экспериментально: представляемся веб-клиентом, чтобы код пришёл по SMS
  late bool _alwaysSendSms = api.webHandshake;
  bool _switchingSmsMode = false;
  String? _phoneError;
  Timer? _phoneErrorTimer;
  int _logoTapCount = 0;
  Timer? _logoTapTimer;
  late SessionState _sessionState;
  StreamSubscription<SessionState>? _stateSub;

  bool get _isOnline => _sessionState == SessionState.online;

  @override
  void initState() {
    super.initState();
    _sessionState = api.state;
    if (api.state == SessionState.disconnected) {
      // #***! экран входа по телефону — сокет без токена, прошлая версия
      unawaited(api.connect(authenticated: false, web: _alwaysSendSms));
    }
    _stateSub = api.stateStream.listen((state) {
      if (mounted) setState(() => _sessionState = state);
    });
    _selectedCountry = countriesByCode['RU'] ?? allCountries.first;
    _clampCountryToAllowed();
    _checkTOS();
  }

  // #***! режим зашит в рукопожатие, так что переподнимаем сессию целиком
  Future<void> _setAlwaysSendSms(bool value) async {
    if (_switchingSmsMode) return;
    setState(() {
      _alwaysSendSms = value;
      _switchingSmsMode = true;
    });
    try {
      await api.disconnect();
      await api.connect(authenticated: false, web: value);
    } catch (e) {
      if (!mounted) return;
      showCustomNotification(context, 'Не удалось переподключиться: $e');
    } finally {
      if (mounted) setState(() => _switchingSmsMode = false);
    }
  }

  // #***! предупреждение перед эксперим. SMS-входом: true=Принять, false=Отмена,
  // null=закрыли мимо (галочку не трогаем, но и дальше не идём)
  Future<bool?> _showExperimentalSmsWarning() {
    if (IosGlass.of(context)) {
      return showIosAlert<bool>(
        context: context,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'ЕСЛИ НА ВАШЕМ АККАУНТЕ НЕТ 2FA ВСЕ СЕССИИ БУДУТ СБРОШЕНЫ',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Способ экспериментальный, его использование на ваш '
              'страх и риск.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
        actions: const [
          IosAlertAction(
            id: 'cancel',
            label: 'Отмена',
            result: false,
            isCancel: true,
          ),
          IosAlertAction(
            id: 'accept',
            label: 'Принять',
            result: true,
            isDefault: true,
          ),
        ],
      );
    }
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: AppFrost.scrim(),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final cs = Theme.of(context).colorScheme;
        final curve = Curves.easeOutQuart.transform(anim1.value);
        return Opacity(
          opacity: anim1.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curve)),
            child: Transform.scale(
              scale: 0.8 + (0.2 * curve),
              child: AlertDialog(
                backgroundColor: cs.surfaceContainerHigh,
                surfaceTintColor: Colors.transparent,
                shape: AppShape.dialogBorder,
                contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ЕСЛИ НА ВАШЕМ АККАУНТЕ НЕТ 2FA ВСЕ СЕССИИ БУДУТ СБРОШЕНЫ',
                      style: TextStyle(
                        color: cs.error,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Способ экспериментальный, его использование на ваш '
                      'страх и риск.',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Отмена',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Принять',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onBackPressed() async {
    final returnId = widget.returnToAccountId;
    if (returnId != null) {
      await resetDigitalIdSession();
      try {
        await accountModule.switchAccount(returnId);
      } catch (_) {
        if (!mounted) return;
        showCustomNotification(context, 'Не удалось переключить аккаунт');
        return;
      }
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        iosPageRoute(context, builder: (_) => const AdaptiveShell()),
        (route) => false,
      );
      return;
    }
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _clampCountryToAllowed() {
    final allowed = api.registrationCountries;
    if (allowed.any((c) => c.code == _selectedCountry.code)) return;
    _selectedCountry = allowed.firstWhere(
      (c) => c.code == 'RU',
      orElse: () => allowed.first,
    );
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _phoneErrorTimer?.cancel();
    _logoTapTimer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _checkTOS() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isTOSRead = prefs.getBool('IsReadeTOS') ?? false;
      });
    }
  }

  void _onLogoTap() {
    if (!BuildProfile.devTools) return;
    _logoTapTimer?.cancel();
    _logoTapTimer = Timer(const Duration(milliseconds: 600), () {
      _logoTapCount = 0;
    });
    _logoTapCount++;
    if (_logoTapCount >= 7) {
      _logoTapTimer?.cancel();
      _logoTapCount = 0;
      Navigator.push(
        context,
        iosPageRoute(context, builder: (context) => const DebugMenuScreen()),
      );
    }
  }

  Future<void> _markTOSRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('IsReadeTOS', true);
    if (mounted) {
      setState(() {
        _isTOSRead = true;
      });
    }
  }

  void _showCountryPicker() async {
    final result = await Navigator.push<CountryName>(
      context,
      iosPageRoute(context,
        builder: (context) => SelectCountryScreen(
          selectedCountry: _selectedCountry,
          countries: api.registrationCountries,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedCountry = result;
        _phoneController.clear();
        _isPhoneValid = false;
      });
    }
  }

  String _countryDisplayName(CountryName country) {
    final lang = Localizations.localeOf(context).languageCode;
    return country.displayName(lang);
  }

  String _phoneMaskHint(CountryName country) {
    return country.phoneMask.replaceAll('#', '0');
  }

  void _showLanguagePicker() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final appContext = context;
    showIosSheet<void>(
      context: context,
      backgroundColor: cs.surfaceContainerHigh,
      shape: kSheetShape,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    l10n.loginLanguage,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ListTile(
                  title: Text(
                    l10n.languageNameRu,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    KometApp.stateOf(
                      appContext,
                    )?.applyLocale(const Locale('ru'));
                  },
                ),
                ListTile(
                  title: Text(
                    l10n.languageNameEn,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    KometApp.stateOf(
                      appContext,
                    )?.applyLocale(const Locale('en'));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTOS(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final termsLocale = Localizations.localeOf(context);
    showIosSheet(
      context: context,
      backgroundColor: cs.surfaceContainerHigh,
      isScrollControlled: true,
      shape: kSheetShape,
      builder: (context) {
        double progress = _isTOSRead ? 1.0 : 0.0;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final cs = Theme.of(context).colorScheme;
            void trackReading(ScrollMetrics metrics) {
              if (_isTOSRead) return;
              final newProgress = metrics.maxScrollExtent > 0
                  ? (metrics.pixels / metrics.maxScrollExtent).clamp(0.0, 1.0)
                  : 1.0;
              if (newProgress >= 0.99) {
                _markTOSRead();
                setModalState(() => progress = 1.0);
              } else {
                setModalState(() => progress = newProgress);
              }
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 1.0,
              snap: true,
              snapSizes: const [0.7, 1.0],
              expand: false,
              builder: (context, scrollController) => Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.loginTermsOfUse,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(IosSymbols.close(context), color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: NotificationListener<ScrollMetricsNotification>(
                        onNotification: (notification) {
                          trackReading(notification.metrics);
                          return false;
                        },
                        child: NotificationListener<ScrollUpdateNotification>(
                          onNotification: (notification) {
                            trackReading(notification.metrics);
                            return false;
                          },
                          child: ListView(
                            controller: scrollController,
                            children: [
                              Text(
                                termsOfServiceBody(termsLocale),
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 48,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(
                            right: progress == 1.0 ? 56.0 : 0.0,
                          ),
                          child: Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: progress < 1.0 ? progress : 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: progress == 1.0 ? 1.0 : 0.0,
                          curve: Curves.easeIn,
                          child: IgnorePointer(
                            ignoring: progress < 1.0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              transform: Matrix4.translationValues(
                                progress == 1.0 ? 0 : 20,
                                0,
                                0,
                              ),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  child: Icon(IosSymbols.check(context),
                                    color: cs.onPrimaryContainer,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPhoneError(String message) {
    _phoneErrorTimer?.cancel();
    setState(() => _phoneError = message);
    _phoneErrorTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _phoneError = null);
    });
  }

  Future<void> _showPhoneConfirmationDialog(String formattedPhone) async {
    final screenContext = context;
    final l10n = AppLocalizations.of(screenContext)!;
    final phoneLine = '${_selectedCountry.phoneCode} $formattedPhone';

    Future<void> confirm() async {
      final fullPhone =
          '${_selectedCountry.phoneCode}${_phoneController.text}';

      if (!_isOnline) {
        _showPhoneError(
          'Нет соединения с сервером. Подождите подключения.',
        );
        return;
      }

      if (ReviewAccess.matchesPhone(fullPhone)) {
        Navigator.push(
          screenContext,
          iosPageRoute(
            screenContext,
            builder: (context) => CodeConfirmationScreen.review(
              phoneNumber: phoneLine,
              rawPhone: fullPhone,
            ),
          ),
        );
        return;
      }

      // #***! эксперим. SMS-вход: предупреждаем про сброс
      // сессий, Отмена снимает галочку и не пускает дальше
      if (_alwaysSendSms) {
        final choice = await _showExperimentalSmsWarning();
        if (choice == false) {
          await _setAlwaysSendSms(false);
          return;
        }
        if (choice != true) return;
        if (!screenContext.mounted) return;
      }

      try {
        final result = await accountModule.requestCode(fullPhone);

        if (!screenContext.mounted) return;
        Navigator.push(
          screenContext,
          iosPageRoute(
            screenContext,
            builder: (context) => CodeConfirmationScreen(
              phoneNumber: phoneLine,
              rawPhone: fullPhone,
              token: result.token,
            ),
          ),
        );
      } catch (e) {
        if (!screenContext.mounted) return;
        _showPhoneError(
          isSessionStateError(e)
              ? 'Нет соединения с сервером. Попробуйте ещё раз.'
              : e.toString(),
        );
      }
    }

    if (IosGlass.of(screenContext)) {
      final ok = await showIosAlert<bool>(
        context: screenContext,
        title: l10n.loginConfirmPhoneTitle,
        message: phoneLine,
        actions: [
          IosAlertAction(
            id: 'edit',
            label: l10n.loginEdit,
            result: false,
            isCancel: true,
          ),
          IosAlertAction(
            id: 'ok',
            label: l10n.loginDone,
            result: true,
            isDefault: true,
          ),
        ],
      );
      if (ok == true) await confirm();
      return;
    }

    showGeneralDialog(
      context: screenContext,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: AppFrost.scrim(),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final cs = Theme.of(context).colorScheme;
        final curve = Curves.easeOutQuart.transform(anim1.value);
        return Opacity(
          opacity: anim1.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curve)),
            child: Transform.scale(
              scale: 0.8 + (0.2 * curve),
              child: AlertDialog(
                backgroundColor: cs.surfaceContainerHigh,
                surfaceTintColor: Colors.transparent,
                shape: AppShape.dialogBorder,
                contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.loginConfirmPhoneTitle,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      phoneLine,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          l10n.loginEdit,
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await confirm();
                        },
                        child: Text(
                          l10n.loginDone,
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _validateAndSubmit() {
    if (!_isTOSRead) {
      _showTOS(context);
      return;
    }
    _showPhoneConfirmationDialog(_phoneController.text);
  }

  void _notifyConnecting() {
    showCustomNotification(context, 'Подключаемся к серверу, секунду…');
  }

  void _showServerSettingsSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showIosSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surfaceContainerHigh,
      shape: kSheetShape,
      builder: (_) {
        return SafeArea(child: const ServerSettingsSheet());
      },
    );
  }

  void _showProxySettingsSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showIosSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surfaceContainerHigh,
      shape: kSheetShape,
      builder: (_) {
        return SafeArea(child: const ProxySettingsSheet());
      },
    );
  }

  void _showSecurityOptions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    showIosSheet(
      context: context,
      backgroundColor: cs.surfaceContainerHigh,
      shape: kSheetShape,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (BuildProfile.spoofUi)
                  ListTile(
                    leading: Icon(IosSymbols.security(context), color: cs.onSurface),
                    title: Text(
                      l10n.loginSpoofRedacted,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        iosPageRoute(context,
                          builder: (context) => const SpoofScreen(),
                        ),
                      );
                    },
                  ),
                ListTile(
                  leading: Icon(IosSymbols.vpnLock(context), color: cs.onSurface),
                  title: Text(
                    l10n.loginProxy,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showProxySettingsSheet(context);
                  },
                ),
                ListTile(
                  leading: Icon(Symbols.dns, color: cs.onSurface),
                  title: Text(
                    l10n.loginChangeServer,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showServerSettingsSheet(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOtherLoginMethods(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    showIosSheet(
      context: context,
      backgroundColor: cs.surfaceContainerHigh,
      shape: kSheetShape,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (BuildProfile.qrLogin)
                  ListTile(
                    leading: Icon(IosSymbols.qrCode(context), color: cs.onSurface),
                    title: Text(
                      l10n.loginSignInWithQr,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                if (BuildProfile.tokenLogin)
                  ListTile(
                    leading: Icon(Symbols.key, color: cs.onSurface),
                    title: Text(
                      l10n.loginSignInWithToken,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        iosPageRoute(context,
                          builder: (_) => TokenLoginScreen(
                            returnToAccountId: widget.returnToAccountId,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final ios = IosGlass.of(context);
    return Scaffold(
      backgroundColor: iosAuthBackground(context),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -500) {
            _showTOS(context);
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 44),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (Navigator.canPop(context) ||
                                  widget.returnToAccountId != null)
                                IconButton(
                                  onPressed: _onBackPressed,
                                  icon: Icon(
                                    IosSymbols.chevronBack(context),
                                    color: cs.onSurfaceVariant,
                                    weight: 400,
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _showSecurityOptions(context),
                                    icon: Icon(
                                      IosSymbols.admin(context),
                                      color: cs.onSurfaceVariant,
                                      weight: 400,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _showLanguagePicker,
                                    icon: Icon(
                                      IosSymbols.language(context),
                                      color: cs.onSurfaceVariant,
                                      weight: 400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 74),
                          Center(
                            child: Column(
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _onLogoTap,
                                  child: Image.asset(
                                    'assets/komet.png',
                                    height: 80,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.loginTitle,
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: ios ? IosTypography.largeTitle : 32,
                                    fontWeight: ios
                                        ? IosTypography.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.loginSubtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          InkWell(
                            onTap: _showCountryPicker,
                            borderRadius: BorderRadius.circular(50),
                            child: _buildInputField(
                              label: l10n.loginCountry,
                              content: Row(
                                children: [
                                  Text(
                                    _countryDisplayName(_selectedCountry),
                                    style: iosAuthFieldStyle(context),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    IosSymbols.chevronDown(context),
                                    color: cs.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          _buildInputField(
                            label: l10n.loginPhoneNumber,
                            content: Row(
                              children: [
                                Text(
                                  _selectedCountry.phoneCode,
                                  style: iosAuthFieldStyle(context),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: cs.outlineVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    key: ValueKey(_selectedCountry.code),
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      PhoneInputFormatter(_selectedCountry),
                                    ],
                                    style: iosAuthFieldStyle(context),
                                    decoration: InputDecoration(
                                      hintText: _phoneMaskHint(
                                        _selectedCountry,
                                      ),
                                      hintStyle: TextStyle(
                                        color: ios
                                            ? IosPalette.secondaryLabel(cs)
                                            : cs.outline,
                                        fontSize: ios
                                            ? IosTypography.body
                                            : 15,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (value) {
                                      final digits = value.replaceAll(
                                        RegExp(r'\D'),
                                        '',
                                      );
                                      setState(() {
                                        _isPhoneValid =
                                            digits.length ==
                                            _selectedCountry.phoneDigits;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topLeft,
                            child: _phoneError != null
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      _phoneError!,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: _switchingSmsMode
                                ? null
                                : () => _setAlwaysSendSms(!_alwaysSendSms),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Всегда слать СМС (ЭКСПЕРИМЕНТАЛЬНО)',
                                      style: TextStyle(
                                        color: cs.onSurface,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GlassSwitch(
                                    value: _alwaysSendSms,
                                    onChanged: _switchingSmsMode
                                        ? null
                                        : _setAlwaysSendSms,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (BuildProfile.qrLogin || BuildProfile.tokenLogin)
                            TextButton(
                              onPressed: () => _showOtherLoginMethods(context),
                              child: Text(
                                l10n.loginOtherSignInMethods,
                                style: TextStyle(
                                  color: cs.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 24.0),
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: cs.onSurface,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: l10n.loginTermsIntro,
                                          style: TextStyle(
                                            color: cs.onSurface,
                                            fontSize: 14,
                                            height: 1.4,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        TextSpan(
                                          text: l10n.loginTermsLink,
                                          style: TextStyle(
                                            color: cs.primary,
                                            fontSize: 14,
                                            height: 1.4,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => _showTOS(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: ios
                                    ? CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: !_isPhoneValid
                                            ? null
                                            : (_isOnline
                                                  ? _validateAndSubmit
                                                  : _notifyConnecting),
                                        child: Container(
                                          width: kIosAuthPrimaryHeight,
                                          height: kIosAuthPrimaryHeight,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: _isPhoneValid
                                                ? cs.primary
                                                : cs.surfaceContainerHighest,
                                            shape: BoxShape.circle,
                                          ),
                                          child: _isPhoneValid && !_isOnline
                                              ? SmallSpinner(
                                                  size: 22,
                                                  color: Colors.white,
                                                )
                                              : Icon(
                                                  IosSymbols.chevronRight(
                                                    context,
                                                  ),
                                                  color: _isPhoneValid
                                                      ? Colors.white
                                                      : cs.onSurfaceVariant,
                                                ),
                                        ),
                                      )
                                    : FloatingActionButton(
                                        onPressed: !_isPhoneValid
                                            ? null
                                            : (_isOnline
                                                  ? _validateAndSubmit
                                                  : _notifyConnecting),
                                        backgroundColor: _isPhoneValid
                                            ? cs.primaryContainer
                                            : cs.surfaceContainerHighest,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                        ),
                                        child: _isPhoneValid && !_isOnline
                                            ? SmallSpinner(
                                                size: 24,
                                                color: cs.onPrimaryContainer,
                                              )
                                            : Icon(
                                                IosSymbols.chevronRight(
                                                  context,
                                                ),
                                                color: _isPhoneValid
                                                    ? cs.onPrimaryContainer
                                                    : cs.onSurfaceVariant,
                                              ),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required String label, required Widget content}) {
    final cs = Theme.of(context).colorScheme;
    final ios = IosGlass.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              height: ios ? 52 : 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: ios ? IosPalette.searchFill(cs) : null,
                border: ios
                    ? null
                    : Border.all(color: cs.primary, width: 1.5),
                borderRadius: BorderRadius.circular(ios ? 12 : 50),
              ),
              alignment: Alignment.centerLeft,
              child: content,
            ),
            Positioned(
              top: -10,
              left: 20,
              child: Container(
                color: ios ? iosAuthBackground(context) : cs.surface,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label,
                  style: TextStyle(
                    color: ios ? IosPalette.secondaryLabel(cs) : cs.primary,
                    fontSize: ios ? IosTypography.footnote : 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
