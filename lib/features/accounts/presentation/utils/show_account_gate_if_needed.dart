import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/usecases/has_any_active_account.dart';
import '../../domain/usecases/watch_active_accounts_count.dart';
import '../widgets/account_gate_bridge_sheet.dart';
import '../widgets/account_gate_copy.dart';

/// The one place every FAB, form and router guard asks "can I proceed, or
/// does the user need to create an account first?" — `docs/requirements/
/// 15-gate-cuenta.md` HU-01/HU-02/HU-04.
///
/// Resolves to `true` the moment [surface]'s account requirement is met —
/// immediately, with no sheet at all, if it already was — and the caller
/// should go on with the action it was about to do. Resolves to `false` when
/// the user cancels the bridge (`Ahora no` or the scrim), in which case the
/// caller must do nothing else: the user stays exactly where they were
/// (HU-01).
///
/// For [AccountGateSurface.transfer] this is also what chains "0 cuentas" →
/// `XYfSq` → create → "1 cuenta" → `goGwA` → create → proceed (HU-02's "at
/// least two", the design's 0→1→2 encadenamiento): each loop iteration
/// re-reads the live count, so it re-evaluates to the right copy on its own
/// without a bespoke state machine.
Future<bool> showAccountGateIfNeeded(
  BuildContext context,
  AccountGateSurface surface,
) async {
  final hasAnyActiveAccount = getIt<HasAnyActiveAccount>();
  final watchActiveAccountsCount = getIt<WatchActiveAccountsCount>();
  final requiredCount = AccountGateCopy.requiredCount(surface);

  while (true) {
    final currentCount = surface == AccountGateSurface.transfer
        ? await watchActiveAccountsCount().first
        : await hasAnyActiveAccount().first
            ? 1
            : 0;
    if (currentCount >= requiredCount) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }
    final copy = AccountGateCopy.resolve(
      AppLocalizations.of(context),
      surface,
      currentCount: currentCount,
    );
    final wantsToCreateAccount = await AccountGateBridgeSheet.show(
      context,
      copy,
    );
    if (!wantsToCreateAccount) {
      return false;
    }

    if (!context.mounted) {
      return false;
    }
    // The account form is the same full-page HU-01 of `01-cuentas.md` used
    // everywhere else in the app — no bespoke embedded form. Its own back
    // button lets the user give up mid-way, which the next loop iteration
    // simply reads as "still not enough accounts" and shows the bridge
    // again, no special-casing needed.
    await context.push<void>(AppRoutes.newAccount);
  }
}
