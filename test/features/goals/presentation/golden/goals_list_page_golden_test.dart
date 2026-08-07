import 'package:billetudo/features/goals/domain/entities/goal_momentum.dart';
import 'package:billetudo/features/goals/domain/entities/goal_with_progress.dart';
import 'package:billetudo/features/goals/presentation/cubit/goals_list_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goals_list_state.dart';
import 'package:billetudo/features/goals/presentation/pages/goals_list_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    accountName: 'Ahorros Bancolombia',
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

  // HU-15: the list header's momentum, shown on top of the list (never a
  // monetary total across goals). Two variants — an active streak with a
  // nearby milestone, and a broken one (`zJQwe`) — separate from `goals`
  // above so the existing "with data" baseline stays untouched.
  final momentumActiveGoals = [
    buildGoalWithProgress(
      goal: buildGoal(id: 'g1', name: 'Viaje a Cartagena', targetMinor: 3000000),
      savedMinor: 1200000,
      displayedPercent: 40,
      momentum: const GoalMomentum(streakWeeks: 6),
    ),
    buildGoalWithProgress(
      goal: buildGoal(
        id: 'g2',
        name: 'Computador nuevo',
        targetMinor: 4500000,
        lastMilestonePct: 25,
      ),
      savedMinor: 3375000,
      displayedPercent: 75,
      momentum: const GoalMomentum(
        streakWeeks: 2,
        nextMilestonePct: 50,
        amountToNextMilestoneMinor: 225000,
      ),
    ),
  ];

  // HU-12: lista filtrada por cuenta (`qFX42`/`CnkG9`) — the removable
  // "Metas en <cuenta>" chip active, coherence signal for that account still
  // shown underneath it, and archived goals' link hidden while filtered.
  final filteredGoals = [
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
        id: 'g3',
        name: 'Colchón de emergencia',
        targetMinor: 4000000,
        accountId: 'a1',
      ),
      savedMinor: 900000,
      displayedPercent: 22,
      coherence: coherenceSignal,
    ),
  ];

  final momentumBrokenGoals = [
    buildGoalWithProgress(
      goal: buildGoal(id: 'g1', name: 'Viaje a Cartagena', targetMinor: 3000000),
      savedMinor: 1200000,
      displayedPercent: 40,
      momentum: const GoalMomentum(
        streakWeeks: 0,
        weeksSinceLastContribution: 3,
      ),
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
          onAddGoal: ([_]) {},
          onOpenGoal: (_) {},
          onOpenArchived: () {},
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

    testWidgets(
        'filtrada por cuenta (HU-12): chip removible + señal de coherencia ($suffix)',
        (tester) async {
      await golden(
        tester,
        GoalsListState(
          status: GoalsListStatus.ready,
          goals: filteredGoals,
          filterAccountId: 'a1',
          filterAccountName: 'Ahorros Bancolombia',
        ),
        'filtered_by_account_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'con momentum: racha activa + próximo hito (HU-15) ($suffix)',
        (tester) async {
      await golden(
        tester,
        GoalsListState(
          status: GoalsListStatus.ready,
          goals: momentumActiveGoals,
        ),
        'momentum_active_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('con momentum: racha rota, tono neutro (HU-15) ($suffix)',
        (tester) async {
      await golden(
        tester,
        GoalsListState(
          status: GoalsListStatus.ready,
          goals: momentumBrokenGoals,
        ),
        'momentum_broken_$suffix',
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

    // HU-03 (`design-system/billetudo/pages/minitutoriales.md`): Metas'
    // header gained a "⋮" that opens `GoalsMenuSheet`, whose only row is
    // "Ver ayuda" — captured through a real tap so the golden shows the
    // sheet + scrim over the page, same as `budgets_page_menus_golden_test`.
    testWidgets('menú ⋮ (Ver ayuda) ($suffix)', (tester) async {
      when(() => cubit.state).thenReturn(
        GoalsListState(status: GoalsListStatus.ready, goals: goals),
      );
      await pumpGolden(
        tester,
        BlocProvider<GoalsListCubit>.value(
          value: cubit,
          child: GoalsListPage(
            onAddGoal: ([_]) {},
            onOpenGoal: (_) {},
            onOpenArchived: () {},
          ),
        ),
        brightness: brightness,
        size: tallGoldenPhoneSize(height: 1700),
      );
      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/goals_list_page_menu_$suffix.png'),
      );
    });
  }
}
