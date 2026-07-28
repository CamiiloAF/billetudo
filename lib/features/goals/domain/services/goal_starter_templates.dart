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
    // Icons and which template carries the "3 meses de tus gastos ≈ $X"
    // suggestion are confirmed against the real `.pen` tiles (`qzBkN`'s
    // `vjTZR` rows), not guessed from the templates' own names — "Colchón de
    // 3 meses" mentions "3 meses" in its copy but the frame gives it a
    // static description, not a computed suggestion; only "Fondo de
    // emergencia" does.
    GoalStarterTemplate(
      id: emergencyFundId,
      name: 'Fondo de emergencia',
      icon: 'umbrella',
      suggestedMonthsOfExpenses: 3,
    ),
    GoalStarterTemplate(
      id: vacationId,
      name: 'Vacaciones',
      icon: 'plane',
    ),
    GoalStarterTemplate(
      id: threeMonthCushionId,
      name: 'Un colchón de 3 meses',
      icon: 'shield',
    ),
  ];

  /// A static placeholder average monthly expense, in COP-equivalent minor
  /// units ($800.000). No use case in this codebase yet derives a real
  /// average from the user's transaction history — until one exists, the
  /// empty-state's "3 meses de tus gastos ≈ $X" suggestion falls back to this
  /// fixed figure rather than going unsuggested. Replace with a real
  /// data-derived average (e.g. a dedicated `WatchAverageMonthlyExpense` use
  /// case reading `Transactions`) as soon as that source exists.
  static const int fallbackAverageMonthlyExpenseMinor = 80000000;

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
