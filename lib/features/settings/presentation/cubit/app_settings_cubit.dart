import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../budgets/domain/usecases/get_active_budgets.dart';
import '../../domain/entities/app_settings.dart';
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
@injectable
class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(
    this._getAppSettings,
    this._setZeroBasedEnabled,
    this._getActiveBudgets,
    this._setFeaturedBudget,
  ) : super(const AppSettingsState());

  final GetAppSettings _getAppSettings;
  final SetZeroBasedEnabled _setZeroBasedEnabled;
  final GetActiveBudgets _getActiveBudgets;
  final SetFeaturedBudget _setFeaturedBudget;

  StreamSubscription<Result<AppSettings>>? _settingsSubscription;
  StreamSubscription<Result<List<BudgetWithProgress>>>? _budgetsSubscription;

  Future<void> start() async {
    await _settingsSubscription?.cancel();
    await _budgetsSubscription?.cancel();
    _settingsSubscription = _getAppSettings().listen((result) {
      if (isClosed) {
        return;
      }
      result.fold(
        (_) {},
        (settings) => emit(state.copyWith(settings: settings)),
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
  }

  /// Persists the "Modo sobres" flag (HU-06). The stream re-emits the stored
  /// value, so no manual state juggling is needed.
  Future<void> setZeroBasedEnabled({required bool enabled}) =>
      _setZeroBasedEnabled(enabled: enabled);

  /// Picks (or clears, with `null` for "Automático") the budget featured on
  /// the Home hero card. The settings stream re-emits the stored value, so no
  /// manual state juggling is needed here either.
  Future<void> setFeaturedBudget(String? budgetId) =>
      _setFeaturedBudget(budgetId: budgetId);

  @override
  Future<void> close() async {
    await _settingsSubscription?.cancel();
    await _budgetsSubscription?.cancel();
    return super.close();
  }
}
