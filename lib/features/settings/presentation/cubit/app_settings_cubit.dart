import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../budgets/domain/usecases/get_active_budgets.dart';
import '../../../capture/domain/usecases/get_cloud_transcription_consent.dart';
import '../../../capture/domain/usecases/set_cloud_transcription_consent.dart';
import '../../../home/domain/entities/quick_access_item.dart';
import '../../../tutorials/domain/usecases/set_tutorials_enabled.dart';
import '../../../tutorials/domain/usecases/watch_help_enabled.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/clear_ai_consent.dart';
import '../../domain/usecases/clear_featured_budget.dart';
import '../../domain/usecases/get_app_settings.dart';
import '../../domain/usecases/set_ai_notes_access_enabled.dart';
import '../../domain/usecases/set_featured_budget.dart';
import '../../domain/usecases/set_quick_access_order.dart';
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
    this._setQuickAccessOrder,
    this._setAiNotesAccessEnabled,
    this._clearAiConsent,
    this._getCloudTranscriptionConsent,
    this._setCloudTranscriptionConsent,
  ) : super(const AppSettingsState(isLoaded: false));

  final GetAppSettings _getAppSettings;
  final SetZeroBasedEnabled _setZeroBasedEnabled;
  final GetActiveBudgets _getActiveBudgets;
  final SetFeaturedBudget _setFeaturedBudget;
  final ClearFeaturedBudget _clearFeaturedBudget;
  final WatchHelpEnabled _watchHelpEnabled;
  final SetTutorialsEnabled _setTutorialsEnabled;
  final SetQuickAccessOrder _setQuickAccessOrder;
  final SetAiNotesAccessEnabled _setAiNotesAccessEnabled;
  final ClearAiConsent _clearAiConsent;
  final GetCloudTranscriptionConsent _getCloudTranscriptionConsent;
  final SetCloudTranscriptionConsent _setCloudTranscriptionConsent;

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
    // A one-shot read, not a stream: the consent lives in this device's
    // preferences and only this screen writes it, so there is nothing to
    // watch for.
    final consent = await _getCloudTranscriptionConsent();
    if (isClosed) {
      return;
    }
    emit(state.copyWith(cloudTranscriptionEnabled: consent.isGranted));
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

  /// Reorders Home's quick-access chips (`QuickAccessRow`), from the reorder
  /// screen in Ajustes. [order] must be an exact permutation of
  /// [QuickAccessItem.values] — [SetQuickAccessOrder] enforces that and
  /// leaves the persisted order untouched otherwise. The settings stream
  /// re-emits the stored value, so no manual state juggling is needed here
  /// either.
  Future<Result<Unit>> setQuickAccessOrder(List<QuickAccessItem> order) =>
      _setQuickAccessOrder(order);

  /// Persists "Dejar que el asistente lea mis notas"
  /// (`AppSettings.aiNotesAccessEnabled`). Turning it **on** is gated behind
  /// an explicit confirmation in the UI (`AiNotesAccessSheet`), because it
  /// widens what leaves the device; turning it off is immediate — withdrawing
  /// a permission never asks twice. The settings stream re-emits the stored
  /// value, so no manual state juggling is needed here either.
  Future<void> setAiNotesAccessEnabled({required bool enabled}) =>
      _setAiNotesAccessEnabled(enabled: enabled);

  /// Withdraws the AI assistant's data-sharing consent from Ajustes (RGPD
  /// art. 7.3 — withdrawing must be as easy as granting). Gated behind an
  /// explicit confirmation in the UI (`AiConsentWithdrawSheet`) because it
  /// closes the assistant and turns "Dejar que el asistente lea mis notas"
  /// off in the same write — that combined rule lives in [ClearAiConsent].
  /// The settings stream re-emits the stored values, so both the switch and
  /// the action's own visibility update without manual state juggling.
  Future<void> clearAiConsent() => _clearAiConsent();

  /// Persists "Transcribir mi voz en la nube", the reversal the cloud consent
  /// sheet (`kJG43`) promises in its caption.
  ///
  /// Emitted optimistically because — unlike every toggle above — there is no
  /// stream re-emitting the stored value: the consent is per-device
  /// preference state, so this cubit is the one that has to move the switch.
  Future<void> setCloudTranscriptionEnabled({required bool enabled}) async {
    emit(state.copyWith(cloudTranscriptionEnabled: enabled));
    await _setCloudTranscriptionConsent.setAllowed(allowed: enabled);
  }

  @override
  Future<void> close() async {
    await _settingsSubscription?.cancel();
    await _budgetsSubscription?.cancel();
    await _helpEnabledSubscription?.cancel();
    return super.close();
  }
}
