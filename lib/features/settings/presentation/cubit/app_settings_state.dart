import 'package:equatable/equatable.dart';

import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../domain/entities/app_settings.dart';

/// State of the account-level app settings (HU-06). Starts with the safe
/// defaults so the toggle renders before the first stream value arrives.
class AppSettingsState extends Equatable {
  const AppSettingsState({
    this.settings = const AppSettings.defaults(),
    this.activeBudgets = const [],
    this.showHelpOnSectionEntry = true,
    this.isLoaded = true,
  });

  final AppSettings settings;

  /// Active budgets (not archived, not trashed), newest first — the options
  /// offered by the "Presupuesto destacado" select sheet, alongside
  /// "Automático".
  final List<BudgetWithProgress> activeBudgets;

  /// "Mostrar ayuda al entrar a una sección" (`docs/requirements/
  /// 16-minitutoriales.md` HU-04). Lives outside [AppSettings] on purpose —
  /// it is `TutorialsRepository`'s own `AppSettings.showHelpOnSectionEntry`
  /// column, read through `WatchHelpEnabled`, not through
  /// `AppSettingsRepository` — so this cubit stays the single place Ajustes
  /// asks for every one of its toggles without needing to know which
  /// repository backs which column.
  final bool showHelpOnSectionEntry;

  /// Whether [settings] already reflects the first real value emitted by
  /// `GetAppSettings`'s stream, as opposed to the in-memory default this
  /// state starts with before that stream has emitted at least once.
  ///
  /// `AppSettingsCubit`'s own initial state (before `AppSettingsCubit.start`
  /// has resolved anything) is the only place this is explicitly `false` —
  /// a fresh `AppSettingsCubit` instance is created per navigation to the
  /// budget detail route (`app_router.dart`), so its stream has not
  /// necessarily emitted yet by the time the user taps "Destacar"/"Quitar de
  /// Inicio". Every state built elsewhere (tests, `copyWith`) defaults to
  /// `true` since it already represents a resolved value.
  final bool isLoaded;

  bool get zeroBasedEnabled => settings.zeroBasedEnabled;

  /// The manually-featured budget id, or `null` for "Automático"
  /// (`design-system/billetudo/pages/ajustes.md`, "Presupuesto destacado").
  String? get featuredBudgetId => settings.featuredBudgetId;

  AppSettingsState copyWith({
    AppSettings? settings,
    List<BudgetWithProgress>? activeBudgets,
    bool? showHelpOnSectionEntry,
    bool? isLoaded,
  }) =>
      AppSettingsState(
        settings: settings ?? this.settings,
        activeBudgets: activeBudgets ?? this.activeBudgets,
        showHelpOnSectionEntry:
            showHelpOnSectionEntry ?? this.showHelpOnSectionEntry,
        isLoaded: isLoaded ?? this.isLoaded,
      );

  @override
  List<Object?> get props =>
      [settings, activeBudgets, showHelpOnSectionEntry, isLoaded];
}
