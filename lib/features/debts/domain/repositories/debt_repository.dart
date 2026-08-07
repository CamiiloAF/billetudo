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

  /// Extension (HU-07): manual closure — a pure status change (`closedAt`),
  /// never a `DebtEntry`. `CloseDebt` guards the "already closed" rule before
  /// calling this.
  FutureResult<Unit> closeDebt(String id);

  /// HU-02 (toggle "Sí"): creates a `Transaction` carrying the debt id, which
  /// moves [accountId] and enters the derived balance. [type]/[currency] are
  /// resolved by the caller from the debt's direction. [countsInBudget]
  /// (budget-income-counts-in-budget) is resolved by the caller too, via
  /// `DebtEventRules.countsInBudgetFor` — `true` only for a repago recibido
  /// (`owedToMe` + `income`), so it raises a covering budget's disponible
  /// without the user touching a toggle.
  FutureResult<Unit> registerCashEvent({
    required String debtId,
    required String accountId,
    required int amountMinor,
    required TransactionType type,
    required String currency,
    required DateTime date,
    required bool countsInBudget,
    String? note,
    String? categoryId,
  });

  /// HU-02 (toggle "No") / HU-06: persists a solo-deuda [DebtEntry] (cash-less
  /// payment/disbursement, interest accrual, or manual adjustment).
  FutureResult<DebtEntry> addDebtEntry(DebtEntryDraft draft);

  /// HU-06: the read-then-write half of `AccrueInterest` that must be atomic.
  /// Re-reads [DebtAccrualContext] and, if [buildEntry] decides something
  /// should post, inserts it — both inside a single Drift transaction, so two
  /// concurrent callers can never both read the same stale
  /// `lastAccrualDate`/outstanding and each post their own `interestAccrual`
  /// row for the same span. [buildEntry] returns `null` to post nothing (e.g.
  /// the freshly re-read context now yields zero or negative interest,
  /// because a just-committed concurrent call already advanced
  /// `lastAccrualDate`). The caller (`AccrueInterest`) is responsible for the
  /// debt-state validations (closed, accrual mode, rate) against its own
  /// initial read — those do not change across a concurrent accrual, so they
  /// stay outside the transaction.
  FutureResult<DebtEntry?> accrueInterestAtomic({
    required String debtId,
    required DebtEntryDraft? Function(DebtAccrualContext context) buildEntry,
  });

  /// HU-02 (Fase 0): attributes an existing `Transaction` to a debt by setting
  /// its `debtId`. The movement already moved its account; this only makes it
  /// count towards the debt's derived balance.
  ///
  /// budget-income-counts-in-budget (criterion 3): when the transaction being
  /// linked is `type = income` and the debt's `direction` is `owedToMe` — the
  /// same "repago recibido" semantics as [registerCashEvent] —
  /// `countsInBudget` is **forced** to `true`, not merely defaulted: linking
  /// an existing income to a debt after the fact means "this was a loan
  /// repayment all along", which should raise a covering budget's disponible
  /// exactly as if the user had used the cash-event flow from the start,
  /// overriding whatever the transaction's toggle held before (most likely
  /// `false`, since nothing suggested it was debt-related yet). Every other
  /// (direction, type) combination leaves `countsInBudget` untouched — linking
  /// alone never flips it off.
  FutureResult<Unit> linkTransactionToDebt({
    required String transactionId,
    required String debtId,
  });
}
