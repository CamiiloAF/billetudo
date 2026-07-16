import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/account_repository.dart';

/// HU-08: deletes an account logically.
///
/// The app always needs at least one account to record on, so deleting the last
/// active one is blocked here — the UI turns this failure into the "no se puede
/// eliminar" sheet. The row itself survives (`tombstonedAt`), which keeps
/// `Transactions.accountId` pointing somewhere real; the account number is
/// wiped from secure storage by the repository.
@injectable
class DeleteAccount {
  const DeleteAccount(this._repository);

  /// `ValidationFailure.field` returned when this is the only active account.
  static const String lastAccountField = 'lastAccount';

  final AccountRepository _repository;

  FutureResult<Unit> call(String id) async {
    switch (await _repository.getDeletionImpact(id)) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final impact) when impact.isLastAccount:
        return const Left(
          ValidationFailure(
            'the last active account cannot be deleted',
            field: lastAccountField,
          ),
        );
      case Right():
        return _repository.softDeleteAccount(id);
    }
  }
}
