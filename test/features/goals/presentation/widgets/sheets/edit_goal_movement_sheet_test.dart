import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution_draft.dart';
import 'package:billetudo/features/goals/domain/usecases/update_goal_movement.dart';
import 'package:billetudo/features/goals/presentation/cubit/edit_goal_movement_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/edit_goal_movement_state.dart';
import 'package:billetudo/features/goals/presentation/widgets/goal_amount_hero_field.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/edit_goal_movement_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../support/fake_note_suggestions.dart';
import '../../../../../support/golden_helpers.dart';
import '../../goals_presentation_fixtures.dart';

class MockUpdateGoalMovement extends Mock implements UpdateGoalMovement {}

/// `EditGoalMovementSheetBody` built through the REAL cubit (not a
/// `MockCubit` fixed state), reproducing the actual failure -> `submit()`
/// flow, so this catches a regression where the anchoring logic breaks
/// wiring rather than just its pure `isAmountFailure` getter (already unit
/// tested in `edit_goal_movement_cubit_test.dart`) or its pixels (already
/// golden tested in `goals_sheets_golden_test.dart`).
void main() {
  late MockUpdateGoalMovement updateGoalMovement;

  setUp(() {
    updateGoalMovement = MockUpdateGoalMovement();
    registerFakeNoteSuggestions();
  });

  tearDown(getIt.reset);

  EditGoalMovementCubit buildCubit() =>
      EditGoalMovementCubit(updateGoalMovement)
        ..start(
          buildGoalContribution(
            id: 'm1',
            goalId: 'g1',
            direction: GoalMovementDirection.withdrawal,
            amountMinor: 999999,
            date: DateTime(2026, 7, 15),
          ),
          goalName: 'Viaje a Cartagena',
          currency: 'COP',
        );

  Finder amountFieldErrorText(WidgetTester tester) {
    final field = tester.widget<GoalAmountHeroField>(
      find.byType(GoalAmountHeroField),
    );
    return find.text(field.errorText ?? '');
  }

  testWidgets(
    'una ValidationFailure de fieldAmountMinor ancla el error al campo de '
    'Monto (errorText) y NO muestra el texto genérico suelto',
    (tester) async {
      final cubit = buildCubit();
      when(
        () => updateGoalMovement(
          contributionId: any(named: 'contributionId'),
          amountMinor: any(named: 'amountMinor'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          ValidationFailure(
            'a withdrawal cannot leave the goal\'s saved amount negative',
            field: GoalContributionDraft.fieldAmountMinor,
          ),
        ),
      );

      await tester.pumpWidget(
        wrapForGolden(
          BlocProvider<EditGoalMovementCubit>.value(
            value: cubit,
            child: BlocBuilder<EditGoalMovementCubit, EditGoalMovementState>(
              builder: (context, state) =>
                  EditGoalMovementSheetBody(state: state),
            ),
          ),
          brightness: Brightness.light,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('edit-goal-movement-submit')),
      );
      await tester.pumpAndSettle();

      expect(cubit.state.isAmountFailure, isTrue);
      final heroField = tester.widget<GoalAmountHeroField>(
        find.byType(GoalAmountHeroField),
      );
      expect(heroField.errorText, isNotNull);
      expect(heroField.errorText, isNotEmpty);
      expect(amountFieldErrorText(tester), findsOneWidget);

      // The old generic sheet-level text must be gone for this
      // field-anchored case — the withdraw-specific copy replaces it, it
      // never also shows alongside it.
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
      expect(find.text(l10n.goalMovementError), findsNothing);

      await cubit.close();
    },
  );

  testWidgets(
    'una falla NO atribuible al monto (p.ej. DatabaseFailure) muestra el '
    'texto genérico suelto y deja el campo de Monto sin errorText',
    (tester) async {
      final cubit = buildCubit();
      when(
        () => updateGoalMovement(
          contributionId: any(named: 'contributionId'),
          amountMinor: any(named: 'amountMinor'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).thenAnswer(
        (_) async =>
            const Left(DatabaseFailure('no se pudo guardar el movimiento')),
      );

      await tester.pumpWidget(
        wrapForGolden(
          BlocProvider<EditGoalMovementCubit>.value(
            value: cubit,
            child: BlocBuilder<EditGoalMovementCubit, EditGoalMovementState>(
              builder: (context, state) =>
                  EditGoalMovementSheetBody(state: state),
            ),
          ),
          brightness: Brightness.light,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('edit-goal-movement-submit')),
      );
      await tester.pumpAndSettle();

      expect(cubit.state.isAmountFailure, isFalse);
      final heroField = tester.widget<GoalAmountHeroField>(
        find.byType(GoalAmountHeroField),
      );
      expect(heroField.errorText, isNull);

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
      expect(find.text(l10n.goalMovementError), findsOneWidget);

      await cubit.close();
    },
  );
}
