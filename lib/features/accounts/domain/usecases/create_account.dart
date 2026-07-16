import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/account.dart';
import '../entities/account_draft.dart';
import '../repositories/account_repository.dart';

/// HU-01/HU-02/HU-03: creates an account.
///
/// Validation (name, currency, card fields, forbidden PAN) and `last4`
/// derivation live in [AccountDraft.validated]; the repository only persists
/// what already passed it.
@injectable
class CreateAccount {
  const CreateAccount(this._repository);

  final AccountRepository _repository;

  FutureResult<Account> call(AccountDraft draft) =>
      draft.validated().fold<FutureResult<Account>>(
            (failure) async => Left(failure),
            _repository.createAccount,
          );
}
