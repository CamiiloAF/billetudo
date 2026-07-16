import 'package:injectable/injectable.dart';

import '../entities/transaction.dart';
import '../entities/transaction_draft.dart';
import '../entities/transaction_edit_impact.dart';

/// HU-04: evaluates whether the change proposed by a draft would desync a
/// transaction from the recurring template, goal or debt it is linked to, so
/// the form can warn the user *before* the edit is confirmed.
///
/// A pure computation over the two entities the caller already holds (the
/// original transaction and the pending draft) — no repository round trip
/// needed, since both linked relations are identified by ids already present
/// on the original transaction.
///
/// The rule: a link is affected when a field that would make it no longer
/// apply as-is changes.
///  - `recurringId`: any change to amount, account or type breaks the
///    template match.
///  - `goalId` / `debtId`: a change to amount or account breaks the
///    contribution/payment they were tracking.
@injectable
class GetTransactionEditImpact {
  const GetTransactionEditImpact();

  TransactionEditImpact call({
    required Transaction original,
    required TransactionDraft draft,
  }) {
    final amountChanged = draft.amountMinor != original.amountMinor;
    final accountChanged = draft.accountId != original.accountId;
    final typeChanged = draft.type != original.type;

    return TransactionEditImpact(
      affectsRecurring: original.recurringId != null &&
          (amountChanged || accountChanged || typeChanged),
      affectsGoal: original.goalId != null && (amountChanged || accountChanged),
      affectsDebt: original.debtId != null && (amountChanged || accountChanged),
    );
  }
}
