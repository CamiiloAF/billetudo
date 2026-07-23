import 'package:equatable/equatable.dart';

/// The nature of a single **solo-deuda** ledger entry (one that does NOT move
/// any account). Mirrors `DebtEntryKind` stored as text in Drift.
///
/// Cash abonos/desembolsos are NOT here — those are a `Transaction` carrying
/// the debt's id (they move an account). These four never touch a balance or a
/// budget: they only change how much is owed.
///  - `interestAccrual`: interest posted (auto or by hand). Always increases (+).
///  - `manualAdjustment`: reconciliation to the real figure ("actualizar
///    saldo"); signed either way (±).
///  - `payment`: a cash-less abono (HU-02 toggle "No"). Reduces the debt (−).
///  - `disbursement`: a cash-less desembolso (HU-02 toggle "No"). Increases (+).
enum DebtEntryKind { interestAccrual, manualAdjustment, payment, disbursement }

/// A signed ledger entry against a debt. Pure domain entity.
///
/// [amountMinor] is **signed**: a positive value increases the debt, a negative
/// value reduces it. The outstanding balance is derived by summing entries (and
/// the cash `Transaction`s and the principal), so there is deliberately no
/// stored balance. See `DebtBalanceCalculator`.
class DebtEntry extends Equatable {
  const DebtEntry({
    required this.id,
    required this.debtId,
    required this.kind,
    required this.amountMinor,
    required this.entryDate,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.rateBpsSnapshot,
    this.deletedAt,
  });

  /// UUID as text.
  final String id;

  final String debtId;
  final DebtEntryKind kind;

  /// Signed integer of cents: + increases the debt, − reduces it.
  final int amountMinor;

  final DateTime entryDate;
  final String? note;

  /// The rate (whole basis points) used to compute this entry when it is an
  /// accrual. Audit/display snapshot; null otherwise.
  final int? rateBpsSnapshot;

  final DateTime createdAt;

  /// Epoch millis, not a `DateTime` — see `_SyncColumns.updatedAt`.
  final int updatedAt;

  /// Solo-deuda entries are hidden together with their debt when it is trashed
  /// (HU-05). null = active.
  final DateTime? deletedAt;

  @override
  List<Object?> get props => [
        id,
        debtId,
        kind,
        amountMinor,
        entryDate,
        note,
        rateBpsSnapshot,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
