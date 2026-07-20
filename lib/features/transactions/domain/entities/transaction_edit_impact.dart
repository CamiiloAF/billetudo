import 'package:equatable/equatable.dart';

/// What editing a transaction would affect on the relations it is linked to
/// (HU-04): a scheduled payment, a savings goal, or a debt. Purely
/// informative — the edit still goes through; this only drives the warning
/// shown before confirming.
class TransactionEditImpact extends Equatable {
  const TransactionEditImpact({
    required this.affectsScheduledPayment,
    required this.affectsGoal,
    required this.affectsDebt,
  });

  static const TransactionEditImpact none = TransactionEditImpact(
    affectsScheduledPayment: false,
    affectsGoal: false,
    affectsDebt: false,
  );

  final bool affectsScheduledPayment;
  final bool affectsGoal;
  final bool affectsDebt;

  bool get hasImpact => affectsScheduledPayment || affectsGoal || affectsDebt;

  @override
  List<Object?> get props =>
      [affectsScheduledPayment, affectsGoal, affectsDebt];
}
