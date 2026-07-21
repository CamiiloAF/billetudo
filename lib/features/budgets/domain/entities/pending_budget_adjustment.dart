import 'package:equatable/equatable.dart';

/// "Ajustar monto — este período": the pending fork of a recurring budget,
/// once `BudgetRepository.scheduleBudgetAdjustment` created it.
///
/// Not persisted as its own row — it is inferred from the budgets the fork
/// creates (see `BudgetRepositoryImpl.getPendingAdjustment`), so this is a
/// read model, not a domain entity with its own id.
class PendingBudgetAdjustment extends Equatable {
  const PendingBudgetAdjustment({
    required this.newAmountMinor,
    required this.effectiveFrom,
    required this.resumeAmountMinor,
    required this.resumeFrom,
  });

  /// The adjusted amount, in effect for the rest of the current cycle,
  /// starting [effectiveFrom].
  final int newAmountMinor;

  /// First day of the current cycle (`currentWindow.start`) when
  /// `currentWindow.index == 0`, or the adjusted fork's own `startDate`
  /// otherwise — either way, the day [newAmountMinor] starts applying.
  final DateTime effectiveFrom;

  /// The original amount the budget resumes to, indefinitely, from
  /// [resumeFrom] onward.
  final int resumeAmountMinor;

  /// First day of the cycle right after the current one
  /// (`nextWindow.start`), when [resumeAmountMinor] takes back over.
  final DateTime resumeFrom;

  @override
  List<Object?> get props =>
      [newAmountMinor, effectiveFrom, resumeAmountMinor, resumeFrom];
}
