import 'package:equatable/equatable.dart';

/// A single one-tap starter template offered by the empty-state (HU-13).
/// Picking one pre-fills the create-goal form with [name]/[icon]; the amount
/// stays editable — this is a suggestion, never an imposed value.
class GoalStarterTemplate extends Equatable {
  const GoalStarterTemplate({
    required this.id,
    required this.name,
    required this.icon,
    this.suggestedMonthsOfExpenses,
  });

  final String id;
  final String name;
  final String icon;

  /// When set, the suggested `targetMinor` is this many months of the user's
  /// average monthly expense (HU-13: "3 meses de tus gastos ≈ $X"),
  /// resolved by [GoalStarterTemplates.suggestedTargetMinor]. `null` means
  /// the template has no data-derived suggestion (the user types a figure).
  final int? suggestedMonthsOfExpenses;

  @override
  List<Object?> get props => [id, name, icon, suggestedMonthsOfExpenses];
}

/// Local, network-free content for HU-13's empty-state templates. Nivel 0:
/// no IA, no remote call, never gated by ad or payment.
abstract final class GoalStarterTemplates {
  static const String emergencyFundId = 'starter-emergency-fund';
  static const String vacationId = 'starter-vacation';
  static const String threeMonthCushionId = 'starter-three-month-cushion';

  static const List<GoalStarterTemplate> all = [
    GoalStarterTemplate(
      id: emergencyFundId,
      name: 'Fondo de emergencia',
      icon: 'shield',
      suggestedMonthsOfExpenses: 3,
    ),
    GoalStarterTemplate(
      id: vacationId,
      name: 'Vacaciones',
      icon: 'palm-tree',
    ),
    GoalStarterTemplate(
      id: threeMonthCushionId,
      name: 'Un colchón de 3 meses',
      icon: 'umbrella',
      suggestedMonthsOfExpenses: 3,
    ),
  ];

  /// HU-13: "3 meses de tus gastos ≈ $X" — a suggestion the user can edit,
  /// never an imposed value. `null` when there is no expense history to
  /// derive one from, or the template carries no data-driven suggestion.
  static int? suggestedTargetMinor({
    required GoalStarterTemplate template,
    required int averageMonthlyExpenseMinor,
  }) {
    final months = template.suggestedMonthsOfExpenses;
    if (months == null || averageMonthlyExpenseMinor <= 0) {
      return null;
    }
    return averageMonthlyExpenseMinor * months;
  }
}
