import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/debt.dart';
import '../entities/debt_draft.dart';
import '../repositories/debt_repository.dart';

/// Item 2 ("Sí, elegir cuenta"): creates a debt together with an opening
/// movement (registro inicial).
///
/// Validation (name, currency, non-negative figures) lives in
/// [DebtDraft.validated]; on top of it this use case requires a **positive**
/// opening magnitude — a registro of 0 would move nothing. The concrete
/// income/expense of the movement is resolved by the repository from the debt's
/// direction, so a caller never picks it.
@injectable
class CreateDebtWithOpeningMovement {
  const CreateDebtWithOpeningMovement(this._repository);

  final DebtRepository _repository;

  FutureResult<Debt> call({
    required DebtDraft draft,
    required String accountId,
    required DateTime date,
  }) =>
      draft.validated().fold<FutureResult<Debt>>(
        (failure) async => Left(failure),
        (validated) async {
          if (validated.principalMinor <= 0) {
            return const Left(
              ValidationFailure(
                'an opening movement needs a positive amount',
                field: DebtDraft.fieldPrincipalMinor,
              ),
            );
          }
          if (accountId.trim().isEmpty) {
            return const Left(
              ValidationFailure('an account is required', field: 'accountId'),
            );
          }
          return _repository.createDebtWithOpeningMovement(
            draft: validated,
            accountId: accountId,
            date: date,
          );
        },
      );
}
