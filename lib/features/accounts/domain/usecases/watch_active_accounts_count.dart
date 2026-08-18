import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/account_repository.dart';
import 'has_any_active_account.dart';

/// The exact count of active accounts, not just "any" — the account gate
/// (`docs/requirements/fase-1/15-gate-cuenta.md`, HU-02) needs it to tell "0 cuentas"
/// from "1 cuenta" for transferencia, which requires **two** active accounts,
/// not one.
///
/// [HasAnyActiveAccount] stays the single source of truth for the plain
/// yes/no every other surface asks; this only exists for the one surface that
/// needs the number itself. A query failure degrades to `0` for the same
/// reason [HasAnyActiveAccount] degrades to `false`: an infrastructure error
/// should read as "you need an account", never as a crash.
@injectable
class WatchActiveAccountsCount {
  const WatchActiveAccountsCount(this._repository);

  final AccountRepository _repository;

  Stream<int> call() => _repository.watchActiveAccountsCount().map(
        (result) => switch (result) {
          Right(value: final count) => count,
          Left() => 0,
        },
      );
}
