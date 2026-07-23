import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/debt.dart';
import '../entities/debt_draft.dart';
import '../repositories/debt_repository.dart';

/// HU-01: creates a debt. Validation (name required, non-negative opening
/// balance, 3-letter currency, non-negative rate) lives in
/// [DebtDraft.validated]; the repository only persists what passed it.
@injectable
class CreateDebt {
  const CreateDebt(this._repository);

  final DebtRepository _repository;

  FutureResult<Debt> call(DebtDraft draft) =>
      draft.validated().fold<FutureResult<Debt>>(
            (failure) async => Left(failure),
            _repository.createDebt,
          );
}
