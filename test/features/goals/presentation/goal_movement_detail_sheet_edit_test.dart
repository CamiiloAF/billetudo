import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/presentation/cubit/edit_goal_movement_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/edit_goal_movement_state.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_movement_detail_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_movement_detail_state.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/goal_movement_detail_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'goals_presentation_fixtures.dart';

class MockGoalMovementDetailCubit extends MockCubit<GoalMovementDetailState>
    implements GoalMovementDetailCubit {}

class MockEditGoalMovementCubit extends MockCubit<EditGoalMovementState>
    implements EditGoalMovementCubit {}

/// Both a money-moving and a tracking-only [GoalContribution] always show
/// Editar+Eliminar together (`DetailActionsRow`): Editar behaves differently
/// under the hood depending on `transactionId`, and this only exercises that
/// branch — `goals_sheets_golden_test.dart` covers the visuals.
void main() {
  late MockGoalMovementDetailCubit detailCubit;
  late MockEditGoalMovementCubit editCubit;

  setUpAll(() {
    registerFallbackValue(buildGoalContribution());
  });

  setUp(() {
    detailCubit = MockGoalMovementDetailCubit();
    when(() => detailCubit.state).thenReturn(
      const GoalMovementDetailState(status: GoalMovementDetailStatus.ready),
    );
    when(() => detailCubit.start(any())).thenAnswer((_) async {});

    editCubit = MockEditGoalMovementCubit();
    when(() => editCubit.state).thenReturn(
      EditGoalMovementState(
        contributionId: 'm1',
        goalId: 'g1',
        goalName: 'Viaje',
        direction: GoalMovementDirection.contribution,
        currency: 'COP',
        date: DateTime(2026, 7, 1),
      ),
    );
    getIt
      ..registerFactory<GoalMovementDetailCubit>(() => detailCubit)
      ..registerFactory<EditGoalMovementCubit>(() => editCubit);
  });

  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester, GoalContribution movement,
          {ValueChanged<String>? onOpenTransaction}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => GoalMovementDetailSheet.show(
                    context,
                    movement: movement,
                    currency: 'COP',
                    goalName: 'Viaje a Cartagena',
                    goalCompleted: false,
                    onOpenTransaction: onOpenTransaction,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets(
      'un movimiento de solo seguimiento: Editar cierra el detalle y abre '
      'EditGoalMovementSheet', (tester) async {
    await pump(
      tester,
      buildGoalContribution(id: 'm1', transactionId: null),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle del movimiento'), findsOneWidget);

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle del movimiento'), findsNothing);
    expect(find.text('Editar movimiento'), findsOneWidget);
  });

  testWidgets(
      'un movimiento con transacción: Editar abre la transacción y no '
      'EditGoalMovementSheet', (tester) async {
    String? openedTransactionId;
    await pump(
      tester,
      buildGoalContribution(id: 'm1', transactionId: 'tx-1'),
      onOpenTransaction: (id) => openedTransactionId = id,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(openedTransactionId, 'tx-1');
    expect(find.text('Editar movimiento'), findsNothing);
  });
}
