import 'package:equatable/equatable.dart';

/// "Ajustar monto — solo el próximo período": the pending fork of a recurring
/// budget, once `BudgetRepository.scheduleBudgetAdjustment` created it.
///
/// Not persisted as its own row — it is inferred from the two budgets the
/// fork creates (see `BudgetRepositoryImpl.getPendingAdjustment`), so this is
/// a read model, not a domain entity with its own id.
class PendingBudgetAdjustment extends Equatable {
  const PendingBudgetAdjustment({
    required this.newAmountMinor,
    required this.effectiveFrom,
    required this.resumeAmountMinor,
    required this.resumeFrom,
  });

  /// The adjusted amount, in effect for exactly one cycle starting
  /// [effectiveFrom].
  final int newAmountMinor;

  /// First day of the next cycle, when [newAmountMinor] takes over.
  final DateTime effectiveFrom;

  /// The original amount the budget resumes to, indefinitely, from
  /// [resumeFrom] onward.
  final int resumeAmountMinor;

  /// First day of the cycle after the adjusted one.
  final DateTime resumeFrom;

  @override
  List<Object?> get props =>
      [newAmountMinor, effectiveFrom, resumeAmountMinor, resumeFrom];
}
