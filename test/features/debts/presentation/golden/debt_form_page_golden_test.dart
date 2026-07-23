import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_draft.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_form_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_form_state.dart';
import 'package:billetudo/features/debts/presentation/pages/debt_form_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockDebtFormCubit extends MockCubit<DebtFormState>
    implements DebtFormCubit {}

/// Crear / editar deuda (`dUryC`, variante B "monto héroe", HU-01/HU-05): the
/// opening-balance héroe, the direction toggle, name/counterparty/vencimiento,
/// and the interest card with its Manual/Automático accrual mode. Editing
/// prefills every field and reveals the "Eliminar deuda" link.
///
/// States captured: create (empty), edit (prefilled with an automatic rate,
/// showing the delete link), and the name-required validation error. Each in
/// light and dark.
void main() {
  late MockDebtFormCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() {
    cubit = MockDebtFormCubit();
    when(() => cubit.stream)
        .thenAnswer((_) => const Stream<DebtFormState>.empty());
  });

  Future<void> golden(
    WidgetTester tester,
    DebtFormState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<DebtFormCubit>.value(
        value: cubit,
        child: const DebtFormPage(),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: 1500),
    );
    await expectLater(
      find.byType(DebtFormPage),
      matchesGoldenFile('goldens/debt_form_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('crear: vacío ($suffix)', (tester) async {
      await golden(
        tester,
        const DebtFormState(status: DebtFormStatus.ready),
        'create_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('editar: prellenado con tasa automática ($suffix)',
        (tester) async {
      await golden(
        tester,
        const DebtFormState(
          status: DebtFormStatus.ready,
          id: 'd1',
          direction: DebtDirection.iOwe,
          amountMinor: 4200000000,
          name: 'Crédito vehicular',
          counterparty: 'Banco de Bogotá',
          rateText: '24',
          accrualMode: DebtAccrualMode.auto,
        ),
        'edit_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('crear: error de nombre requerido ($suffix)', (tester) async {
      await golden(
        tester,
        const DebtFormState(
          status: DebtFormStatus.ready,
          amountMinor: 500000,
          failedField: DebtDraft.fieldName,
        ),
        'name_error_$suffix',
        brightness: brightness,
      );
    });
  }
}
