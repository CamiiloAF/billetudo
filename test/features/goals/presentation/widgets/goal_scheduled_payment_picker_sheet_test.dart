import 'package:billetudo/core/error/failure.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_recurring_contribution_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_recurring_contribution_state.dart';
import 'package:billetudo/features/goals/presentation/widgets/goal_scheduled_payment_picker_sheet.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../../scheduled_payments/scheduled_payment_fixtures.dart';

class MockGoalRecurringContributionCubit
    extends MockCubit<GoalRecurringContributionState>
    implements GoalRecurringContributionCubit {}

/// HU-16's "Enlazar existente" picker (`RX8C9`/`LSwr8`): behavior coverage
/// complementing the golden — empty state message and that selecting a card
/// dispatches `linkExisting` with that template's id (AC4), never a
/// duplicate.
void main() {
  late MockGoalRecurringContributionCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() {
    cubit = MockGoalRecurringContributionCubit();
    when(() => cubit.linkExisting(any())).thenAnswer((_) async => true);
  });

  GoalRecurringContributionState stateWith({
    List<ScheduledPaymentSummary> linkablePayments = const [],
  }) =>
      GoalRecurringContributionState(
        goalId: 'g1',
        goalName: 'Viaje a Cartagena',
        currency: 'COP',
        status: GoalRecurringContributionStatus.ready,
        linkablePayments: linkablePayments,
      );

  Future<void> pump(WidgetTester tester, GoalRecurringContributionState state)
      async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<GoalRecurringContributionCubit>.value(
        value: cubit,
        child: GoalScheduledPaymentPickerSheetBody(state: state),
      ),
      brightness: Brightness.light,
    );
  }

  testWidgets(
      'sin pagos programados enlazables muestra el mensaje de estado vacío',
      (tester) async {
    await pump(tester, stateWith());

    expect(
      find.text('No tienes pagos programados disponibles para enlazar.'),
      findsOneWidget,
    );
  });

  testWidgets('seleccionar una plantilla llama linkExisting con su id',
      (tester) async {
    final linkable = ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(
        id: 'sp-42',
        amountMinor: 44900,
        frequency: ScheduledPaymentFrequency.monthly,
      ),
      accountName: 'Nequi',
      categoryName: 'Suscripciones',
    );
    await pump(tester, stateWith(linkablePayments: [linkable]));

    await tester.tap(find.text('Nequi · Suscripciones'));
    await tester.pumpAndSettle();

    verify(() => cubit.linkExisting('sp-42')).called(1);
  });

  testWidgets('un fallo al enlazar muestra el mensaje de error',
      (tester) async {
    await pump(
      tester,
      stateWith().copyWith(
        status: GoalRecurringContributionStatus.failure,
        failure: () => const ValidationFailure('nope'),
      ),
    );

    expect(
      find.text('No pudimos enlazar el pago programado. Intenta de nuevo.'),
      findsOneWidget,
    );
  });
}
