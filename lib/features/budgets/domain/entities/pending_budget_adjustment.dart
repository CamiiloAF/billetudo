import 'package:equatable/equatable.dart';

/// "Ajustar monto": the pending amount override of a recurring budget for the
/// window the stepper is showing, once
/// `BudgetRepository.scheduleBudgetAdjustment` created it.
///
/// Not persisted as its own row — it is read from the budget's
/// `BudgetPeriodOverride` for the visible window (see
/// `BudgetRepositoryImpl.getPendingAdjustment`), so this is a read model, not a
/// domain entity with its own id.
class PendingBudgetAdjustment extends Equatable {
  const PendingBudgetAdjustment({
    required this.newAmountMinor,
    required this.effectiveFrom,
    required this.resumeAmountMinor,
    required this.resumeFrom,
  });

  /// The adjusted amount, applied only to the visible window, starting
  /// [effectiveFrom].
  final int newAmountMinor;

  /// First day of the adjusted window (`visibleWindow.start`) — the day
  /// [newAmountMinor] starts applying.
  final DateTime effectiveFrom;

  /// The base amount the budget resumes to from [resumeFrom] onward.
  final int resumeAmountMinor;

  /// First day of the cycle right after the adjusted one
  /// (`windowAt(visible.index + 1).start`), when [resumeAmountMinor] takes
  /// back over.
  final DateTime resumeFrom;

  @override
  List<Object?> get props =>
      [newAmountMinor, effectiveFrom, resumeAmountMinor, resumeFrom];
}
