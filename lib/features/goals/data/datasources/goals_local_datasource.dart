import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// Drift queries for the Metas feature: `Goals` and `GoalContributions` CRUD,
/// plus the read side of the `Transactions`/`Accounts` rows Metas needs
/// (a transfer a movement mirrors, and an account's balance for HU-12).
///
/// A plain injected class instead of a `@DriftAccessor`, same reasoning as
/// `DebtsLocalDatasource`: no new tables get declared here, so it forces no
/// code regeneration.
///
/// It returns **raw rows**, never sums: the progress rule (derive
/// `savedMinor` from `GoalContributions`) is domain logic with a single home
/// in `GoalProgressCalculator`. SQL only narrows which rows are read.
///
/// Deletion: a goal uses `deletedAt` (reversible trash, HU-10) while active,
/// and `tombstonedAt` (irreversible lápida) only when its trash entry is
/// purged — `Transactions.goalId` may still reference it. `GoalContributions`
/// hide together with their goal in both cases.
@lazySingleton
class GoalsLocalDatasource {
  const GoalsLocalDatasource(this._db);

  final AppDatabase _db;

  Expression<bool> _aliveGoal(Goals g) =>
      g.deletedAt.isNull() & g.tombstonedAt.isNull();

  Expression<bool> _aliveContribution(GoalContributions c) =>
      c.deletedAt.isNull() & c.tombstonedAt.isNull();

  // -- List streams --

  Stream<List<Goal>> watchActiveGoals() => (_db.select(_db.goals)
        ..where((g) => _aliveGoal(g) & g.archivedAt.isNull()))
      .watch();

  Stream<List<Goal>> watchArchivedGoals() => (_db.select(_db.goals)
        ..where((g) => _aliveGoal(g) & g.archivedAt.isNotNull()))
      .watch();

  Stream<List<GoalContribution>> watchActiveContributions() =>
      (_db.select(_db.goalContributions)..where(_aliveContribution)).watch();

  // -- Detail streams (one goal) --

  Stream<Goal?> watchGoal(String id) =>
      (_db.select(_db.goals)..where((g) => g.id.equals(id) & _aliveGoal(g)))
          .watchSingleOrNull();

  Stream<List<GoalContribution>> watchContributions(String goalId) =>
      (_db.select(_db.goalContributions)
            ..where(
              (c) => c.goalId.equals(goalId) & _aliveContribution(c),
            )
            ..orderBy([(c) => OrderingTerm.desc(c.date)]))
          .watch();

  // -- One-shot reads --

  Future<Goal?> getGoal(String id) =>
      (_db.select(_db.goals)..where((g) => g.id.equals(id) & _aliveGoal(g)))
          .getSingleOrNull();

  Future<List<GoalContribution>> getContributions(String goalId) =>
      (_db.select(_db.goalContributions)
            ..where(
              (c) => c.goalId.equals(goalId) & _aliveContribution(c),
            ))
          .get();

  /// A single movement by its own id, for the "Eliminar movimiento" sheets.
  Future<GoalContribution?> getContributionById(String id) =>
      (_db.select(_db.goalContributions)
            ..where((c) => c.id.equals(id) & _aliveContribution(c)))
          .getSingleOrNull();

  Future<List<Goal>> getActiveGoals() => (_db.select(_db.goals)
        ..where((g) => _aliveGoal(g) & g.archivedAt.isNull()))
      .get();

  /// The account row for [accountId], ignoring tombstone/archival — HU-12's
  /// coherence still needs the balance of an account a goal is linked to even
  /// if that account was since archived (only a hard tombstone hides it).
  Future<Account?> getAccount(String accountId) =>
      (_db.select(_db.accounts)
            ..where((a) => a.id.equals(accountId) & a.tombstonedAt.isNull()))
          .getSingleOrNull();

  /// Same as [getAccount] but ignoring the tombstone too — the "cuenta con
  /// lápida" detail state (`XoGzx`) and the movement detail sheet's account
  /// names (`N8Dv2e`) both need to keep naming an account after it was
  /// tombstoned, since the goal/movement still reference its id.
  Future<Account?> getAccountEvenTombstoned(String accountId) =>
      (_db.select(_db.accounts)..where((a) => a.id.equals(accountId)))
          .getSingleOrNull();

  /// Every non-deleted movement touching [accountId], on either side of a
  /// transfer — the same shape `AccountsLocalDatasource` feeds into
  /// `AccountBalance.fromMovements`.
  Future<List<Transaction>> getAccountMovements(String accountId) =>
      (_db.select(_db.transactions)
            ..where(
              (t) =>
                  (t.accountId.equals(accountId) |
                      t.transferAccountId.equals(accountId)) &
                  t.deletedAt.isNull(),
            ))
          .get();

  // -- Writes --

  Future<Goal> insertGoal(GoalsCompanion companion) =>
      _db.into(_db.goals).insertReturning(companion);

  /// HU-01: creates a goal and, when [initialContribution] is provided,
  /// atomically inserts it as the goal's first movement — so the history
  /// never observes a goal without its declared starting progress.
  Future<Goal> insertGoalWithInitialContribution({
    required GoalsCompanion goalCompanion,
    GoalContributionsCompanion? initialContribution,
  }) =>
      _db.transaction(() async {
        final goal = await _db.into(_db.goals).insertReturning(goalCompanion);
        if (initialContribution != null) {
          await _db.into(_db.goalContributions).insertReturning(
                initialContribution.copyWith(goalId: Value(goal.id)),
              );
        }
        return goal;
      });

  /// Every normal edit funnels through here with the "alive" guard: a
  /// trashed goal must not be silently mutated by anything but [restoreGoal].
  Future<Goal?> updateGoal(String id, GoalsCompanion companion) =>
      (_db.update(_db.goals)..where((g) => g.id.equals(id) & _aliveGoal(g)))
          .writeReturning(companion)
          .then((rows) => rows.isEmpty ? null : rows.first);

  /// HU-10: undo from the trash. Guards only `tombstonedAt IS NULL`.
  Future<Goal?> restoreGoal(String id, GoalsCompanion companion) =>
      (_db.update(_db.goals)
            ..where((g) => g.id.equals(id) & g.tombstonedAt.isNull()))
          .writeReturning(companion)
          .then((rows) => rows.isEmpty ? null : rows.first);

  /// HU-10: vaciar la papelera. Only ever applies to an already-trashed goal.
  Future<Goal?> tombstoneGoal(String id, GoalsCompanion companion) =>
      (_db.update(_db.goals)
            ..where(
              (g) =>
                  g.id.equals(id) &
                  g.deletedAt.isNotNull() &
                  g.tombstonedAt.isNull(),
            ))
          .writeReturning(companion)
          .then((rows) => rows.isEmpty ? null : rows.first);

  /// Cascades the goal's soft-delete state onto its `GoalContributions`
  /// (HU-10). `deletedAt: null` restores them.
  Future<void> setContributionsDeletedAt(
    String goalId, {
    required DateTime? deletedAt,
    required int updatedAt,
  }) =>
      (_db.update(_db.goalContributions)
            ..where((c) => c.goalId.equals(goalId) & c.tombstonedAt.isNull()))
          .write(
        GoalContributionsCompanion(
          deletedAt: Value(deletedAt),
          updatedAt: Value(updatedAt),
        ),
      );

  /// Cascades an irreversible tombstone onto the goal's `GoalContributions`
  /// when its trash entry is purged (HU-10). Never called with `null` —
  /// tombstoning has no undo.
  Future<void> setContributionsTombstonedAt(
    String goalId, {
    required DateTime tombstonedAt,
    required int updatedAt,
  }) =>
      (_db.update(_db.goalContributions)..where((c) => c.goalId.equals(goalId)))
          .write(
        GoalContributionsCompanion(
          tombstonedAt: Value(tombstonedAt),
          updatedAt: Value(updatedAt),
        ),
      );

  Future<GoalContribution> insertContribution(
    GoalContributionsCompanion companion,
  ) =>
      _db.into(_db.goalContributions).insertReturning(companion);

  /// Atomically writes a money-moving movement: the transfer `Transaction`
  /// first, then the `GoalContribution` pointing at it.
  Future<(Transaction, GoalContribution)> insertMovementWithTransfer({
    required TransactionsCompanion transactionCompanion,
    required GoalContributionsCompanion Function(String transactionId)
        contributionCompanionBuilder,
  }) =>
      _db.transaction(() async {
        final transaction = await _db
            .into(_db.transactions)
            .insertReturning(transactionCompanion);
        final contribution = await _db.into(_db.goalContributions).insertReturning(
              contributionCompanionBuilder(transaction.id),
            );
        return (transaction, contribution);
      });

  /// Reads a transaction ignoring the goal filter, to validate a link target
  /// (HU-03 "enlazar un movimiento existente").
  Future<Transaction?> getTransaction(String id) => (_db.select(_db.transactions)
        ..where(
          (t) => t.id.equals(id) & t.deletedAt.isNull() & t.tombstonedAt.isNull(),
        ))
      .getSingleOrNull();

  /// HU-08 cascade: the movement (if any) mirroring [transactionId].
  Future<GoalContribution?> getContributionByTransaction(String transactionId) =>
      (_db.select(_db.goalContributions)
            ..where(
              (c) =>
                  c.transactionId.equals(transactionId) & _aliveContribution(c),
            ))
          .getSingleOrNull();

  /// HU-08 cascade: keeps the mirrored movement's amount in sync when its
  /// backing transaction is edited.
  Future<void> updateContributionAmountForTransaction({
    required String transactionId,
    required int amountMinor,
    required int updatedAt,
  }) =>
      (_db.update(_db.goalContributions)
            ..where(
              (c) =>
                  c.transactionId.equals(transactionId) & _aliveContribution(c),
            ))
          .write(
        GoalContributionsCompanion(
          amountMinor: Value(amountMinor),
          updatedAt: Value(updatedAt),
        ),
      );

  /// HU-08 cascade: removes the mirrored movement when its backing
  /// transaction is deleted. A hard delete — nothing else references a
  /// `GoalContribution`'s own id, so there is no lápida to protect here.
  Future<void> deleteContributionForTransaction(String transactionId) =>
      (_db.delete(_db.goalContributions)
            ..where((c) => c.transactionId.equals(transactionId)))
          .go();

  /// The "Eliminar movimiento" sheets for a tracking-only movement
  /// (`GoalRepository.removeContribution`): reversible trash via
  /// `deletedAt`, same rule as everything else in this feature.
  Future<void> softDeleteContribution(
    String id, {
    required DateTime deletedAt,
    required int updatedAt,
  }) =>
      (_db.update(_db.goalContributions)
            ..where((c) => c.id.equals(id) & _aliveContribution(c)))
          .write(
        GoalContributionsCompanion(
          deletedAt: Value(deletedAt),
          updatedAt: Value(updatedAt),
        ),
      );

  /// The "Editar movimiento" sheet's write for a tracking-only movement
  /// (`GoalRepository.updateContribution`): rewrites amount/date/note in
  /// place on the same row. Restricted to `transactionId IS NULL` — a
  /// money-moving movement is guarded against at the repository layer, but
  /// the `WHERE` here is a second line of defense so this can never silently
  /// rewrite one even if that guard is ever skipped.
  Future<void> updateContributionFields(
    String id, {
    required int amountMinor,
    required DateTime date,
    required String? note,
    required int updatedAt,
  }) =>
      (_db.update(_db.goalContributions)
            ..where(
              (c) =>
                  c.id.equals(id) &
                  c.transactionId.isNull() &
                  _aliveContribution(c),
            ))
          .write(
        GoalContributionsCompanion(
          amountMinor: Value(amountMinor),
          date: Value(date),
          note: Value(note),
          updatedAt: Value(updatedAt),
        ),
      );
}
