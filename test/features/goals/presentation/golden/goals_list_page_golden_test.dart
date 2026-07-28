import 'package:billetudo/features/goals/domain/entities/goal_with_progress.dart';
import 'package:billetudo/features/goals/presentation/cubit/goals_list_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goals_list_state.dart';
import 'package:billetudo/features/goals/presentation/pages/goals_list_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../goals_presentation_fixtures.dart';

class MockGoalsListCubit extends MockCubit<GoalsListState>
    implements GoalsListCubit {}

/// The goals list (HU-11): a `Page Header` with the add action, then either
/// the empty-state that sells (HU-13, hero copy + 3 starter templates), a
/// flat list of `GoalCard`s with an HU-12 coherence banner on top, a loading
/// skeleton, or an error state.
///
/// States captured: loading, empty/onboarding (starter templates), with data
/// (an active goal with a target date, a completed goal's "capítulo
/// cerrado", and a coherence signal banner), and the load failure. Each in
/// light and dark.
void main() {
  late MockGoalsListCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockGoalsListCubit());

  const coherenceSignal = GoalCoherenceSignal(
    accountId: 'a1',
    totalSavedMinor: 5200000,
    accountBalanceMinor: 4000000,
    currency: 'COP',
  );

  final goals = [
    buildGoalWithProgress(
      goal: buildGoal(
        id: 'g1',
        name: 'Viaje a Cartagena',
        targetMinor: 3000000,
        targetDate: DateTime(2026, 12, 1),
        accountId: 'a1',
      ),
      savedMinor: 1800000,
      displayedPercent: 60,
      coherence: coherenceSignal,
    ),
    buildGoalWithProgress(
      goal: buildGoal(
        id: 'g2',
        name: 'Fondo de emergencia',
        targetMinor: 2000000,
        completedAt: DateTime(2026, 6, 1),
        lastMilestonePct: 100,
      ),
      savedMinor: 2000000,
      displayedPercent: 100,
    ),
    buildGoalWithProgress(
      goal: buildGoal(
        id: 'g3',
        name: 'Portátil nuevo',
        targetMinor: 5000000,
      ),
      savedMinor: 900000,
      displayedPercent: 18,
    ),
  ];

  Future<void> golden(
    WidgetTester tester,
    GoalsListState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<GoalsListCubit>.value(
        value: cubit,
        child: GoalsListPage(
          onAddGoal: () {},
          onOpenGoal: (_) {},
          onOpenArchived: () {},
          onOpenCoherenceAccount: (_) {},
        ),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: 1700),
      settle: settle,
    );
    await expectLater(
      find.byType(GoalsListPage),
      matchesGoldenFile('goldens/goals_list_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        const GoalsListState(),
        'loading_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('empty / onboarding: plantillas (HU-13) ($suffix)',
        (tester) async {
      await golden(
        tester,
        const GoalsListState(status: GoalsListStatus.ready),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'con datos: señal de coherencia + meta activa + meta cumplida ($suffix)',
        (tester) async {
      await golden(
        tester,
        GoalsListState(status: GoalsListStatus.ready, goals: goals),
        'with_data_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('error ($suffix)', (tester) async {
      await golden(
        tester,
        const GoalsListState(status: GoalsListStatus.failure),
        'error_$suffix',
        brightness: brightness,
      );
    });
  }
}
