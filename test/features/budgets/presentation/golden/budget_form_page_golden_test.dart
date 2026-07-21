import 'package:billetudo/features/budgets/domain/entities/budget.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_form_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_form_state.dart';
import 'package:billetudo/features/budgets/presentation/pages/budget_form_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockBudgetFormCubit extends MockCubit<BudgetFormState>
    implements BudgetFormCubit {}

/// The create/edit budget form.
///
/// Pencil rows (`design-system/billetudo/pages/presupuestos.md`):
/// `form_new_empty` and `form_new_filled` → `a3gGPM` / `AHGQc` (Formulario —
/// Nuevo presupuesto; empty is the CTA-disabled gate of HU-01, filled is the
/// designed frame with data) ·
/// `form_one_off` → `C6SRE` / `c13OZ` (Ref. bloque "Repetir → Una única vez":
/// sin Periodicidad, con Inicio + Fin obligatorio) ·
/// `form_scope_all` → `yfy35` / `u6RBA9` (Ref. estado "Todo" — global, las
/// filas Cuentas/Categorías ocultas). `form_new_filled` es también el caso
/// "Personalizado" del mismo bloque: al haber alcance seleccionado el form
/// revela las dos filas.
///
/// States with **no row of their own in the spec table**, flagged for the
/// audit: `form_edit` (mismo frame con título "Editar presupuesto" y CTA
/// "Guardar cambios", HU-09), `form_repeat_until_date` ("Repetir hasta → Hasta
/// una fecha", que revela el selector de fecha), `form_threshold_off`
/// ("No avisarme", HU-08) y `form_loading` (`BudgetFormSkeletonView`: el
/// esqueleto de los campos mientras carga el form de edición, no un spinner).
void main() {
  late MockBudgetFormCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() {
    cubit = MockBudgetFormCubit();
  });

  Future<void> golden(
    WidgetTester tester,
    BudgetFormState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
    double height = 1200,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<BudgetFormCubit>.value(
        value: cubit,
        child: const BudgetFormPage(),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: height),
      settle: settle,
    );
    await expectLater(
      find.byType(BudgetFormPage),
      matchesGoldenFile('goldens/budget_form_page_$name.png'),
    );
  }

  /// A fully typed-in periodic budget with a custom scope: long real name,
  /// a 7-figure COP amount and a real catalog icon (`credit-card`).
  final filled = BudgetFormState(
    status: BudgetFormStatus.ready,
    name: 'Tarjeta de crédito Bancolombia',
    icon: 'credit-card',
    amountMinor: 450000000,
    startDate: DateTime(2025, 7, 21),
    accountIds: const {'acc-bancolombia', 'acc-nequi'},
    categoryIds: const {'cat-mercado', 'cat-restaurantes', 'cat-domicilios'},
  );

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('nuevo, vacío (CTA siempre activo) ($suffix)', (tester) async {
      await golden(
        tester,
        BudgetFormState.initial(DateTime(2025, 7, 21)),
        'form_new_empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('nuevo, diligenciado con alcance personalizado ($suffix)',
        (tester) async {
      await golden(
        tester,
        filled,
        'form_new_filled_$suffix',
        brightness: brightness,
        height: 1300,
      );
    });

    testWidgets('alcance "Todo" (global): sin filas de alcance ($suffix)',
        (tester) async {
      await golden(
        tester,
        BudgetFormState(
          status: BudgetFormStatus.ready,
          name: 'Gastos fijos del hogar',
          icon: 'house',
          amountMinor: 320000000,
          startDate: DateTime(2025, 7),
        ),
        'form_scope_all_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('repetir → una única vez (Inicio + Fin) ($suffix)',
        (tester) async {
      await golden(
        tester,
        BudgetFormState(
          status: BudgetFormStatus.ready,
          name: 'Remodelación de la cocina del apartamento',
          icon: 'house',
          amountMinor: 1250000000,
          recurring: false,
          period: BudgetPeriod.custom,
          startDate: DateTime(2025, 6, 15),
          endDate: DateTime(2025, 9, 30),
        ),
        'form_one_off_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('periódico con "Repetir hasta → Hasta una fecha" ($suffix)',
        (tester) async {
      await golden(
        tester,
        BudgetFormState(
          status: BudgetFormStatus.ready,
          name: 'Mercado y domicilios del mes',
          icon: 'shopping-cart',
          amountMinor: 185000000,
          period: BudgetPeriod.biweekly,
          startDate: DateTime(2025, 7),
          endDate: DateTime(2026, 6, 30),
        ),
        'form_repeat_until_date_$suffix',
        brightness: brightness,
        height: 1300,
      );
    });

    testWidgets('umbral en "No avisarme" ($suffix)', (tester) async {
      await golden(
        tester,
        BudgetFormState(
          status: BudgetFormStatus.ready,
          name: 'Restaurantes y salidas con amigos',
          icon: 'utensils-crossed',
          amountMinor: 90000000,
          startDate: DateTime(2025, 7),
          alertThresholdPct: null,
        ),
        'form_threshold_off_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('editar presupuesto (prellenado) ($suffix)', (tester) async {
      await golden(
        tester,
        BudgetFormState(
          status: BudgetFormStatus.ready,
          id: 'bud-tarjeta',
          name: 'Tarjeta de crédito Bancolombia',
          icon: 'credit-card',
          amountMinor: 450000000,
          startDate: DateTime(2025, 7, 21),
          accountIds: const {'acc-bancolombia'},
        ),
        'form_edit_$suffix',
        brightness: brightness,
        height: 1300,
      );
    });

    testWidgets('cargando el form de edición ($suffix)', (tester) async {
      await golden(
        tester,
        BudgetFormState.loading(),
        'form_loading_$suffix',
        brightness: brightness,
        height: 844,
      );
    });
  }
}
