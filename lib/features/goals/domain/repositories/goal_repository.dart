import '../../../../core/error/result.dart';
import '../entities/goal.dart';
import '../entities/goal_contribution.dart';
import '../entities/goal_contribution_draft.dart';
import '../entities/goal_detail.dart';
import '../entities/goal_draft.dart';
import '../entities/goal_movement_accounts.dart';
import '../entities/goal_with_progress.dart';

/// Contract the Metas feature depends on. Implemented in `data/` over Drift
/// (source of truth).
///
/// Every write stamps `updatedAt`. `savedMinor` is never written directly —
/// it is always derived from `GoalContribution`s by `GoalProgressCalculator`.
/// Deletion is the reversible UX trash (`deletedAt`, HU-10); vaciar la
/// papelera uses [purgeGoal] (`tombstonedAt`) instead of a physical delete,
/// because `Transactions.goalId` references a goal's id.
abstract class GoalRepository {
  /// Reactive list of active (non-archived, non-trashed) goals with their
  /// derived progress, ordered per HU-11 (nearest `targetDate` first, then no
  /// date, then completed-not-archived last), each carrying its HU-12
  /// coherence signal when applicable.
  Stream<Result<List<GoalWithProgress>>> watchGoals();

  /// Reactive list of archived goals (HU-09), same shape as [watchGoals].
  Stream<Result<List<GoalWithProgress>>> watchArchivedGoals();

  /// Reactive detail for one goal: progress, projection (HU-05), momentum
  /// (HU-15) and its movement history. Emits `NotFoundFailure` when the goal
  /// does not exist or is trashed.
  Stream<Result<GoalDetail>> watchGoalDetail(String goalId);

  /// One-shot read of a goal. `NotFoundFailure` when missing/trashed.
  FutureResult<Goal> getGoal(String id);

  /// One-shot derived `savedMinor` (HU-04's withdrawal cap needs this without
  /// subscribing to the whole detail stream).
  FutureResult<int> getSavedMinor(String goalId);

  /// Whether the goal has at least one non-hidden movement (HU-02's "cambiar
  /// de cuenta de otra moneda se bloquea si la meta ya tiene movimientos").
  FutureResult<bool> hasContributions(String goalId);

  /// Creates a goal (HU-01). The draft must already be `validated()`. When
  /// `draft.initialSavedMinor` is set and > 0, atomically inserts it as the
  /// first `GoalContribution` (never a stored value).
  FutureResult<Goal> createGoal(GoalDraft draft);

  /// Updates a goal (HU-08). Requires `draft.id`. Recomputes
  /// `completedAt`/`lastMilestonePct` against the new `targetMinor` (HU-06
  /// reconciliation, HU-07 raise/lower rules) but never rewrites any
  /// `GoalContribution`.
  FutureResult<Goal> updateGoal(GoalDraft draft);

  /// HU-09: fija `archivedAt`.
  FutureResult<Unit> archiveGoal(String id);

  /// HU-09: limpia `archivedAt`.
  FutureResult<Unit> unarchiveGoal(String id);

  /// HU-10: logical delete via `deletedAt` (papelera/undo).
  FutureResult<Unit> deleteGoal(String id);

  /// HU-10: undo from the trash. Clears `deletedAt`.
  FutureResult<Unit> restoreGoal(String id);

  /// HU-10: vaciar la papelera. Sets `tombstonedAt` instead of a physical
  /// delete — `Transactions.goalId` may still reference this row. Its
  /// `GoalContribution`s are hidden alongside it; the transactions they
  /// mirrored are left untouched.
  FutureResult<Unit> purgeGoal(String id);

  /// HU-03: registers an aporte. The returned `int?` is the single milestone
  /// threshold newly crossed (HU-06), or `null` when none was.
  FutureResult<(GoalContribution, int?)> contribute(
    GoalContributionDraft draft,
  );

  /// HU-04: registers a retiro. Same shape as [contribute]; the draft's
  /// `direction` must already be `withdrawal`.
  FutureResult<(GoalContribution, int?)> withdraw(
    GoalContributionDraft draft,
  );

  /// HU-03 "Enlazar un movimiento existente": attributes an existing
  /// `Transaction` to a goal by creating a `GoalContribution` that points at
  /// it, without creating a new transaction.
  FutureResult<GoalContribution> linkExistingTransaction({
    required String goalId,
    required String transactionId,
    required GoalMovementDirection direction,
    String? note,
  });

  /// HU-08 cascade: keeps a movement's mirrored `GoalContribution` amount in
  /// sync when the `Transaction` backing it (`transactionId`) is edited.
  /// Orchestrated from `TransactionRepository`, since that is where a
  /// transaction's amount actually changes. No-op when no contribution
  /// references [transactionId].
  FutureResult<Unit> syncContributionForTransactionAmount({
    required String transactionId,
    required int amountMinor,
  });

  /// HU-08 cascade: removes the `GoalContribution` that mirrored
  /// [transactionId] when that transaction is deleted. No-op when none does.
  FutureResult<Unit> removeContributionForTransaction(String transactionId);

  /// The Sheet detalle del movimiento (`N8Dv2e`)'s "Cuenta de origen"/
  /// "Transferencia" rows: the origin/destination account names of the
  /// `Transaction` a money-moving movement mirrors. `null` when
  /// [transactionId] does not resolve to a transaction (should not happen for
  /// a live movement) or either account row is missing entirely.
  FutureResult<GoalMovementAccounts?> getMovementAccounts(String transactionId);

  /// Deletes a single movement from a goal's ledger (the "Eliminar
  /// movimiento" sheets, `arr2T`/`H2ND7O`/`xCNxM`): reversible via
  /// `deletedAt`, same trash convention as everything else, but its effect on
  /// the goal's derived state is a rewrite of history, unlike
  /// [withdraw]/[contribute] which only ever add new events. Only for a
  /// tracking-only [GoalContribution] (`transactionId == null`) —
  /// a money-moving one must be removed by deleting its `Transaction`
  /// instead (`TransactionRepository.deleteTransaction`, which cascades here
  /// via [removeContributionForTransaction]), so the transfer and its
  /// account balances unwind together.
  ///
  /// Unlike a normal contribution/withdrawal, this can move `completedAt`
  /// **backwards**: deleting a movement that completed the goal reverts it
  /// to in-progress, because this is a correction of history, not a new
  /// event (HU-07's "never clears on a withdrawal" rule does not apply here).
  FutureResult<Unit> removeContribution(String contributionId);

  /// A single movement by its own id, for `UpdateGoalMovement`: reads its
  /// current `transactionId`/`direction`/`amountMinor` before rewriting it,
  /// so the use case can reject a money-moving movement and re-check the
  /// negative-`savedMinor` invariant excluding this movement's previous
  /// amount.
  FutureResult<GoalContribution> getContribution(String contributionId);

  /// The "Editar movimiento" sheet for a tracking-only movement
  /// (`transactionId == null`): rewrites `amountMinor`/`date`/`note` on the
  /// SAME `GoalContribution` row — no delete, no new row, unlike
  /// [contribute]/[withdraw]. Like [removeContribution], this is a rewrite of
  /// history, so it reconciles `completedAt`/`lastMilestonePct`
  /// bidirectionally (can move either forward or backward), not the
  /// forward-only rule a fresh [contribute]/[withdraw] applies.
  ///
  /// A money-moving movement (`transactionId != null`) is rejected with a
  /// `ValidationFailure` — it must be edited through its `Transaction`
  /// instead, same restriction as [removeContribution].
  FutureResult<Unit> updateContribution({
    required String contributionId,
    required int amountMinor,
    required DateTime date,
    String? note,
  });
}
