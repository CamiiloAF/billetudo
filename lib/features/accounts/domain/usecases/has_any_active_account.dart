import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/account_repository.dart';

/// HU-02 of `docs/requirements/15-gate-cuenta.md`: whether the app has any
/// active account to record a movement against — the single source of truth
/// the account gate (FAB, forms, router guards) checks before letting the
/// user reach a flow that needs one.
///
/// Backed by the same rows as [AccountRepository.watchActiveAccounts]
/// (archived and tombstoned accounts never count), but through the lighter
/// [AccountRepository.watchActiveAccountsCount] — no transaction join, no
/// balance calculation. A query failure degrades to `false` so an
/// infrastructure error surfaces as "you need an account" rather than as a
/// crash or a silently open gate.
@injectable
class HasAnyActiveAccount {
  const HasAnyActiveAccount(this._repository);

  final AccountRepository _repository;

  Stream<bool> call() => _repository.watchActiveAccountsCount().map(
        (result) => switch (result) {
          Right(value: final count) => count > 0,
          Left() => false,
        },
      );
}
