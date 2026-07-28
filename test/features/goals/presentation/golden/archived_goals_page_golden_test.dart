import 'package:billetudo/features/goals/presentation/cubit/archived_goals_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/archived_goals_state.dart';
import 'package:billetudo/features/goals/presentation/pages/archived_goals_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../goals_presentation_fixtures.dart';

class MockArchivedGoalsCubit extends MockCubit<ArchivedGoalsState>
    implements ArchivedGoalsCubit {}

/// HU-09's "Metas archivadas": a flat list of paused goals, each with a
/// one-tap "Desarchivar", or the empty state when there are none.
///
/// States captured: with data (two archived goals), empty, loading and
/// error. Each in light and dark.
void main() {
  late MockArchivedGoalsCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockArchivedGoalsCubit());

  final goals = [
    buildGoalWithProgress(
      goal: buildGoal(
        id: 'g1',
        name: 'Portátil nuevo',
        targetMinor: 5000000,
        archivedAt: DateTime(2026, 6, 1),
      ),
      savedMinor: 900000,
      displayedPercent: 18,
    ),
    buildGoalWithProgress(
      goal: buildGoal(
        id: 'g2',
        name: 'Fondo para el carro',
        targetMinor: 20000000,
        archivedAt: DateTime(2026, 5, 1),
      ),
      savedMinor: 4000000,
      displayedPercent: 20,
    ),
  ];

  Future<void> golden(
    WidgetTester tester,
    ArchivedGoalsState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<ArchivedGoalsCubit>.value(
        value: cubit,
        child: ArchivedGoalsPage(onOpenGoal: (_) {}),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: 1000),
      settle: settle,
    );
    await expectLater(
      find.byType(ArchivedGoalsPage),
      matchesGoldenFile('goldens/archived_goals_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        const ArchivedGoalsState(),
        'loading_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('con datos ($suffix)', (tester) async {
      await golden(
        tester,
        ArchivedGoalsState(status: ArchivedGoalsStatus.ready, goals: goals),
        'with_data_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('vacío ($suffix)', (tester) async {
      await golden(
        tester,
        const ArchivedGoalsState(status: ArchivedGoalsStatus.ready),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('error ($suffix)', (tester) async {
      await golden(
        tester,
        const ArchivedGoalsState(status: ArchivedGoalsStatus.failure),
        'error_$suffix',
        brightness: brightness,
      );
    });
  }
}
