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

  /// Everything that pushed the debt down since the debt's origin: every
  /// abono/cuota (cash or ledger) + downward adjustments (as a positive
  /// magnitude). Historical, same lifetime scope as [totalIncreasesMinor].
  final int totalDecreasesMinor;

  /// The subset of increases that is interest (for the "estimado" label).
  final int interestAccruedMinor;

  /// What the hero/card show as "de $X": the total against which the current
  /// balance is measured. Always equal to [totalIncreasesMinor] — the full
  /// lifetime total (opening principal + every disbursement/interest/upward
  /// adjustment). A balance reconciliation (`manualAdjustment` written by
  /// `UpdateDebtBalance`, HU-06) never resets it: a downward correction is a
  /// decrease (it lowers what is pending, exactly like an abono, but leaves
  /// the total the user originally owed untouched); an upward correction is
  /// an increase (new debt discovered at reconciliation time, so it correctly
  /// grows the total). Kept as its own field, not a mere alias, because a
  /// previous version of this logic *did* reset it after a reconciliation —
  /// that reset made "actualizar saldo" also silently rewrite how much was
  /// ever borrowed, which is a different, wrong thing to correct (see the
  /// dev-run bug fix for the exact scenario this reverted).
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

  /// "pagado / total" as a 0..1 fraction — the emotional core of the feature
  /// (HU-04). total = everything that increased the debt, paid = everything
  /// that reduced it. A debt with no increases reads 100% when settled, else 0.
  double get progress {
    if (totalIncreasesMinor <= 0) return settled ? 1 : 0;
    final raw = totalDecreasesMinor / totalIncreasesMinor;
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
