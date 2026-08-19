import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/goals/domain/entities/goal_projection.dart';
import 'package:billetudo/features/goals/domain/usecases/create_goal_recurring_contribution.dart';
import 'package:billetudo/features/goals/domain/usecases/get_linkable_scheduled_payments.dart';
import 'package:billetudo/features/goals/domain/usecases/link_scheduled_payment_to_goal.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_detail_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_detail_state.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_recurring_contribution_cubit.dart';
import 'package:billetudo/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:billetudo/features/goals/presentation/widgets/goal_recurring_contribution_entry_card.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../goals_presentation_fixtures.dart';

class MockGoalDetailCubit extends MockCubit<GoalDetailState>
    implements GoalDetailCubit {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockCreateGoalRecurringContribution extends Mock
    implements CreateGoalRecurringContribution {}

class MockLinkScheduledPaymentToGoal extends Mock
    implements LinkScheduledPaymentToGoal {}

class MockGetLinkableScheduledPayments extends Mock
    implements GetLinkableScheduledPayments {}

/// HU-16's entry point in the goal detail (`hWrGw`/`D3Apm1`): the "Configura
/// un aporte recurrente" card between Aportar/Retirar and Aporte rápido, and
/// the enlazar/crear decision it opens. Mirrors
/// `debt_detail_page_test.dart`'s equivalent group for
/// `DebtConfigureInstallmentCard`.
void main() {
  late MockGoalDetailCubit cubit;
  late MockWatchAccounts watchAccounts;
  late MockCreateGoalRecurringContribution createRecurringContribution;
  late MockLinkScheduledPaymentToGoal linkScheduledPaymentToGoal;
  late MockGetLinkableScheduledPayments getLinkablePayments;
  String? pushedGoalRecurringContributionRoute;
  GoalRecurringContributionContext? pushedExtra;

  final activeState = GoalDetailState(
    status: GoalDetailStatus.ready,
    detail: buildGoalDetail(
      progress: buildGoalWithProgress(
        goal: buildGoal(id: 'g1', name: 'Viaje a Cartagena'),
        savedMinor: 1800000,
        displayedPercent: 60,
      ),
      projection: const GoalProjection(
        kind: GoalProjectionKind.insufficientHistory,
      ),
      history: const [],
    ),
  );

  final archivedState = GoalDetailState(
    status: GoalDetailStatus.ready,
    detail: buildGoalDetail(
      progress: buildGoalWithProgress(
        goal: buildGoal(id: 'g2', name: 'Meta archivada', archivedAt: DateTime(2026)),
        savedMinor: 100000,
        displayedPercent: 20,
      ),
      projection: const GoalProjection(
        kind: GoalProjectionKind.insufficientHistory,
      ),
      history: const [],
    ),
  );

  setUp(() {
    cubit = MockGoalDetailCubit();
    watchAccounts = MockWatchAccounts();
    createRecurringContribution = MockCreateGoalRecurringContribution();
    linkScheduledPaymentToGoal = MockLinkScheduledPaymentToGoal();
    getLinkablePayments = MockGetLinkableScheduledPayments();
    pushedGoalRecurringContributionRoute = null;
    pushedExtra = null;

    when(() => watchAccounts())
        .thenAnswer((_) => Stream.value(const Right(<AccountWithBalance>[])));
    when(() => getLinkablePayments()).thenAnswer(
      (_) => Stream.value(const Right(<ScheduledPaymentSummary>[])),
    );

    getIt.registerFactory<GoalRecurringContributionCubit>(
      () => GoalRecurringContributionCubit(
        watchAccounts,
        createRecurringContribution,
        linkScheduledPaymentToGoal,
        getLinkablePayments,
      ),
    );
  });

  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester, GoalDetailState state) async {
    await tester.binding.setSurfaceSize(const Size(420, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(() => cubit.state).thenReturn(state);

    final router = GoRouter(
      initialLocation: '/metas/${state.detail!.progress.goal.id}',
      routes: [
        GoRoute(
          path: '/metas/:id',
          builder: (context, goRouterState) =>
              BlocProvider<GoalDetailCubit>.value(
            value: cubit,
            child: GoalDetailPage(
              onEdit: (_) {},
              onOpenCompletedCelebration: (_) {},
              onOpenMilestone: (_, __) {},
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.goalRecurringContribution(':id'),
          builder: (context, goRouterState) {
            pushedGoalRecurringContributionRoute = goRouterState.uri.toString();
            pushedExtra =
                goRouterState.extra as GoalRecurringContributionContext?;
            return const Scaffold(body: Text('aporte-recurrente-form'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('meta activa muestra la card de aporte recurrente',
      (tester) async {
    await pump(tester, activeState);

    expect(find.byType(GoalRecurringContributionEntryCard), findsOneWidget);
    expect(find.text('Configura un aporte recurrente'), findsOneWidget);
  });

  testWidgets('meta archivada no muestra la card de aporte recurrente',
      (tester) async {
    await pump(tester, archivedState);

    expect(find.byType(GoalRecurringContributionEntryCard), findsNothing);
  });

  testWidgets(
      'tocar la card abre la decisión y "Crear uno nuevo" navega al form '
      'con el goalId/goalName/currency correctos', (tester) async {
    await pump(tester, activeState);

    await tester.tap(find.byType(GoalRecurringContributionEntryCard));
    await tester.pumpAndSettle();

    expect(find.text('Crear uno nuevo'), findsOneWidget);
    expect(find.text('Enlazar un pago programado existente'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('goal-recurring-contribution-create-new')),
    );
    await tester.pumpAndSettle();

    expect(pushedGoalRecurringContributionRoute, '/metas/g1/aporte-recurrente');
    expect(pushedExtra?.goalId, 'g1');
    expect(pushedExtra?.goalName, 'Viaje a Cartagena');
    expect(find.text('aporte-recurrente-form'), findsOneWidget);
  });

  testWidgets(
      'tocar la card y elegir "Enlazar existente" abre el picker de pagos '
      'programados', (tester) async {
    await pump(tester, activeState);

    await tester.tap(find.byType(GoalRecurringContributionEntryCard));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('goal-recurring-contribution-link-existing')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enlazar un pago programado'), findsOneWidget);
  });
}
