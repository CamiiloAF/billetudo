import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'usecase_mocks.dart';

void main() {
  late MockGetAppSettings getAppSettings;
  late MockSetZeroBasedEnabled setZeroBasedEnabled;
  late MockGetActiveBudgets getActiveBudgets;
  late MockSetFeaturedBudget setFeaturedBudget;
  late MockClearFeaturedBudget clearFeaturedBudget;
  late MockWatchHelpEnabled watchHelpEnabled;
  late MockSetTutorialsEnabled setTutorialsEnabled;

  const enabledSettings = AppSettings(
    zeroBasedEnabled: true,
    categoriesSeeded: false,
    onboardingCompleted: false,
  );

  const featuredSettings = AppSettings(
    zeroBasedEnabled: true,
    categoriesSeeded: false,
    onboardingCompleted: false,
    featuredBudgetId: 'budget-1',
    featuredBudgetMode: FeaturedBudgetMode.manual,
  );

  final budget = BudgetWithProgress(
    budget: Budget(
      id: 'budget-1',
      name: 'Vacaciones',
      amountMinor: 600000,
      currency: 'COP',
      period: BudgetPeriod.monthly,
      startDate: DateTime(2026, 7, 1),
      recurring: true,
      rollover: false,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: 0,
    ),
    scope: const BudgetScope.empty(),
    window: BudgetPeriodWindow(
      start: DateTime(2026, 7, 1),
      endExclusive: DateTime(2026, 8, 1),
      index: 0,
      status: BudgetWindowStatus.current,
      hasPrevious: false,
      hasNext: true,
    ),
    progress: const BudgetProgress(
      amountMinor: 600000,
      spentMinor: 300000,
      daysLeft: 12,
    ),
  );

  setUp(() {
    getAppSettings = MockGetAppSettings();
    setZeroBasedEnabled = MockSetZeroBasedEnabled();
    getActiveBudgets = MockGetActiveBudgets();
    setFeaturedBudget = MockSetFeaturedBudget();
    clearFeaturedBudget = MockClearFeaturedBudget();
    watchHelpEnabled = MockWatchHelpEnabled();
    setTutorialsEnabled = MockSetTutorialsEnabled();
    // Default: no active budgets; individual tests override.
    when(getActiveBudgets.call)
        .thenAnswer((_) => Stream.value(const Right([])));
    // Default: help preference already on, matching `AppSettingsState`'s own
    // default — most tests never touch this preference.
    when(watchHelpEnabled.call)
        .thenAnswer((_) => Stream.value(const Right(true)));
  });

  AppSettingsCubit build() => AppSettingsCubit(
        getAppSettings,
        setZeroBasedEnabled,
        getActiveBudgets,
        setFeaturedBudget,
        clearFeaturedBudget,
        watchHelpEnabled,
        setTutorialsEnabled,
      );

  blocTest<AppSettingsCubit, AppSettingsState>(
    'HU-06: emits the settings the use case streams',
    setUp: () => when(getAppSettings.call)
        .thenAnswer((_) => Stream.value(const Right(enabledSettings))),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [const AppSettingsState(settings: enabledSettings)],
  );

  blocTest<AppSettingsCubit, AppSettingsState>(
    'a stream failure is swallowed: the last good state stays',
    setUp: () => when(getAppSettings.call).thenAnswer(
      (_) => Stream.fromIterable([
        const Right(enabledSettings),
        const Left(DatabaseFailure('boom')),
      ]),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [const AppSettingsState(settings: enabledSettings)],
  );

  blocTest<AppSettingsCubit, AppSettingsState>(
    'setZeroBasedEnabled delegates to the use case instead of emitting '
    'directly: the stream is the source of truth',
    setUp: () => when(() => setZeroBasedEnabled(enabled: true))
        .thenAnswer((_) async => const Right(unit)),
    build: build,
    act: (cubit) => cubit.setZeroBasedEnabled(enabled: true),
    expect: () => <AppSettingsState>[],
    verify: (_) => verify(() => setZeroBasedEnabled(enabled: true)).called(1),
  );

  blocTest<AppSettingsCubit, AppSettingsState>(
    'start also emits the active budgets for the "Presupuesto destacado" '
    'select sheet',
    setUp: () {
      when(getAppSettings.call)
          .thenAnswer((_) => Stream.value(const Right(enabledSettings)));
      when(getActiveBudgets.call)
          .thenAnswer((_) => Stream.value(Right([budget])));
    },
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [
      const AppSettingsState(settings: enabledSettings),
      AppSettingsState(settings: enabledSettings, activeBudgets: [budget]),
    ],
  );

  blocTest<AppSettingsCubit, AppSettingsState>(
    'exposes the featured budget id vigente from settings',
    setUp: () => when(getAppSettings.call)
        .thenAnswer((_) => Stream.value(const Right(featuredSettings))),
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) =>
        expect(cubit.state.featuredBudgetId, 'budget-1'),
  );

  blocTest<AppSettingsCubit, AppSettingsState>(
    'setFeaturedBudget delegates to the use case instead of emitting '
    'directly: the settings stream is the source of truth',
    setUp: () => when(() => setFeaturedBudget(budgetId: 'budget-1'))
        .thenAnswer((_) async => const Right(unit)),
    build: build,
    act: (cubit) => cubit.setFeaturedBudget('budget-1'),
    expect: () => <AppSettingsState>[],
    verify: (_) =>
        verify(() => setFeaturedBudget(budgetId: 'budget-1')).called(1),
  );

  blocTest<AppSettingsCubit, AppSettingsState>(
    'clearFeaturedBudget delegates to the use case instead of emitting '
    'directly: the settings stream is the source of truth',
    setUp: () => when(clearFeaturedBudget.call)
        .thenAnswer((_) async => const Right(unit)),
    build: build,
    act: (cubit) => cubit.clearFeaturedBudget(),
    expect: () => <AppSettingsState>[],
    verify: (_) => verify(clearFeaturedBudget.call).called(1),
  );

  blocTest<AppSettingsCubit, AppSettingsState>(
    'start also exposes AppSettings.showHelpOnSectionEntry (HU-04)',
    setUp: () {
      when(getAppSettings.call)
          .thenAnswer((_) => Stream.value(const Right(enabledSettings)));
      when(watchHelpEnabled.call)
          .thenAnswer((_) => Stream.value(const Right(false)));
    },
    build: build,
    act: (cubit) => cubit.start(),
    verify: (cubit) =>
        expect(cubit.state.showHelpOnSectionEntry, isFalse),
  );

  blocTest<AppSettingsCubit, AppSettingsState>(
    'setShowHelpOnSectionEntry delegates to SetTutorialsEnabled instead of '
    'emitting directly: the help-enabled stream is the source of truth',
    setUp: () => when(() => setTutorialsEnabled(enabled: true))
        .thenAnswer((_) async => const Right(unit)),
    build: build,
    act: (cubit) => cubit.setShowHelpOnSectionEntry(enabled: true),
    expect: () => <AppSettingsState>[],
    verify: (_) =>
        verify(() => setTutorialsEnabled(enabled: true)).called(1),
  );
}
