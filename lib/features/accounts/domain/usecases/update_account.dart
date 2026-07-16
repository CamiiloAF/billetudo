import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/account.dart';
import '../entities/account_draft.dart';
import '../repositories/account_repository.dart';

/// HU-06: edits an account.
///
/// Changing `type` or `currency` on an account that already has transactions
/// rewrites the meaning of its history (a card's balance is debt; the currency
/// scales every figure), so it is refused unless the caller passes
/// `confirmed` — the UI asks first. Moving away from `card` nulls the card
/// fields and moving to `card` demands them, both via
/// [AccountDraft.validated].
@injectable
class UpdateAccount {
  const UpdateAccount(this._repository);

  /// `ValidationFailure.field` returned when the change needs the user's
  /// explicit confirmation.
  static const String confirmationField = 'typeOrCurrencyChange';

  final AccountRepository _repository;

  FutureResult<Account> call(
    AccountDraft draft, {
    bool confirmed = false,
  }) async {
    final id = draft.id;
    if (id == null) {
      return const Left(
        ValidationFailure(
          'cannot update an account without an id',
          field: AccountDraft.fieldId,
        ),
      );
    }

    final AccountDraft normalized;
    switch (draft.validated()) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final validated):
        normalized = validated;
    }

    final Account existing;
    switch (await _repository.getAccount(id)) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final account):
        existing = account;
    }

    final changesTypeOrCurrency = existing.type != normalized.type ||
        existing.currency != normalized.currency;
    if (changesTypeOrCurrency && !confirmed) {
      switch (await _repository.hasTransactions(id)) {
        case Left(value: final failure):
          return Left(failure);
        case Right(value: true):
          return const Left(
            ValidationFailure(
              'changing type or currency on an account with transactions '
              'needs explicit confirmation',
              field: confirmationField,
            ),
          );
        case Right():
          break;
      }
    }

    return _repository.updateAccount(normalized);
  }
}
