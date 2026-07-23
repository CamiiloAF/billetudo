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
  });

  /// A zeroed balance, for a debt with no principal and no events.
  static const DebtBalance empty = DebtBalance(
    principalMinor: 0,
    totalIncreasesMinor: 0,
    totalDecreasesMinor: 0,
    interestAccruedMinor: 0,
  );

  final int principalMinor;

  /// Everything that pushed the debt up: the opening principal + every
  /// disbursement (cash or ledger) + accrued interest + upward adjustments.
  final int totalIncreasesMinor;

  /// Everything that pushed the debt down: every abono/cuota (cash or ledger) +
  /// downward adjustments (as a positive magnitude).
  final int totalDecreasesMinor;

  /// The subset of increases that is interest (for the "estimado" label).
  final int interestAccruedMinor;

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
      ];
}
