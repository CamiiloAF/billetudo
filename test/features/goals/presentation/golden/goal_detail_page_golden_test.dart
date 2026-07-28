import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/entities/goal_projection.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_detail_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_detail_state.dart';
import 'package:billetudo/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../goals_presentation_fixtures.dart';

class MockGoalDetailCubit extends MockCubit<GoalDetailState>
    implements GoalDetailCubit {}

/// The goal detail (HU-05/06/07/12/15): arc héroe + "Te faltan $X" +
/// projection, quick-amount chips + Aportar/Retirar, and the movement peek.
///
/// States captured: loading, failure, active (with target date → projected
/// estimate, and a movement history), completed (100%, "capítulo cerrado"
/// treatment, no CTAs), archived (no CTAs, no quick-amount row), the
/// movement peek expanded in-place, every non-"projected" `GoalProjection`
/// kind (insufficient history, no target date, overdue), and an empty
/// history (goal just created, no aportes yet) — each in light and dark.
void main() {
  late MockGoalDetailCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockGoalDetailCubit());

  final activeState = GoalDetailState(
    status: GoalDetailStatus.ready,
    detail: buildGoalDetail(
      progress: buildGoalWithProgress(
        goal: buildGoal(
          id: 'g1',
          name: 'Viaje a Cartagena',
          targetMinor: 3000000,
          targetDate: DateTime(2026, 12, 1),
        ),
        savedMinor: 1800000,
        displayedPercent: 60,
      ),
      projection: GoalProjection(
        kind: GoalProjectionKind.projected,
        estimatedDate: DateTime(2026, 11, 1),
        paceMinorPerMonth: 200000,
      ),
      history: [
        buildGoalContribution(
          id: 'm2',
          amountMinor: 300000,
          date: DateTime(2026, 7, 20),
          note: 'Ahorro de julio',
        ),
        buildGoalContribution(
          id: 'm1',
          amountMinor: 1500000,
          date: DateTime(2026, 6, 1),
        ),
      ],
    ),
  );

  final completedState = GoalDetailState(
    status: GoalDetailStatus.ready,
    detail: buildGoalDetail(
      progress: buildGoalWithProgress(
        goal: buildGoal(
          id: 'g2',
          name: 'Fondo de emergencia',
          targetMinor: 2000000,
          completedAt: DateTime(2026, 6, 1),
          lastMilestonePct: 100,
        ),
        savedMinor: 2000000,
        displayedPercent: 100,
        remainingMinor: 0,
      ),
      history: [
        buildGoalContribution(id: 'm1', amountMinor: 2000000, date: DateTime(2026, 5, 1)),
      ],
    ),
  );

  final archivedState = GoalDetailState(
    status: GoalDetailStatus.ready,
    detail: buildGoalDetail(
      progress: buildGoalWithProgress(
        goal: buildGoal(
          id: 'g3',
          name: 'Portátil nuevo',
          targetMinor: 5000000,
          archivedAt: DateTime(2026, 7, 1),
        ),
        savedMinor: 900000,
        displayedPercent: 18,
      ),
    ),
  );

  // Movimientos expandidos in-place (`p6g6S`/`v6yh8`): more than the 2-row
  // peek, all visible, "Ver todos" gone since it's already expanded.
  final expandedMovementsState = GoalDetailState(
    status: GoalDetailStatus.ready,
    movementsExpanded: true,
    detail: buildGoalDetail(
      progress: buildGoalWithProgress(
        goal: buildGoal(
          id: 'g4',
          name: 'Viaje a Cartagena',
          targetMinor: 3000000,
          targetDate: DateTime(2026, 12, 1),
        ),
        savedMinor: 1800000,
        displayedPercent: 60,
      ),
      projection: GoalProjection(
        kind: GoalProjectionKind.projected,
        estimatedDate: DateTime(2026, 11, 1),
        paceMinorPerMonth: 200000,
      ),
      history: [
        buildGoalContribution(
          id: 'm3',
          amountMinor: 300000,
          date: DateTime(2026, 7, 20),
          note: 'Ahorro de julio',
        ),
        buildGoalContribution(
          id: 'm2',
          amountMinor: 50000,
          direction: GoalMovementDirection.withdrawal,
          date: DateTime(2026, 6, 15),
        ),
        buildGoalContribution(
          id: 'm1',
          amountMinor: 1550000,
          date: DateTime(2026, 6, 1),
        ),
      ],
    ),
  );

  // HU-12's "cuenta con lápida" (`XoGzx`/`Kossf`): the linked account was
  // tombstoned (`Accounts.tombstonedAt`, referential — the goal keeps its
  // `accountId` and full history) — the neutral `GoalAccountUnavailableBanner`
  // shows instead of the usual "Te faltan $X de $Y" caption, and a fresh
  // Aportar/Retirar can only track manually (no account left to move money
  // through).
  final accountTombstonedState = GoalDetailState(
    status: GoalDetailStatus.ready,
    detail: buildGoalDetail(
      progress: buildGoalWithProgress(
        goal: buildGoal(
          id: 'g9',
          name: 'Viaje a Cartagena',
          targetMinor: 3000000,
          targetDate: DateTime(2026, 12, 1),
          accountId: 'a1',
        ),
        savedMinor: 1800000,
        displayedPercent: 60,
      ),
      projection: GoalProjection(
        kind: GoalProjectionKind.projected,
        estimatedDate: DateTime(2026, 11, 1),
        paceMinorPerMonth: 200000,
      ),
      accountTombstoned: true,
      history: [
        buildGoalContribution(
          id: 'm1',
          amountMinor: 1800000,
          date: DateTime(2026, 6, 1),
        ),
      ],
    ),
  );

  // Sin historial suficiente (`xEqbd`/`q2zQv`): fewer than a month of life
  // (or zero movements) — a required monthly contribution replaces the
  // estimated date.
  final insufficientHistoryState = GoalDetailState(
    status: GoalDetailStatus.ready,
    detail: buildGoalDetail(
      progress: buildGoalWithProgress(
        goal: buildGoal(
          id: 'g5',
          name: 'Cámara nueva',
          targetMinor: 2000000,
          targetDate: DateTime(2026, 12, 1),
        ),
        savedMinor: 100000,
        displayedPercent: 5,
      ),
      projection: const GoalProjection(
        kind: GoalProjectionKind.insufficientHistory,
        monthlyContributionNeededMinor: 380000,
      ),
      history: [
        buildGoalContribution(id: 'm1', amountMinor: 100000, date: DateTime(2026, 7, 20)),
      ],
    ),
  );

  // Sin fecha objetivo (`E4jMdn`/`Y3d7wu`): no `targetDate` at all — no date
  // projection is shown.
  final noTargetDateState = GoalDetailState(
    status: GoalDetailStatus.ready,
    detail: buildGoalDetail(
      progress: buildGoalWithProgress(
        goal: buildGoal(
          id: 'g6',
          name: 'Colchón de emergencia',
          targetMinor: 4000000,
        ),
        savedMinor: 1200000,
        displayedPercent: 30,
      ),
      history: [
        buildGoalContribution(id: 'm1', amountMinor: 1200000, date: DateTime(2026, 6, 1)),
      ],
    ),
  );

  // Fecha vencida (`Mnc0Q`/`Vk5Hj`): `targetDate` already passed — no
  // projection, no failure either, just the "fecha ya pasó" copy.
  final overdueState = GoalDetailState(
    status: GoalDetailStatus.ready,
    detail: buildGoalDetail(
      progress: buildGoalWithProgress(
        goal: buildGoal(
          id: 'g7',
          name: 'Curso de inglés',
          targetMinor: 1500000,
          targetDate: DateTime(2026, 6, 1),
        ),
        savedMinor: 700000,
        displayedPercent: 47,
      ),
      projection: const GoalProjection(kind: GoalProjectionKind.overdue),
      history: [
        buildGoalContribution(id: 'm1', amountMinor: 700000, date: DateTime(2026, 3, 1)),
      ],
    ),
  );

  // Historial vacío (`Zbsyb`/`ZOfmE`): meta recién creada, sin aportes —
  // "Retirar" queda deshabilitado (`savedMinor` es 0).
  final emptyHistoryState = GoalDetailState(
    status: GoalDetailStatus.ready,
    detail: buildGoalDetail(
      progress: buildGoalWithProgress(
        goal: buildGoal(
          id: 'g8',
          name: 'Regalo de cumpleaños',
          targetMinor: 800000,
          targetDate: DateTime(2026, 10, 1),
        ),
        savedMinor: 0,
        displayedPercent: 0,
      ),
      projection: const GoalProjection(
        kind: GoalProjectionKind.insufficientHistory,
        monthlyContributionNeededMinor: 267000,
      ),
    ),
  );

  Future<void> golden(
    WidgetTester tester,
    GoalDetailState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<GoalDetailCubit>.value(
        value: cubit,
        child: GoalDetailPage(
          onEdit: (_) {},
          onOpenCompletedCelebration: (_) {},
          onOpenMilestone: (_, __) {},
        ),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: 1400),
      settle: settle,
    );
    await expectLater(
      find.byType(GoalDetailPage),
      matchesGoldenFile('goldens/goal_detail_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        const GoalDetailState(),
        'loading_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('failure ($suffix)', (tester) async {
      await golden(
        tester,
        const GoalDetailState(status: GoalDetailStatus.failure),
        'failure_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('activa: proyección estimada + historial ($suffix)',
        (tester) async {
      await golden(
        tester,
        activeState,
        'active_projected_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('cumplida: 100%, capítulo cerrado ($suffix)', (tester) async {
      await golden(
        tester,
        completedState,
        'completed_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('archivada: sin CTAs de aportar/retirar ($suffix)',
        (tester) async {
      await golden(
        tester,
        archivedState,
        'archived_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('movimientos expandidos in-place ($suffix)', (tester) async {
      await golden(
        tester,
        expandedMovementsState,
        'movements_expanded_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'cuenta con lápida (HU-12): sin cuenta vinculada, aviso neutro ($suffix)',
        (tester) async {
      await golden(
        tester,
        accountTombstonedState,
        'account_tombstoned_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('proyección: historial insuficiente ($suffix)', (tester) async {
      await golden(
        tester,
        insufficientHistoryState,
        'projection_insufficient_history_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('proyección: sin fecha objetivo ($suffix)', (tester) async {
      await golden(
        tester,
        noTargetDateState,
        'projection_no_target_date_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('proyección: fecha vencida ($suffix)', (tester) async {
      await golden(
        tester,
        overdueState,
        'projection_overdue_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('historial vacío: meta recién creada ($suffix)', (tester) async {
      await golden(
        tester,
        emptyHistoryState,
        'history_empty_$suffix',
        brightness: brightness,
      );
    });
  }
}
