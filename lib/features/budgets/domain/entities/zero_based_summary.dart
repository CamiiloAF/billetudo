import 'package:equatable/equatable.dart';

/// The "Modo sobres" hero figures for one reference currency (HU-06):
/// **income − assigned = unassigned**, all in minor units.
///
/// `unassignedMinor` tends to zero but is never a blocker — it is guidance, not
/// an obstacle. It can be negative (over-assigned) or positive (still to give a
/// job to), and the UI states it in positive, non-punitive terms.
class ZeroBasedSummary extends Equatable {
  const ZeroBasedSummary({
    required this.currency,
    required this.incomeMinor,
    required this.assignedMinor,
  });

  /// ISO-4217 code the three figures are expressed in. Cross-currency sums are
  /// never mixed (Fase 0 multi-currency rule).
  final String currency;

  /// Income of the current calendar month in [currency].
  final int incomeMinor;

  /// Total assigned to active budgets of [currency].
  final int assignedMinor;

  /// What is still unassigned (`income − assigned`). May be negative.
  int get unassignedMinor => incomeMinor - assignedMinor;

  /// Every peso of the income already has a job.
  bool get isAllAssigned => unassignedMinor == 0;

  /// More was assigned than came in. Never a blocker, just a nudge.
  bool get isOverAssigned => unassignedMinor < 0;

  /// How much of the income is already assigned, in `[0, 1]` — what the hero's
  /// progress track (`i9NQn`) fills. With no income there is nothing to split,
  /// so the track stays empty; over-assigning tops it out instead of
  /// overflowing.
  double get assignedFraction {
    if (incomeMinor <= 0 || assignedMinor <= 0) {
      return 0;
    }
    if (assignedMinor >= incomeMinor) {
      return 1;
    }
    return assignedMinor / incomeMinor;
  }

  @override
  List<Object?> get props => [currency, incomeMinor, assignedMinor];
}
