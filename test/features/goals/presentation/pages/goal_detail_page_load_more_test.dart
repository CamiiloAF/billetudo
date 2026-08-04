import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/load_more_button.dart';
import 'package:billetudo/features/goals/domain/entities/goal_projection.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_detail_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_detail_state.dart';
import 'package:billetudo/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:billetudo/features/goals/presentation/widgets/goal_movement_row.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../goals_presentation_fixtures.dart';

class MockGoalDetailCubit extends MockCubit<GoalDetailState>
    implements GoalDetailCubit {}

/// The 8/+8 "Ver más" pagination (replaces the old peek-of-2 /
/// expand-all-at-once `movementsExpanded`) at the real page level, mirroring
/// `debt_detail_page_test.dart`'s equivalent group — this is the widget-level
/// counterpart of `goal_detail_cubit_test.dart`'s state assertions.
void main() {
  late MockGoalDetailCubit cubit;

  setUp(() => cubit = MockGoalDetailCubit());

  GoalDetailState buildManyMovementsState(int rowCount) {
    final history = List.generate(
      rowCount,
      (index) => buildGoalContribution(
        id: 'm$index',
        amountMinor: 10000 + index * 1000,
        date: DateTime(2026, 7, 20).subtract(Duration(days: index)),
      ),
    );
    return GoalDetailState(
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
        history: history,
      ),
    );
  }

  Future<void> pump(WidgetTester tester, GoalDetailState state) async {
    await tester.binding.setSurfaceSize(const Size(420, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<GoalDetailCubit>.value(
          value: cubit,
          child: GoalDetailPage(
            onEdit: (_) {},
            onOpenCompletedCelebration: (_) {},
            onOpenMilestone: (_, __) {},
          ),
        ),
      ),
    );
  }

  testWidgets('con 8 movimientos o menos no muestra el botón "Ver más"',
      (tester) async {
    await pump(tester, buildManyMovementsState(8));

    expect(find.byType(GoalMovementRow), findsNWidgets(8));
    expect(find.byType(LoadMoreButton), findsNothing);
  });

  testWidgets(
      'con más de 8 revela sólo la primera página y el botón carga 8 más '
      'por toque, nunca todos de un tiro', (tester) async {
    when(cubit.loadMoreMovements).thenReturn(null);
    await pump(tester, buildManyMovementsState(20));

    expect(find.byType(GoalMovementRow), findsNWidgets(8));
    expect(find.byType(LoadMoreButton), findsOneWidget);

    await tester.tap(find.byType(LoadMoreButton));
    await tester.pump();

    verify(cubit.loadMoreMovements).called(1);
  });
}
