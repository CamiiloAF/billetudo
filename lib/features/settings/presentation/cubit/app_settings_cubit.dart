import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../budgets/domain/usecases/get_active_budgets.dart';
import '../../../tutorials/domain/usecases/set_tutorials_enabled.dart';
import '../../../tutorials/domain/usecases/watch_help_enabled.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/clear_featured_budget.dart';
import '../../domain/usecases/get_app_settings.dart';
import '../../domain/usecases/set_featured_budget.dart';
import '../../domain/usecases/set_zero_based_enabled.dart';
import 'app_settings_state.dart';

/// Drives the account-level settings shown in Ajustes (HU-06). Talks only to
/// use cases. The toggle is optimistic against the settings stream, which is the
/// source of truth and re-emits the persisted value.
///
/// Also feeds the "Presupuesto destacado" select sheet
/// (`design-system/billetudo/pages/ajustes.md`): [AppSettingsState.activeBudgets]
/// mirrors `BudgetRepository.watchActiveBudgets()` so an archived/deleted
/// featured budget stops appearing as a selectable — and stops being
/// highlighted as selected — the moment it drops out of that stream, with no
/// extra cleanup.
///
/// "Mostrar ayuda al entrar a una sección" (`docs/requirements/
/// 16-minitutoriales.md` HU-04) rides along here too: it is the same kind of
/// account-level preference as "Modo sobres", just backed by
/// `TutorialsRepository` instead of `AppSettingsRepository`.
@injectable
class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(
    this._getAppSettings,
    this._setZeroBasedEnabled,
    this._getActiveBudgets,
    this._setFeaturedBudget,
    this._clearFeaturedBudget,
    this._watchHelpEnabled,
    this._setTutorialsEnabled,
  ) : super(const AppSettingsState(isLoaded: false));

  final GetAppSettings _getAppSettings;
  final SetZeroBasedEnabled _setZeroBasedEnabled;
  final GetActiveBudgets _getActiveBudgets;
  final SetFeaturedBudget _setFeaturedBudget;
  final ClearFeaturedBudget _clearFeaturedBudget;
  final WatchHelpEnabled _watchHelpEnabled;
  final SetTutorialsEnabled _setTutorialsEnabled;

  StreamSubscription<Result<AppSettings>>? _settingsSubscription;
  StreamSubscription<Result<List<BudgetWithProgress>>>? _budgetsSubscription;
  StreamSubscription<Result<bool>>? _helpEnabledSubscription;

  Future<void> start() async {
    await _settingsSubscription?.cancel();
    await _budgetsSubscription?.cancel();
    await _helpEnabledSubscription?.cancel();
    _settingsSubscription = _getAppSettings().listen((result) {
      if (isClosed) {
        return;
      }
      result.fold(
        (_) {},
        (settings) => emit(state.copyWith(settings: settings, isLoaded: true)),
      );
    });
    _budgetsSubscription = _getActiveBudgets().listen((result) {
      if (isClosed) {
        return;
      }
      result.fold(
        (_) {},
        (budgets) => emit(state.copyWith(activeBudgets: budgets)),
      );
    });
    _helpEnabledSubscription = _watchHelpEnabled().listen((result) {
      if (isClosed) {
        return;
      }
      result.fold(
        (_) {},
        (enabled) => emit(state.copyWith(showHelpOnSectionEntry: enabled)),
      );
    });
  }

  /// Persists the "Modo sobres" flag (HU-06). The stream re-emits the stored
  /// value, so no manual state juggling is needed.
  Future<void> setZeroBasedEnabled({required bool enabled}) =>
      _setZeroBasedEnabled(enabled: enabled);

  /// Manually picks the budget featured on the Home hero card. The settings
  /// stream re-emits the stored value, so no manual state juggling is needed
  /// here either.
  Future<void> setFeaturedBudget(String budgetId) =>
      _setFeaturedBudget(budgetId: budgetId);

  /// Clears the featured budget (`FeaturedBudgetMode.none`): no featured
  /// budget on Home, and no automatic fallback either.
  Future<void> clearFeaturedBudget() => _clearFeaturedBudget();

  /// Persists "Mostrar ayuda al entrar a una sección" (HU-04). Turning it
  /// back on also resets every tutorial's "seen" registry — that business
  /// rule lives in [SetTutorialsEnabled], not here; the stream re-emits the
  /// stored value the same way [setZeroBasedEnabled] does.
  Future<void> setShowHelpOnSectionEntry({required bool enabled}) =>
      _setTutorialsEnabled(enabled: enabled);

  @override
  Future<void> close() async {
    await _settingsSubscription?.cancel();
    await _budgetsSubscription?.cancel();
    await _helpEnabledSubscription?.cancel();
    return super.close();
  }
}
