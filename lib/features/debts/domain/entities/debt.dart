import 'package:equatable/equatable.dart';

/// Which way a debt points. Mirrors `DebtDirection` stored as text in Drift,
/// declared here so the domain never depends on the database layer.
///  - `iOwe`: money the user owes to someone (a bank, a friend).
///  - `owedToMe`: money someone owes the user (a loan the user gave).
enum DebtDirection { iOwe, owedToMe }

/// How a debt's outstanding balance grows over time. Mirrors
/// `DebtAccrualMode`.
///  - `manual` (default): the user keeps the figure current by hand via
///    "actualizar saldo" (a `manualAdjustment` ledger entry).
///  - `auto`: the app posts `interestAccrual` entries from the debt's rate.
enum DebtAccrualMode { manual, auto }

/// A debt or loan, in either direction (`iOwe` / `owedToMe`).
///
/// Pure domain entity: no Drift types, no `double`. Every money field is an
/// integer of minor units (cents). The outstanding balance is **never** stored
/// here — it is derived from the ledger (opening [principalMinor] + the debt's
/// `DebtEntry`s + the `Transaction`s that carry its id). See
/// `docs/requirements/fase-1/08-deudas.md` and `DebtBalanceCalculator`.
class Debt extends Equatable {
  const Debt({
    required this.id,
    required this.name,
    required this.direction,
    required this.principalMinor,
    required this.currency,
    required this.accrualMode,
    required this.createdAt,
    required this.updatedAt,
    this.startDate,
    this.counterparty,
    this.dueDate,
    this.interestRateBps,
    this.deletedAt,
    this.initialTransactionId,
    this.closedAt,
  });

  /// UUID as text.
  final String id;

  final String name;
  final DebtDirection direction;

  /// Opening balance in cents (the figure the debt had before it was tracked
  /// in the app). Non-negative. May be 0 when the whole balance is built from
  /// ledger events instead of an opening figure.
  final int principalMinor;

  /// ISO-4217 code, e.g. 'COP', 'USD'.
  final String currency;

  final DebtAccrualMode accrualMode;

  /// The date the debt started (its first day), distinct from [createdAt] (when
  /// the row was recorded). It floors every backdated event: an abono, a
  /// balance reconciliation or a linked movement can be dated on or after this
  /// day but never before it, and it is the date the opening `registro inicial`
  /// movement carries. Nullable only because the PowerSync view constraint
  /// forbids a Drift default (decision #14); the repository stamps it on every
  /// insert and old rows were backfilled to `createdAt`, so treat a `null` as
  /// [createdAt] via [effectiveStartDate].
  final DateTime? startDate;

  /// Optional label for the other party ('Banco Bogotá', 'Juan Pérez').
  final String? counterparty;

  final DateTime? dueDate;

  /// Annual interest rate in whole basis points (24.5% -> 2450), optional.
  /// Never `double`: a scaled percentage, not an amount.
  final int? interestRateBps;

  final DateTime createdAt;

  /// Epoch millis, not a `DateTime` (schema v5) — see `_SyncColumns.updatedAt`.
  final int updatedAt;

  /// Soft-delete trash timestamp (HU-05). null = active. Reversible via
  /// `RestoreDebt`; never `tombstonedAt` (the debt is restorable by design).
  final DateTime? deletedAt;

  /// When set, the debt's opening balance is not [principalMinor] (which is 0)
  /// but a real `Transaction` — the "registro inicial" (item 2): a disbursement
  /// carrying this debt's id that moved the chosen account. The outstanding
  /// balance is derived from that movement, so it is never double-counted with
  /// [principalMinor]. `null` = classic debt whose opening lives in
  /// [principalMinor] with no linked movement.
  final String? initialTransactionId;

  /// Manual-closure business-state timestamp (extension, HU-07). `null` =
  /// active. Set once, either by the user from the overflow menu (with a
  /// balance still pending, frozen thereafter) or by the "Completar" button of
  /// the felicitación sheet (once the balance reached 0). Distinct from
  /// [deletedAt] (reversible trash) and `tombstonedAt` (referential lápida):
  /// closing is neither — it is a status change that moves the debt from
  /// "Activas" to "Cerradas" without hiding it or touching its history.
  final DateTime? closedAt;

  /// The debt's floor date, defaulting defensively to [createdAt] when
  /// [startDate] is `null` (an unbackfilled legacy row).
  DateTime get effectiveStartDate => startDate ?? createdAt;

  bool get isTrashed => deletedAt != null;

  /// Whether the opening balance is backed by a linked `Transaction`.
  bool get hasInitialMovement => initialTransactionId != null;

  /// Whether the debt was manually closed (extension, HU-07). A closed debt
  /// accepts no further writes (abonos, ajustes, cuotas) — see
  /// `CloseDebt`/`RegisterDebtCashEvent` and friends.
  bool get isClosed => closedAt != null;

  @override
  List<Object?> get props => [
        id,
        name,
        direction,
        principalMinor,
        currency,
        accrualMode,
        startDate,
        counterparty,
        dueDate,
        interestRateBps,
        createdAt,
        updatedAt,
        deletedAt,
        initialTransactionId,
        closedAt,
      ];
}
