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
/// treatment, no CTAs), and archived (no CTAs, no quick-amount row) — each in
/// light and dark.
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
  }
}
