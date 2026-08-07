import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/domain/repositories/app_settings_repository.dart';
import '../entities/budget_with_progress.dart';
import '../repositories/budget_repository.dart';
import '../services/budget_hero_selector.dart';

/// Home's hero progress bar (`docs/requirements/04-inicio.md`,
/// `design-system/billetudo/pages/ajustes.md`, "Presupuesto destacado").
///
/// Combines the active budgets with the user's settings so a manual pick
/// (`AppSettings.featuredBudgetId`) wins over the automatic global+monthly
/// selection (`BudgetHeroSelector`) — and so the hero falls back
/// automatically, on the very next emission, the moment the featured budget
/// is archived or deleted (it simply drops out of `watchActiveBudgets()`,
/// with no explicit cleanup needed here or in Ajustes).
///
/// This use case only answers "which budget is featured, and how is it doing
/// in its **current** period window" — it deliberately does not grow an
/// `index` parameter to navigate to a different window. The hero's period
/// stepper (HU-05, once the hero navigates the featured budget's real window
/// instead of a calendar month) reuses the exact same pair the budget detail
/// screen already does for that: `GetBudgetById` (the reactive detail bundle
/// for one known id) + `GetBudgetProgress.call(data, now:, index:)` (the pure
/// window/progress computation, `BudgetPeriodCalculator` underneath). Once
/// this stream has produced the featured budget's id, the caller subscribes
/// to those two directly — duplicating navigation here would just be a
/// second, divergence-prone path to the same `BudgetPeriodView`.
@injectable
class WatchFeaturedBudgetProgress {
  const WatchFeaturedBudgetProgress(
    this._budgetRepository,
    this._settingsRepository,
  );

  final BudgetRepository _budgetRepository;
  final AppSettingsRepository _settingsRepository;

  Stream<Result<BudgetWithProgress?>> call() => _combineLatest(
        _budgetRepository.watchActiveBudgets(),
        _settingsRepository.watchSettings(),
      );

  /// Minimal combineLatest for exactly 2 sources — same pattern as
  /// `WatchReportsDashboard`; the project has no rxdart dependency. Emits
  /// once both sources have produced at least one value, then again on every
  /// subsequent emission of either.
  Stream<Result<BudgetWithProgress?>> _combineLatest(
    Stream<Result<List<BudgetWithProgress>>> budgets,
    Stream<Result<AppSettings>> settings,
  ) {
    late final StreamController<Result<BudgetWithProgress?>> controller;
    StreamSubscription<Result<List<BudgetWithProgress>>>? budgetsSub;
    StreamSubscription<Result<AppSettings>>? settingsSub;
    Result<List<BudgetWithProgress>>? latestBudgets;
    Result<AppSettings>? latestSettings;
    var openSources = 2;

    void closeIfDone() {
      openSources--;
      if (openSources == 0) {
        unawaited(controller.close());
      }
    }

    void emit() {
      final budgetsResult = latestBudgets;
      final settingsResult = latestSettings;
      if (budgetsResult == null || settingsResult == null) return;
      controller.add(
        budgetsResult.flatMap(
          (budgetList) => settingsResult.map(
            (appSettings) => BudgetHeroSelector.pick(
              budgetList,
              featuredBudgetId: appSettings.featuredBudgetId,
            ),
          ),
        ),
      );
    }

    controller = StreamController<Result<BudgetWithProgress?>>.broadcast(
      onListen: () {
        budgetsSub = budgets.listen(
          (event) {
            latestBudgets = event;
            emit();
          },
          onError: controller.addError,
          onDone: closeIfDone,
        );
        settingsSub = settings.listen(
          (event) {
            latestSettings = event;
            emit();
          },
          onError: controller.addError,
          onDone: closeIfDone,
        );
      },
      onCancel: () async {
        await budgetsSub?.cancel();
        await settingsSub?.cancel();
      },
    );
    return controller.stream;
  }
}
