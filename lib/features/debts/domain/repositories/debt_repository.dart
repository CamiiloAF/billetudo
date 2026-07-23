import '../../../../core/error/result.dart';
import '../../../transactions/domain/entities/transaction.dart'
    show TransactionType;
import '../entities/debt.dart';
import '../entities/debt_accrual_context.dart';
import '../entities/debt_balance.dart';
import '../entities/debt_detail.dart';
import '../entities/debt_draft.dart';
import '../entities/debt_entry.dart';
import '../entities/debt_entry_draft.dart';
import '../entities/debts_summary.dart';

/// Contract the Deudas feature depends on. Implemented in `data/` over Drift
/// (source of truth).
///
/// Every write stamps `updatedAt`. Deletion is the reversible UX trash
/// (`deletedAt`, HU-05), never `tombstonedAt`: cash `Transaction`s reference a
/// debt's id, but a soft delete keeps the row alive so those FKs stay valid,
/// and the user can restore it. The outstanding balance is never stored — it is
/// derived by `DebtBalanceCalculator`.
abstract class DebtRepository {
  /// Reactive list of active (non-trashed) debts, each with its derived
  /// balance, plus per-currency totals (HU-04).
  Stream<Result<DebtsSummary>> watchDebts();

  /// Reactive detail for one debt: the debt, its derived balance and its
  /// unified newest-first history (HU-04). Emits `NotFoundFailure` when the
  /// debt does not exist or is trashed.
  Stream<Result<DebtDetail>> watchDebtDetail(String debtId);

  /// One-shot read of a debt (HU-05). `NotFoundFailure` when missing/trashed.
  FutureResult<Debt> getDebt(String id);

  /// One-shot derived balance, for reconciliation and interest accrual.
  FutureResult<DebtBalance> getBalance(String debtId);

  /// The snapshot `AccrueInterest` needs: the debt, its raw outstanding, and
  /// the date interest was last accrued to.
  FutureResult<DebtAccrualContext> getAccrualContext(String debtId);

  /// Creates a debt (HU-01). The draft must already be `validated()`.
  FutureResult<Debt> createDebt(DebtDraft draft);

  /// Item 2: creates a debt **with an opening movement** (registro inicial),
  /// atomically. The debt is stored with `principalMinor == 0` and its opening
  /// balance is persisted as a single `disbursement` `Transaction` carrying the
  /// debt id (moving [accountId] on [date]); `initialTransactionId` then points
  /// at that movement. This keeps the derived balance equal to the opening
  /// figure — never twice it. [draft] carries the opening magnitude in its
  /// `principalMinor`; the repository forces the stored principal to 0.
  FutureResult<Debt> createDebtWithOpeningMovement({
    required DebtDraft draft,
    required String accountId,
    required DateTime date,
  });

  /// Item 2b: keeps a debt's linked opening movement in sync when its opening
  /// figure (or direction) changed on edit. Updates the movement's amount and,
  /// when the direction flipped, its [type] (`income`↔`expense`), stamping
  /// `updatedAt`. When [date] is provided, the movement's date is re-synced to
  /// it too — the registro inicial IS the debt's opening event, so its date must
  /// follow the debt's `startDate` (a silent consistency sync, it moves no
  /// account balance). Only ever called for a debt with an
  /// `initialTransactionId`.
  FutureResult<Unit> updateInitialMovementAmount({
    required String transactionId,
    required int amountMinor,
    required TransactionType type,
    DateTime? date,
  });

  /// Updates a debt (HU-05). Requires `draft.id`. Editing the opening balance
  /// never touches the ledger.
  FutureResult<Debt> updateDebt(DebtDraft draft);

  /// HU-05: logical delete via `deletedAt` (papelera/undo).
  FutureResult<Unit> deleteDebt(String id);

  /// HU-05: undo from the trash. Clears `deletedAt`.
  FutureResult<Unit> restoreDebt(String id);

  /// HU-02 (toggle "Sí"): creates a `Transaction` carrying the debt id, which
  /// moves [accountId] and enters the derived balance. [type]/[currency] are
  /// resolved by the caller from the debt's direction.
  FutureResult<Unit> registerCashEvent({
    required String debtId,
    required String accountId,
    required int amountMinor,
    required TransactionType type,
    required String currency,
    required DateTime date,
    String? note,
    String? categoryId,
  });

  /// HU-02 (toggle "No") / HU-06: persists a solo-deuda [DebtEntry] (cash-less
  /// payment/disbursement, interest accrual, or manual adjustment).
  FutureResult<DebtEntry> addDebtEntry(DebtEntryDraft draft);

  /// HU-02 (Fase 0): attributes an existing `Transaction` to a debt by setting
  /// its `debtId`. The movement already moved its account; this only makes it
  /// count towards the debt's derived balance.
  FutureResult<Unit> linkTransactionToDebt({
    required String transactionId,
    required String debtId,
  });
}
