import 'package:equatable/equatable.dart';

import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../domain/entities/app_settings.dart';

/// State of the account-level app settings (HU-06). Starts with the safe
/// defaults so the toggle renders before the first stream value arrives.
class AppSettingsState extends Equatable {
  const AppSettingsState({
    this.settings = const AppSettings.defaults(),
    this.activeBudgets = const [],
  });

  final AppSettings settings;

  /// Active budgets (not archived, not trashed), newest first — the options
  /// offered by the "Presupuesto destacado" select sheet, alongside
  /// "Automático".
  final List<BudgetWithProgress> activeBudgets;

  bool get zeroBasedEnabled => settings.zeroBasedEnabled;

  /// The manually-featured budget id, or `null` for "Automático"
  /// (`design-system/billetudo/pages/ajustes.md`, "Presupuesto destacado").
  String? get featuredBudgetId => settings.featuredBudgetId;

  AppSettingsState copyWith({
    AppSettings? settings,
    List<BudgetWithProgress>? activeBudgets,
  }) =>
      AppSettingsState(
        settings: settings ?? this.settings,
        activeBudgets: activeBudgets ?? this.activeBudgets,
      );

  @override
  List<Object?> get props => [settings, activeBudgets];
}
