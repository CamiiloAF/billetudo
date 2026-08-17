import 'dart:async';

import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_view.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scheduled_item.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_detail_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_detail_state.dart';
import 'package:billetudo/features/budgets/presentation/pages/budget_detail_page.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_featured_badge.dart';
import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_scheduled_sheet.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../golden/budget_golden_fixtures.dart';

class MockBudgetDetailCubit extends MockCubit<BudgetDetailState>
    implements BudgetDetailCubit {}

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

/// HU-12, criterion 8: the "programado" entry point on the detail hero.
void main() {
  late MockBudgetDetailCubit cubit;

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    cubit = MockBudgetDetailCubit();
  });

  Future<void> pump(
    WidgetTester tester,
    BudgetDetailState state, {
    AppSettingsCubit? settingsCubit,
  }) async {
    when(() => cubit.state).thenReturn(state);
    final resolvedSettingsCubit = settingsCubit ?? MockAppSettingsCubit();
    if (settingsCubit == null) {
      when(() => resolvedSettingsCubit.state).thenReturn(
        const AppSettingsState(
          settings: AppSettings(
            zeroBasedEnabled: false,
            categoriesSeeded: true,
            onboardingCompleted: true,
          ),
        ),
      );
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<BudgetDetailCubit>.value(value: cubit),
            BlocProvider<AppSettingsCubit>.value(value: resolvedSettingsCubit),
          ],
          child: BudgetDetailPage(
            onEdit: (_) {},
            onClosed: () {},
            onOpenTransaction: (_) async => null,
            onOpenScheduledPayment: (_) {},
            onSeeAllScheduled: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final scheduledItems = [
    BudgetScheduledItem(
      id: 'sp-1@2025-08-05T00:00:00.000',
      scheduledPaymentId: 'sp-1',
      note: 'Netflix',
      accountName: 'Bancolombia',
      amountMinor: 4500000,
      currency: 'COP',
      date: DateTime(2025, 8, 5),
    ),
  ];

  BudgetDetailState readyState({required int scheduledMinor}) {
    final entry = healthyEntry;
    return BudgetDetailState(
      status: BudgetDetailStatus.ready,
      budget: entry.budget,
      scope: entry.scope,
      view: BudgetPeriodView(
        window: entry.window,
        progress: BudgetProgress(
          amountMinor: entry.progress.amountMinor,
          spentMinor: entry.progress.spentMinor,
          daysLeft: entry.progress.daysLeft,
          scheduledMinor: scheduledMinor,
        ),
        activity: const [],
        scheduledItems: scheduledMinor > 0 ? scheduledItems : const [],
      ),
    );
  }

  testWidgets('with nothing programado, the entry row does not render',
      (tester) async {
    await pump(tester, readyState(scheduledMinor: 0));

    expect(find.textContaining('Programado'), findsNothing);
  });

  testWidgets(
      'with something programado, the entry row shows the figure and opens '
      'the sheet with what composes it', (tester) async {
    await pump(tester, readyState(scheduledMinor: 4500000));

    expect(find.text('Programado'), findsOneWidget);
    expect(find.textContaining(r'$45.000'), findsWidgets);

    await tester.tap(find.text('Programado'));
    await tester.pumpAndSettle();

    expect(find.byType(BudgetScheduledSheet), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
  });

  group(
      'actions sheet "isFeatured" (bugfix: automatic-fallback featured '
      'budget)', () {
    BudgetDetailState globalReadyState() {
      final entry = globalEntry;
      return BudgetDetailState(
        status: BudgetDetailStatus.ready,
        budget: entry.budget,
        scope: entry.scope,
        view: BudgetPeriodView(
          window: entry.window,
          progress: entry.progress,
          activity: const [],
          scheduledItems: const [],
        ),
      );
    }

    MockAppSettingsCubit buildSettingsCubit({
      required FeaturedBudgetMode mode,
      String? featuredBudgetId,
    }) {
      final settingsCubit = MockAppSettingsCubit();
      when(() => settingsCubit.state).thenReturn(
        AppSettingsState(
          settings: AppSettings(
            zeroBasedEnabled: false,
            categoriesSeeded: true,
            onboardingCompleted: true,
            featuredBudgetId: featuredBudgetId,
            featuredBudgetMode: mode,
          ),
          // Only the global-monthly `globalEntry` qualifies for the
          // automatic fallback — this is the exact list `AppSettingsCubit`
          // exposes for the "Presupuesto destacado" sheet, and what
          // `BudgetHeroSelector.pick` (used by `_openActions`) evaluates.
          activeBudgets: [globalEntry],
        ),
      );
      when(settingsCubit.clearFeaturedBudget).thenAnswer((_) async {});
      when(() => settingsCubit.setFeaturedBudget(any()))
          .thenAnswer((_) async {});
      return settingsCubit;
    }

    testWidgets(
        'a budget featured only via the automatic fallback (no manual pick) '
        'opens the sheet offering "Quitar de Inicio", not "Usar como '
        'destacado"', (tester) async {
      final settingsCubit = buildSettingsCubit(
        mode: FeaturedBudgetMode.automatic,
      );

      await pump(tester, globalReadyState(), settingsCubit: settingsCubit);
      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();

      expect(find.text('Quitar de Inicio'), findsOneWidget);
      expect(find.text('Usar como destacado en Inicio'), findsNothing);
    });

    testWidgets(
        'tapping "Quitar de Inicio" on an automatic-fallback-featured budget '
        'calls clearFeaturedBudget(), never setFeaturedBudget(null)',
        (tester) async {
      final settingsCubit = buildSettingsCubit(
        mode: FeaturedBudgetMode.automatic,
      );

      await pump(tester, globalReadyState(), settingsCubit: settingsCubit);
      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitar de Inicio'));
      await tester.pumpAndSettle();

      verify(settingsCubit.clearFeaturedBudget).called(1);
      verifyNever(() => settingsCubit.setFeaturedBudget(any()));
    });

    testWidgets(
        'a budget that is not featured at all (mode: none) opens the sheet '
        'offering "Usar como destacado", and tapping it manually sets this '
        'budget', (tester) async {
      final settingsCubit = buildSettingsCubit(mode: FeaturedBudgetMode.none);

      await pump(tester, globalReadyState(), settingsCubit: settingsCubit);
      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();

      expect(find.text('Usar como destacado en Inicio'), findsOneWidget);
      expect(find.text('Quitar de Inicio'), findsNothing);

      await tester.tap(find.text('Usar como destacado en Inicio'));
      await tester.pumpAndSettle();

      verify(() => settingsCubit.setFeaturedBudget(globalEntry.budget.id))
          .called(1);
      verifyNever(settingsCubit.clearFeaturedBudget);
    });
  });

  group(
      'toggleFeatured waits for AppSettingsCubit to load before deciding '
      'the branch (race fix)', () {
    BudgetDetailState globalReadyState() {
      final entry = globalEntry;
      return BudgetDetailState(
        status: BudgetDetailStatus.ready,
        budget: entry.budget,
        scope: entry.scope,
        view: BudgetPeriodView(
          window: entry.window,
          progress: entry.progress,
          activity: const [],
          scheduledItems: const [],
        ),
      );
    }

    testWidgets(
        'a still-loading cubit (isLoaded: false, stale in-memory default) '
        'blocks the decision until the stream emits the real value, then '
        'acts on it instead of the default', (tester) async {
      final settingsCubit = MockAppSettingsCubit();
      final controller = StreamController<AppSettingsState>();
      addTearDown(controller.close);
      const notYetLoaded = AppSettingsState(
        settings: AppSettings(
          zeroBasedEnabled: false,
          categoriesSeeded: true,
          onboardingCompleted: true,
        ),
        isLoaded: false,
      );
      whenListen(settingsCubit, controller.stream, initialState: notYetLoaded);
      when(() => settingsCubit.state).thenReturn(notYetLoaded);
      when(settingsCubit.clearFeaturedBudget).thenAnswer((_) async {});
      when(() => settingsCubit.setFeaturedBudget(any()))
          .thenAnswer((_) async {});

      await pump(tester, globalReadyState(), settingsCubit: settingsCubit);
      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();

      // With the stale default (mode: automatic, no active budgets loaded
      // yet), `BudgetHeroSelector.pick` cannot resolve anything, so the
      // sheet still offers "Usar como destacado".
      expect(find.text('Usar como destacado en Inicio'), findsOneWidget);

      await tester.tap(find.text('Usar como destacado en Inicio'));
      await tester.pumpAndSettle();

      // The tap is stuck awaiting the real value — neither branch has run.
      verifyNever(() => settingsCubit.setFeaturedBudget(any()));
      verifyNever(settingsCubit.clearFeaturedBudget);

      // The stream now emits what was actually persisted: this budget was
      // already manually featured all along.
      when(() => settingsCubit.state).thenReturn(
        AppSettingsState(
          settings: AppSettings(
            zeroBasedEnabled: false,
            categoriesSeeded: true,
            onboardingCompleted: true,
            featuredBudgetId: globalEntry.budget.id,
            featuredBudgetMode: FeaturedBudgetMode.manual,
          ),
          activeBudgets: [globalEntry],
        ),
      );
      controller.add(
        AppSettingsState(
          settings: AppSettings(
            zeroBasedEnabled: false,
            categoriesSeeded: true,
            onboardingCompleted: true,
            featuredBudgetId: globalEntry.budget.id,
            featuredBudgetMode: FeaturedBudgetMode.manual,
          ),
          activeBudgets: [globalEntry],
        ),
      );
      await tester.pumpAndSettle();

      // Correctly resolved against the real value: this budget WAS
      // featured, so removing it is the right call — never the stale
      // default's "set it as featured" (which would have been a no-op at
      // best, or have clobbered a different manual pick at worst).
      verify(settingsCubit.clearFeaturedBudget).called(1);
      verifyNever(() => settingsCubit.setFeaturedBudget(any()));
    });
  });

  group('hero "BudgetFeaturedBadge" (resolved via BudgetHeroSelector.pick)',
      () {
    MockAppSettingsCubit buildSettingsCubit({
      required FeaturedBudgetMode mode,
      String? featuredBudgetId,
    }) {
      final settingsCubit = MockAppSettingsCubit();
      when(() => settingsCubit.state).thenReturn(
        AppSettingsState(
          settings: AppSettings(
            zeroBasedEnabled: false,
            categoriesSeeded: true,
            onboardingCompleted: true,
            featuredBudgetId: featuredBudgetId,
            featuredBudgetMode: mode,
          ),
          // `readyState()` (shared with the tests above) renders
          // `healthyEntry`'s budget, so it must be the one `activeBudgets`
          // exposes for `BudgetHeroSelector.pick`'s manual match to resolve
          // against.
          activeBudgets: [healthyEntry],
        ),
      );
      return settingsCubit;
    }

    testWidgets(
        'a budget featured (manual pick matches this budget) renders '
        'BudgetFeaturedBadge over the hero', (tester) async {
      final settingsCubit = buildSettingsCubit(
        mode: FeaturedBudgetMode.manual,
        featuredBudgetId: healthyEntry.budget.id,
      );

      await pump(
        tester,
        readyState(scheduledMinor: 0),
        settingsCubit: settingsCubit,
      );

      expect(find.byType(BudgetFeaturedBadge), findsOneWidget);
    });

    testWidgets(
        'a budget not featured (mode: none) renders no BudgetFeaturedBadge',
        (tester) async {
      final settingsCubit = buildSettingsCubit(mode: FeaturedBudgetMode.none);

      await pump(
        tester,
        readyState(scheduledMinor: 0),
        settingsCubit: settingsCubit,
      );

      expect(find.byType(BudgetFeaturedBadge), findsNothing);
    });
  });
}
