import 'package:billetudo/features/goals/domain/entities/goal_draft.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_form_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_form_state.dart';
import 'package:billetudo/features/goals/presentation/pages/goal_form_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../../accounts/account_fixtures.dart';

class MockGoalFormCubit extends MockCubit<GoalFormState>
    implements GoalFormCubit {}

/// Crear / editar meta (HU-01/HU-02/HU-08): the objective amount as the
/// héroe, name, optional linked account (locks the currency), optional
/// fecha objetivo, and — on create only — an optional "¿Ya tienes algo
/// ahorrado?" starting figure. Editing reveals "Eliminar meta" and hides the
/// initial-saved field.
///
/// States captured: create (empty), create with a linked account (currency
/// locked pill), edit (prefilled, shows delete), and the three inline
/// validation errors (name, target amount, target date). Each in light and
/// dark.
void main() {
  late MockGoalFormCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() {
    cubit = MockGoalFormCubit();
    when(() => cubit.stream)
        .thenAnswer((_) => const Stream<GoalFormState>.empty());
  });

  final accounts = [
    buildAccountWithBalance(
      account: buildAccount(id: 'a1', name: 'Bancolombia'),
      balanceMinor: 3450000,
    ),
  ];

  Future<void> golden(
    WidgetTester tester,
    GoalFormState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<GoalFormCubit>.value(
        value: cubit,
        child: const GoalFormPage(),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: 1400),
    );
    await expectLater(
      find.byType(GoalFormPage),
      matchesGoldenFile('goldens/goal_form_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('crear: vacío ($suffix)', (tester) async {
      await golden(
        tester,
        const GoalFormState(status: GoalFormStatus.ready),
        'create_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('crear: con cuenta vinculada (moneda bloqueada) ($suffix)',
        (tester) async {
      await golden(
        tester,
        GoalFormState(
          status: GoalFormStatus.ready,
          name: 'Viaje a Cartagena',
          targetMinor: 3000000,
          accountId: 'a1',
          accounts: accounts,
        ),
        'create_with_account_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('editar: prellenado, con eliminar ($suffix)', (tester) async {
      await golden(
        tester,
        GoalFormState(
          status: GoalFormStatus.ready,
          id: 'g1',
          name: 'Fondo de emergencia',
          targetMinor: 5000000,
          targetDate: DateTime(2026, 12, 1),
          accounts: accounts,
        ),
        'edit_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('crear: error de nombre requerido ($suffix)', (tester) async {
      await golden(
        tester,
        const GoalFormState(
          status: GoalFormStatus.ready,
          targetMinor: 500000,
          failedField: GoalDraft.fieldName,
        ),
        'name_error_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('crear: error de objetivo en 0 ($suffix)', (tester) async {
      await golden(
        tester,
        const GoalFormState(
          status: GoalFormStatus.ready,
          name: 'Portátil nuevo',
          failedField: GoalDraft.fieldTargetMinor,
        ),
        'target_error_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('crear: error de fecha objetivo pasada ($suffix)',
        (tester) async {
      await golden(
        tester,
        GoalFormState(
          status: GoalFormStatus.ready,
          name: 'Portátil nuevo',
          targetMinor: 500000,
          targetDate: DateTime(2020, 1, 1),
          failedField: GoalDraft.fieldTargetDate,
        ),
        'target_date_error_$suffix',
        brightness: brightness,
      );
    });
  }
}
