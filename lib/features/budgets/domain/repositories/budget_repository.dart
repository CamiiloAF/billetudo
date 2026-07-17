import '../../../../core/error/result.dart';
import '../entities/budget.dart';
import '../entities/budget_detail_data.dart';
import '../entities/budget_draft.dart';
import '../entities/budget_with_progress.dart';
import '../entities/zero_based_summary.dart';

/// Contract the Budgets feature depends on. Implemented in `data/` over Drift
/// (source of truth). Every write updates `updatedAt`; the scope join rows are
/// synced on create/edit (a removed referent is soft-deleted on its own row).
///
/// Deletion is TWO separate concepts here: [closeBudget] stamps `archivedAt`
/// (history, reversible via [reactivateBudget]) and [deleteBudget] stamps
/// `deletedAt` (trash). Budgets never use `tombstonedAt` — nothing references
/// `Budgets.id` by FK.
abstract class BudgetRepository {
  /// Active budgets (not archived, not trashed) with their current-period
  /// progress, newest first. Re-emits on any change to budgets, their scope or
  /// transactions (HU-04).
  Stream<Result<List<BudgetWithProgress>>> watchActiveBudgets();

  /// Closed budgets (`archivedAt` not null), with the progress of the period
  /// they were closed in, ordered by close date desc (HU-11).
  Stream<Result<List<BudgetWithProgress>>> watchArchivedBudgets();

  /// Everything the detail screen needs for [id]: the budget, its scope and the
  /// eligible expenses (HU-04/HU-05).
  Stream<Result<BudgetDetailData>> watchBudgetDetail(String id);

  /// HU-06: the "Modo sobres" summary (income of the current calendar month
  /// minus what is assigned to active budgets). Emits `null` when there is
  /// nothing to show. Re-emits on any change to budgets or income transactions.
  Stream<Result<ZeroBasedSummary?>> watchZeroBasedSummary();

  FutureResult<Budget> getBudget(String id);

  /// Persists a new budget and its scope join rows (HU-01). Draft is expected
  /// validated.
  FutureResult<Budget> createBudget(BudgetDraft draft);

  /// Updates an existing budget and reconciles its scope (HU-09). Requires
  /// `draft.id`.
  FutureResult<Budget> updateBudget(BudgetDraft draft);

  /// HU-10: stamps `archivedAt` (close to history).
  FutureResult<Unit> closeBudget(String id);

  /// HU-10: clears `archivedAt` (back to active).
  FutureResult<Unit> reactivateBudget(String id);

  /// HU-11: stamps `deletedAt` (reversible trash).
  FutureResult<Unit> deleteBudget(String id);
}
