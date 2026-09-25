import 'package:flutter/material.dart';
import '../../../backend/modules/account/account_models.dart';
import '../../../core/protocol/packet.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../widgets/animated_slash_icon.dart';
import '../../widgets/auth_limits_sheet.dart';
import '../../widgets/custom_notification.dart';
import '../../widgets/login_success_screen.dart';
import '../../widgets/small_spinner.dart';
import 'session_stale_recovery.dart';
import '../../widgets/glass/ios_auth_chrome.dart';
import '../../widgets/glass/ios_glass.dart';
import '../../widgets/glass/ios_symbols.dart';
import '../../widgets/glass/ios_typography.dart';
import '../../widgets/glass/ios_palette.dart';

class Password2FAScreen extends StatefulWidget {
  final String trackId;
  final String? hint;
  // #***! нужен для эксперим. SMS-входа через веб (запрос кода на сокете)
  final String? rawPhone;

  const Password2FAScreen({
    super.key,
    required this.trackId,
    this.hint,
    this.rawPhone,
  });

  @override
  State<Password2FAScreen> createState() => _Password2FAScreenState();
}

class _Password2FAScreenState extends State<Password2FAScreen>
    with SessionStaleRecovery {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  String get connectionDroppedMessage => 'Соединение прервалось…';

  @override
  void initState() {
    super.initState();
    startSessionRecovery();
  }

  @override
  void dispose() {
    stopSessionRecovery();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void recoverStaleSession() {
    if (recovering || !mounted) return;
    recovering = true;
    showCustomNotification(context, 'Соединение прервалось — войдите заново');
    Navigator.of(context).pop();
  }

  Future<void> _checkPassword() async {
    if (_passwordController.text.isEmpty || _isLoading || recovering) return;

    if (sessionStale) {
      recoverStaleSession();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    var passed = false;
    try {
      final result = await accountModule.checkPassword(
        password: _passwordController.text,
        trackId: widget.trackId,
      );
      passed = true;
      stopSessionRecovery();

      String? avatarUrl;
      // #***! эксперим. SMS-вход через веб: пароль пользователя уже есть, добываем
      // сокетовый токен и перезаходим боевой версией
      if (api.webHandshake && widget.rawPhone != null) {
        await accountModule.completeWebSmsSocketLogin(
          phone: widget.rawPhone!,
          accountId: result.accountId,
          webToken: result.loginToken,
          existingPassword: _passwordController.text,
        );
      } else {
        final loginResult = await accountModule.login(
          accountId: result.accountId,
          token: result.loginToken,
        );
        avatarUrl = loginResult.profile.baseUrl;
      }

      final avatar = mounted
          ? await precacheLoginAvatar(context, avatarUrl)
          : null;

      await markAuthLimitsPending(AuthEntry.login);

      final navigator = mounted
          ? Navigator.of(context)
          : KometApp.navigatorKey.currentState;
      navigator?.pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 240),
          pageBuilder: (_, _, _) => LoginSuccessScreen(avatar: avatar),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final l10n = AppLocalizations.of(context)!;
      if (!passed && (isSessionStateError(e) || sessionStale)) {
        recoverStaleSession();
      } else if (e is WrongPasswordException) {
        showCustomNotification(context, l10n.passwordEntryWrongPassword);
      } else {
        showCustomNotification(context, l10n.devicesGenericError('$e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ios = IosGlass.of(context);
    return Scaffold(
      backgroundColor: iosAuthBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            IosSymbols.chevronBack(context),
            color: cs.onSurfaceVariant,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Двухфакторная аутентификация',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: ios ? IosTypography.title2 : 22,
                  fontWeight: ios ? IosTypography.semibold : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Введите пароль для завершения входа',
                style: TextStyle(
                  color: cs.outline,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              if (widget.hint != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Подсказка: ${widget.hint}',
                  style: TextStyle(
                    color: cs.tertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                autofocus: true,
                enabled: !_isLoading,
                style: iosAuthFieldStyle(context),
                decoration: iosAuthFieldDecoration(
                  context,
                  hintText: 'Пароль',
                ).copyWith(
                  fillColor: ios
                      ? IosPalette.searchFill(cs)
                      : cs.surfaceContainerHigh,
                  filled: true,
                  suffixIcon: IconButton(
                    icon: AnimatedSlashIcon(
                      icon: IosSymbols.visibility(context),
                      slashedIcon: IosSymbols.visibilityOff(context),
                      slashed: _isPasswordVisible,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                onSubmitted: (_) => _checkPassword(),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _checkPassword,
                    backgroundColor: _passwordController.text.isNotEmpty
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: _isLoading
                        ? SmallSpinner(size: 24, color: cs.onPrimaryContainer)
                        : Icon(
                            IosSymbols.chevronRight(context),
                            color: _passwordController.text.isNotEmpty
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
