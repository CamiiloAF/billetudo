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

  @override
  List<Object?> get props => [currency, incomeMinor, assignedMinor];
}
