import 'package:equatable/equatable.dart';

/// The derived state of a debt at a point in time. Never stored: produced by
/// `DebtBalanceCalculator` from the opening principal + the ledger.
///
/// The raw sum can go below zero (the user over-paid); the balance shown to the
/// user is clamped to 0 and the debt is flagged [settled], with the overpayment
/// surfaced as [excessMinor] (HU-02/HU-07).
class DebtBalance extends Equatable {
  const DebtBalance({
    required this.principalMinor,
    required this.totalIncreasesMinor,
    required this.totalDecreasesMinor,
    required this.interestAccruedMinor,
    required this.displayTotalMinor,
  });

  /// A zeroed balance, for a debt with no principal and no events.
  static const DebtBalance empty = DebtBalance(
    principalMinor: 0,
    totalIncreasesMinor: 0,
    totalDecreasesMinor: 0,
    interestAccruedMinor: 0,
    displayTotalMinor: 0,
  );

  final int principalMinor;

  /// Everything that pushed the debt up since the debt's origin: the opening
  /// principal + every disbursement (cash or ledger) + accrued interest +
  /// upward adjustments. Historical, never resets — feeds [rawOutstandingMinor]
  /// and anything that needs the true lifetime figure (e.g. the "total
  /// pagado/cobrado" summaries), so its invariant with [totalDecreasesMinor]
  /// must hold regardless of any reconciliation in between.
  final int totalIncreasesMinor;

  /// Alias of [displayTotalMinor] under the name [progress] actually uses as
  /// its denominator — kept as a separate getter (not the field itself) so
  /// call sites can read either name for what they mean: "the capital total"
  /// in domain code, "what shows as de $X" in presentation. Cannot be derived
  /// from [totalIncreasesMinor] minus [interestAccruedMinor] alone: it also
  /// excludes `manualAdjustment` (reconciliation) entries regardless of sign
  /// — see [displayTotalMinor]'s doc — so `DebtBalanceCalculator` computes it
  /// directly instead of this getter re-deriving it.
  int get capitalTotalMinor => displayTotalMinor;

  /// Everything that pushed the debt down since the debt's origin: every
  /// abono/cuota (cash or ledger) + downward adjustments (as a positive
  /// magnitude). Historical, same lifetime scope as [totalIncreasesMinor].
  final int totalDecreasesMinor;

  /// The subset of increases that is interest (for the "estimado" label).
  final int interestAccruedMinor;

  /// What the hero/card show as "de $X": the total against which the current
  /// balance is measured. As of the "Capital vs Interés separado" variant
  /// (`design-system/billetudo/pages/deudas.md`, 2026-08-19) this is the
  /// **capital total**: the opening principal + every real disbursement/abono
  /// (cash or ledger) — it excludes BOTH the interest portion AND any
  /// `manualAdjustment` (reconciliation, `UpdateDebtBalance`/HU-06)
  /// regardless of sign. A reconciliation only ever corrects what is
  /// *pending* against the bank's real figure — it is never new capital
  /// borrowed, so "Actualizar saldo" must never move this number in either
  /// direction, only [outstandingMinor]. (An earlier version let an upward
  /// reconciliation grow this total, treating it as "new debt discovered" —
  /// reverted: it made "de $X" drift away from the debt's actual saldo de
  /// apertura, which the user expects to never move on its own unless they
  /// explicitly edit it.) The lifetime total (capital + interest +
  /// reconciliations) is still available via [totalIncreasesMinor] for
  /// anything that needs the true historical figure, e.g. [rawOutstandingMinor].
  final int displayTotalMinor;

  /// Signed running balance. May be negative when abonos exceed what is owed;
  /// that surplus is [excessMinor]. Used by reconciliation ("actualizar saldo")
  /// so the adjustment is exact even past 0.
  int get rawOutstandingMinor => totalIncreasesMinor - totalDecreasesMinor;

  /// What the user is shown: never negative (HU-02).
  int get outstandingMinor =>
      rawOutstandingMinor < 0 ? 0 : rawOutstandingMinor;

  /// A debt is settled once nothing more is owed (HU-07): the raw balance
  /// reached 0 or went below.
  bool get settled => rawOutstandingMinor <= 0;

  /// The overpayment amount when abonos exceeded the balance; 0 otherwise.
  int get excessMinor =>
      rawOutstandingMinor < 0 ? -rawOutstandingMinor : 0;

  /// "pagado / capital" as a 0..1 fraction — the emotional core of the
  /// feature (HU-04). As of the "Capital vs Interés separado" variant the
  /// denominator is [capitalTotalMinor], not the lifetime total: interest
  /// accruing by itself must never move this number, or a user who did
  /// nothing wrong watches their progress "regress". The numerator stays
  /// [totalDecreasesMinor] unchanged — an abono is applied 100% to capital,
  /// never split with interest first or pro-rata. That is a deliberate
  /// product decision, not an oversight: the real installment the user pays
  /// already has interest baked into what it disburses, so subtracting
  /// interest from the abono here would double-count it. A debt with no
  /// capital reads 100% when settled, else 0.
  double get progress {
    if (capitalTotalMinor <= 0) return settled ? 1 : 0;
    final raw = totalDecreasesMinor / capitalTotalMinor;
    return raw.clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
        principalMinor,
        totalIncreasesMinor,
        totalDecreasesMinor,
        interestAccruedMinor,
        displayTotalMinor,
      ];
}
