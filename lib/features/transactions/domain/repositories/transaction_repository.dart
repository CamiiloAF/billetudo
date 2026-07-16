import '../../../../core/error/result.dart';
import '../entities/transaction.dart';
import '../entities/transaction_draft.dart';
import '../entities/transaction_filter.dart';
import '../entities/transaction_with_details.dart';

/// Contract the Transactions feature depends on. Implemented in `data/` over
/// Drift (source of truth).
///
/// Every write updates `updatedAt`. Deletion is logical via `deletedAt`
/// (HU-05): the reversible UX trash, never `tombstonedAt` — nothing in this
/// schema references `Transactions.id` by foreign key, so there is no
/// referential-integrity tombstone to protect.
abstract class TransactionRepository {
  /// Filtered, searched and ordered stream (HU-06). Always excludes rows with
  /// `deletedAt != null`. Re-emits on every relevant change.
  Stream<Result<List<TransactionWithDetails>>> watchTransactions(
    TransactionFilter filter,
  );

  /// One transaction with its enriched display data (HU-08). Re-emits on
  /// every relevant change (including its tags).
  Stream<Result<TransactionWithDetails>> watchTransactionDetail(String id);

  FutureResult<Transaction> getTransaction(String id);

  /// Persists a new transaction. `draft.source` is honoured as-is (defaults
  /// to `manual`, HU-01/02/03).
  FutureResult<Transaction> createTransaction(TransactionDraft draft);

  /// Updates an existing transaction (HU-04). Requires `draft.id`. Every
  /// field is written except `source`, which stays whatever it was created
  /// with.
  FutureResult<Transaction> updateTransaction(TransactionDraft draft);

  /// HU-05: logical delete via `deletedAt` (papelera/undo), never
  /// `tombstonedAt`.
  FutureResult<Unit> deleteTransaction(String id);

  /// HU-05: undo from the snackbar. Clears `deletedAt`.
  FutureResult<Unit> restoreTransaction(String id);

  /// HU-07: replaces the full set of tags linked to [transactionId] via
  /// `TransactionTags` with [tagIds] (adds the missing ones, removes the
  /// ones no longer selected).
  FutureResult<Unit> setTransactionTags(
    String transactionId,
    List<String> tagIds,
  );
}
