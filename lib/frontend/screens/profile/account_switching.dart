import 'package:flutter/widgets.dart';

import '../../../core/storage/token_storage.dart';
import '../../../core/utils/haptics.dart';
import '../../../main.dart';
import '../../widgets/account_switcher_overlay.dart';
import '../../widgets/adaptive_shell.dart';
import '../../widgets/custom_notification.dart';
import '../../widgets/glass/ios_route.dart';
import '../auth/login_screen.dart';
import '../digital_id/digital_id_web_screen.dart';

Future<void> startAddAccount(BuildContext context) async {
  final navigator = Navigator.of(context);
  final previousId = await TokenStorage.getActiveAccountId();
  await resetDigitalIdSession();
  try {
    await accountModule.beginAddAccount();
  } catch (_) {}
  if (!context.mounted) return;
  await navigator.pushAndRemoveUntil(
    iosPageRoute(
      context,
      builder: (_) => LoginScreen(returnToAccountId: previousId),
    ),
    (route) => false,
  );
}

Future<void> switchToAccount(BuildContext context, int accountId) async {
  final navigator = Navigator.of(context);
  if (accountId == await TokenStorage.getActiveAccountId()) return;
  await resetDigitalIdSession();
  try {
    await accountModule.switchAccount(accountId);
  } catch (_) {
    if (context.mounted) {
      showCustomNotification(context, 'Не удалось переключить аккаунт');
    }
    return;
  }
  if (!context.mounted) return;
  await navigator.pushAndRemoveUntil(
    iosPageRoute(context, builder: (_) => const AdaptiveShell()),
    (route) => false,
  );
}

void showAccountSwitcherAt(BuildContext context, Offset point) {
  Haptics.medium();
  final controller = AccountSwitcherController()..attach(point);
  showAccountSwitcher(
    context: context,
    tapPoint: point,
    controller: controller,
    onSelected: (accountId) async {
      controller.dispose();
      if (!context.mounted) return;
      if (accountId == null) {
        await startAddAccount(context);
      } else {
        await switchToAccount(context, accountId);
      }
    },
  );
}
