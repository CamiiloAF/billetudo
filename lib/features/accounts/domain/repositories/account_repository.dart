import '../../../../core/error/result.dart';
import '../entities/account.dart';
import '../entities/account_deletion_impact.dart';
import '../entities/account_draft.dart';
import '../entities/account_with_balance.dart';

/// Contract the Accounts feature depends on. Implemented in `data/` over Drift
/// (source of truth) plus the device's secure storage for the full account
/// number (HU-03).
///
/// Every write updates `updatedAt`, and deletion is logical (`tombstonedAt`).
/// Drafts arriving here are expected to be already validated by a use case.
abstract class AccountRepository {
  /// Active accounts (not archived, not deleted) with their balance, ordered by
  /// `sortOrder`. Re-emits on every relevant change to accounts or
  /// transactions.
  Stream<Result<List<AccountWithBalance>>> watchActiveAccounts();

  /// Archived accounts with their balance, ordered by `sortOrder` (HU-07).
  Stream<Result<List<AccountWithBalance>>> watchArchivedAccounts();

  /// One account with its live balance (HU-04).
  Stream<Result<AccountWithBalance>> watchAccount(String id);

  FutureResult<Account> getAccount(String id);

  /// Persists a new account. The full number, if any, only goes to secure
  /// storage; `accountNumberEnc` stays NULL.
  FutureResult<Account> createAccount(AccountDraft draft);

  /// Updates an existing account (HU-06). Requires `draft.id`.
  FutureResult<Account> updateAccount(AccountDraft draft);

  FutureResult<Unit> setArchived(String id, {required bool archived});

  /// Logical delete (HU-08): sets `tombstonedAt` so the row stays and
  /// `Transactions.accountId` keeps its referent, and wipes the account number
  /// from secure storage.
  FutureResult<Unit> softDeleteAccount(String id);

  /// Rewrites `sortOrder` as a contiguous 0..n-1 sequence in the given order
  /// (HU-09).
  FutureResult<Unit> reorderAccounts(List<String> orderedIds);

  /// Reads the full number from secure storage (HU-03). `null` when there is
  /// none stored.
  FutureResult<String?> readAccountNumber(String id);

  /// What deleting the account would affect (HU-08).
  FutureResult<AccountDeletionImpact> getDeletionImpact(String id);

  /// Whether the account has any active transaction, on either side of a
  /// transfer. Drives the confirmation for a type/currency change (HU-06).
  FutureResult<bool> hasTransactions(String id);

  /// Which figure a card highlights (HU-04). Presentation preference only.
  FutureResult<Unit> setCardBalancePrimary(String id, CardBalanceView view);
}
