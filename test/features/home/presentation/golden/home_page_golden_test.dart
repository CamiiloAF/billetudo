import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/home/domain/entities/home_ai_insight.dart';
import 'package:billetudo/features/home/domain/entities/home_snapshot.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/home/presentation/pages/home_page.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../home_fixtures.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

void main() {
  late MockHomeCubit cubit;
  late MockAppSettingsCubit appSettingsCubit;

  final month = DateTime(2026, 7);

  HomeState readyWith(
    List<dynamic> transactions, {
    AuthUser? user,
    BudgetWithProgress? budgetProgress,
  }) =>
      HomeState(
        status: HomeStatus.ready,
        user: user,
        snapshot: HomeSnapshot.from(
          month: month,
          accounts: [buildActiveAccount()],
          transactions: transactions.cast(),
          budgetProgress: budgetProgress,
        ),
      );

  setUpAll(() async {
    await initializeDateFormatting();
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() {
    cubit = MockHomeCubit();
    appSettingsCubit = MockAppSettingsCubit();
    when(() => appSettingsCubit.state).thenReturn(const AppSettingsState());
    whenListen(
      appSettingsCubit,
      const Stream<AppSettingsState>.empty(),
      initialState: const AppSettingsState(),
    );
  });

  Future<void> golden(
    WidgetTester tester,
    HomeState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    whenListen(cubit, const Stream<HomeState>.empty(), initialState: state);
    await pumpGolden(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<HomeCubit>.value(value: cubit),
          BlocProvider<AppSettingsCubit>.value(value: appSettingsCubit),
        ],
        child: HomePage(
          onAddTransaction: () {},
          onSeeAllTransactions: () {},
          onOpenTransaction: (_) async => null,
          onCreateBudget: () {},
          onOpenBudget: (_) {},
          onOpenAccounts: () {},
          onOpenAccountMovements: (_) {},
          onOpenScheduledPayments: () {},
          onOpenDebts: () {},
          onOpenReports: () {},
          onOpenGoals: () {},
          onOpenQuickAccessOrder: () {},
          onOpenLogin: () {},
          onOpenSyncStatus: () {},
          onOpenSettings: () {},
          onSignOut: () {},
          onOpenAi: (_) {},
          onOpenAiInsightQuestion: ({required question, required insightType}) async {},
          onOpenAiConversation: (_) async {},
        ),
      ),
      brightness: brightness,
      settle: settle,
    );
    await expectLater(
      find.byType(HomePage),
      matchesGoldenFile('goldens/home_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        HomeState.initial(month),
        'loading_$suffix',
        brightness: brightness,
        // HU-09: the loading state renders an indeterminate spinner nowhere,
        // but the skeleton rows use fixed widths — still avoid settling in
        // case an ancestor introduces an animation later; `pump()` alone is
        // enough since there is nothing indeterminate here today.
      );
    });

    testWidgets('empty (HU-08) ($suffix)', (tester) async {
      await golden(
        tester,
        readyWith(const []),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with data, no session ($suffix)', (tester) async {
      await golden(
        tester,
        readyWith([
          buildActivity(
            id: 'tx-1',
            categoryName: 'Mercado',
            categoryIcon: 'shopping-cart',
            categoryColor: 'mint',
            amountMinor: 45000,
          ),
          buildActivity(
            id: 'tx-2',
            categoryName: 'Transporte',
            categoryIcon: 'car',
            categoryColor: 'sky',
            amountMinor: 8000,
            date: DateTime(2026, 7, 10),
          ),
          buildActivity(
            id: 'tx-3',
            categoryName: 'Restaurantes',
            categoryIcon: 'coffee',
            categoryColor: 'amber',
            amountMinor: 32000,
            date: DateTime(2026, 7, 5),
          ),
          // Income row so the "+" sign (recent_activity_row_test covers it
          // in unit-test isolation, but no golden had captured it yet).
          buildActivity(
            id: 'tx-4',
            categoryName: 'Salario',
            categoryIcon: 'wallet',
            categoryColor: 'mint',
            amountMinor: 250000,
            type: TransactionType.income,
            date: DateTime(2026, 7, 1),
          ),
        ]),
        'with_data_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with data, signed in ($suffix)', (tester) async {
      await golden(
        tester,
        readyWith(
          [
            buildActivity(
              id: 'tx-1',
              categoryName: 'Mercado',
              categoryIcon: 'shopping-cart',
              categoryColor: 'mint',
              amountMinor: 45000,
            ),
            buildActivity(
              id: 'tx-2',
              categoryName: 'Transporte',
              categoryIcon: 'car',
              categoryColor: 'sky',
              amountMinor: 8000,
              date: DateTime(2026, 7, 10),
            ),
          ],
          user: const AuthUser(
            id: 'user-1',
            displayName: 'Camila Restrepo',
            provider: AuthProvider.google,
            email: 'camila@example.com',
          ),
        ),
        'with_data_signed_in_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with budget progress (HU-03, aOhoY) ($suffix)',
        (tester) async {
      await golden(
        tester,
        readyWith(
          [
            buildActivity(
              id: 'tx-1',
              categoryName: 'Mercado',
              categoryIcon: 'shopping-cart',
              categoryColor: 'mint',
              amountMinor: 45000,
            ),
            buildActivity(
              id: 'tx-2',
              categoryName: 'Transporte',
              categoryIcon: 'car',
              categoryColor: 'sky',
              amountMinor: 8000,
              date: DateTime(2026, 7, 10),
            ),
          ],
          budgetProgress: buildHomeBudgetProgress(
            amountMinor: 600000,
            spentMinor: 300000,
            daysLeft: 12,
          ),
        ),
        'with_budget_progress_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('error, local-first (HU-10) ($suffix)', (tester) async {
      // `HomeCubit._recompute` never clears `snapshot` on a failure (see
      // `copyWith`'s `snapshot ?? this.snapshot`), so the reachable failure
      // state is "a later fetch failed after an earlier one already landed" —
      // hero/quick access keep the last good snapshot, only the recent-feed
      // sliver swaps to `HomeFailureView`. A `HomeState` with `snapshot: null`
      // and `status: failure` (the very first load failing) is NOT safely
      // renderable: `HomePage` calls `state.spending!` for any non-loading
      // status, which null-check-crashes on that combination — a real bug,
      // reported separately, not modeled here since a golden can't capture a
      // crash.
      await golden(
        tester,
        readyWith([buildActivity(id: 'tx-1', categoryName: 'Mercado')])
            .copyWith(status: HomeStatus.failure),
        'error_$suffix',
        brightness: brightness,
      );
    });

    // Criterio 5/6/7/8: los 4 estados del hero que "with budget progress"
    // (sano) no cubre — al límite, límite exacto, riesgo de sobregiro
    // proyectado y sobregasto real. Cada uno resuelve `HomeHeroState` desde
    // `BudgetProgress` puro, sin overrides manuales.
    testWidgets('hero: al límite, 97% sin tinte de color ($suffix)',
        (tester) async {
      await golden(
        tester,
        readyWith(
          [buildActivity(id: 'tx-1', categoryName: 'Mercado')],
          budgetProgress: buildHomeBudgetProgress(
            amountMinor: 100000,
            spentMinor: 97000,
            daysLeft: 2,
          ),
        ),
        'hero_near_limit_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'hero: en el límite exacto, 100% — solo la barra pasa a '
        'on-primary-alert ($suffix)', (tester) async {
      await golden(
        tester,
        readyWith(
          [buildActivity(id: 'tx-1', categoryName: 'Mercado')],
          budgetProgress: buildHomeBudgetProgress(
            amountMinor: 100000,
            spentMinor: 100000,
            daysLeft: 0,
          ),
        ),
        'hero_at_limit_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'hero: riesgo de sobregiro proyectado — 2 tramos + Risk Note '
        '($suffix)', (tester) async {
      await golden(
        tester,
        readyWith(
          [buildActivity(id: 'tx-1', categoryName: 'Mercado')],
          budgetProgress: BudgetWithProgress(
            budget: buildHomeBudgetProgress().budget,
            scope: buildHomeBudgetProgress().scope,
            window: buildHomeBudgetProgress().window,
            progress: const BudgetProgress(
              amountMinor: 600000,
              spentMinor: 300000,
              scheduledMinor: 400000,
              daysLeft: 12,
            ),
          ),
        ),
        'hero_scheduled_overspend_risk_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'hero: sobregasto real — kicker "Excedido por", monto 32px/800 + '
        'circle-minus, barra llena ($suffix)', (tester) async {
      await golden(
        tester,
        readyWith(
          [buildActivity(id: 'tx-1', categoryName: 'Mercado')],
          budgetProgress: buildHomeBudgetProgress(
            amountMinor: 600000,
            spentMinor: 700000,
            daysLeft: 0,
          ),
        ),
        'hero_overspent_$suffix',
        brightness: brightness,
      );
    });

    // Criterio 10: las 3 variantes de la card de IA que "with data, no
    // session"/"with data, signed in" no cubren — con insight sin cola, con
    // cola (contador "1 de N"), y el insight forzado "crea un presupuesto"
    // del estado hero "sin presupuesto".
    testWidgets('ai card: insight sin cola, con link "Ahora no" ($suffix)',
        (tester) async {
      await golden(
        tester,
        readyWith([buildActivity(id: 'tx-1', categoryName: 'Mercado')])
            .copyWith(
          aiInsight: const HomeAiInsight(
            type: HomeAiInsightType.spendingVsAverage,
            percentDelta: 22,
          ),
        ),
        'ai_card_insight_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('ai card: insight con cola, contador "1 de N" ($suffix)',
        (tester) async {
      await golden(
        tester,
        readyWith([buildActivity(id: 'tx-1', categoryName: 'Mercado')])
            .copyWith(
          aiInsight: const HomeAiInsight(
            type: HomeAiInsightType.budgetProjectionRisk,
            overageMinor: 45000,
            currency: 'COP',
            queuePosition: 1,
            queueLength: 3,
          ),
        ),
        'ai_card_insight_queue_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'ai card: sin presupuesto fuerza el insight "crea un presupuesto" '
        '($suffix)', (tester) async {
      await golden(
        tester,
        readyWith([buildActivity(id: 'tx-1', categoryName: 'Mercado')])
            .copyWith(
          hasAnyBudget: false,
          aiInsight: const HomeAiInsight.createBudget(),
        ),
        'ai_card_create_budget_$suffix',
        brightness: brightness,
      );
    });
  }
}
