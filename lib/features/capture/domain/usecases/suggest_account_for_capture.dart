import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/issuer_settings_repository.dart';
import '../repositories/pending_capture_repository.dart';

/// Resolves which of the user's accounts a capture belongs to (HU-06).
///
/// Three steps, in this order:
///  1. `accountHint` against `Accounts.cardLast4` — the physical card, which
///     is what a purchase notification quotes.
///  2. `accountHint` against `Accounts.last4` — the account number. Checked
///     second because on a card account both columns often carry the same
///     digits, and the more specific match must not be shadowed by the more
///     generic one.
///  3. `sourcePackage` against the account the user linked to that issuer.
///
/// **Step 3 is not a nicety, it is the only path that works for most
/// issuers.** Verified against real notifications: Nu and Nequi never quote
/// the last four digits, so there is no hint to match at all; Google Wallet
/// does (`38.000,00 COP con Visa ••5615`). Without the issuer link those
/// captures would arrive account-less forever. It also gets the account right
/// from the first capture, since the user configured it when switching the
/// issuer on, instead of after a first manual confirmation.
///
/// The hint still wins over the issuer link when both are available: one
/// issuer app can notify for several cards, and the digits identify which.
///
/// Always a SUGGESTION: the form shows it pre-filled and the user can change
/// it. Anything ambiguous (two accounts ending in the same four digits)
/// resolves to `null` — no suggestion is better than the wrong account.
@injectable
class SuggestAccountForCapture {
  const SuggestAccountForCapture(this._repository, this._issuers);

  final PendingCaptureRepository _repository;
  final IssuerSettingsRepository _issuers;

  FutureResult<String?> call({
    required String sourcePackage,
    String? accountHint,
  }) async {
    final hint = accountHint?.trim();
    if (hint != null && hint.isNotEmpty) {
      final byHint = await _repository.findAccountIdByLast4(hint);
      // A lookup failure falls through to the issuer link instead of losing
      // the suggestion outright.
      final matched = byHint.getOrElse((_) => null);
      if (matched != null) {
        return Right(matched);
      }
    }
    return _issuers.accountIdForPackage(sourcePackage);
  }
}
