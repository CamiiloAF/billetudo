import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/debt.dart';
import '../entities/debt_entry.dart';
import '../entities/debt_entry_draft.dart';
import '../repositories/debt_repository.dart';
import '../services/debt_interest_calculator.dart';

/// HU-06 (auto mode, Fase 0 opcional): posts the interest that accrued between
/// the last accrual (or the debt's creation) and `upTo`, as an `interestAccrual`
/// entry — a solo-deuda event that grows the debt but touches no account.
///
/// Interest is "estimado": it compounds daily on the raw outstanding at the
/// debt's fixed rate (see [DebtInterestCalculator]). A `null` result means
/// nothing was posted (no auto mode, no rate, no days elapsed, or nothing owed).
@injectable
class AccrueInterest {
  const AccrueInterest(this._repository, this._calculator);

  final DebtRepository _repository;
  final DebtInterestCalculator _calculator;

  FutureResult<DebtEntry?> call({
    required String debtId,
    required DateTime upTo,
  }) async {
    final contextResult = await _repository.getAccrualContext(debtId);
    return contextResult.fold<FutureResult<DebtEntry?>>(
      (failure) async => Left(failure),
      (context) async {
        final debt = context.debt;
        if (debt.isClosed) {
          return const Left(
            ValidationFailure(
              'a closed debt no longer accrues interest',
              field: 'closedAt',
            ),
          );
        }
        if (debt.accrualMode != DebtAccrualMode.auto) {
          return const Left(
            ValidationFailure(
              'interest only accrues automatically in auto mode',
              field: 'accrualMode',
            ),
          );
        }
        final rateBps = debt.interestRateBps;
        if (rateBps == null || rateBps <= 0) {
          return const Left(
            ValidationFailure(
              'auto accrual needs a positive interest rate',
              field: 'interestRateBps',
            ),
          );
        }

        // The days/interest figures are recomputed against the transaction's
        // own fresh read of `lastAccrualDate`/outstanding, not this initial
        // `context` — two concurrent calls to `call()` would otherwise both
        // compute the same interest from the same stale snapshot and each
        // post their own `interestAccrual` row for the same span. The
        // atomic re-read+write below (a single Drift transaction) makes a
        // second concurrent caller see the first one's write and naturally
        // post nothing (or a smaller remainder) instead of duplicating it.
        // The debt-state validations above are not repeated here — they do
        // not change across a concurrent accrual.
        return _repository.accrueInterestAtomic(
          debtId: debtId,
          buildEntry: (freshContext) {
            final base = freshContext.lastAccrualDate ?? debt.createdAt;
            final days = upTo.difference(base).inDays;
            final interest = _calculator.accruedInterestMinor(
              balanceMinor: freshContext.rawOutstandingMinor,
              rateBps: rateBps,
              days: days,
            );
            if (interest <= 0) return null;
            return DebtEntryDraft(
              debtId: debtId,
              kind: DebtEntryKind.interestAccrual,
              amountMinor: interest,
              entryDate: upTo,
              rateBpsSnapshot: rateBps,
            );
          },
        );
      },
    );
  }
}
