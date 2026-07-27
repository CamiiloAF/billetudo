import 'package:billetudo/features/budgets/presentation/cubit/archived_budgets_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/archived_budgets_state.dart';
import 'package:billetudo/features/budgets/presentation/pages/archived_budgets_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import 'budget_golden_fixtures.dart';

class MockArchivedBudgetsCubit extends MockCubit<ArchivedBudgetsState>
    implements ArchivedBudgetsCubit {}

/// The closed-budgets history.
///
/// Pencil rows (`design-system/billetudo/pages/presupuestos.md`):
/// `history_with_data` → `KfPyk` / `g2qP7` (Histórico de presupuestos
/// cerrados; cubre el componente `Archived Budget Row` `Ote7d` en sus dos
/// resultados: dentro del monto y excedido con `circle-minus` en
/// `$expense-text`).
///
/// States with **no row of their own in the spec table**, flagged for the
/// audit: `history_empty` (`EmptyState` con `archive`, centrado bajo el
/// subheader y con subtítulo, igual que el vacío de la lista `Zqsi1`),
/// `history_loading` (subheader + 4× `Archived Budget Skeleton Row`, como
/// `rI2bL/KqkhS`) y `history_error` (`BudgetsErrorView`).
void main() {
  late MockArchivedBudgetsCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() {
    cubit = MockArchivedBudgetsCubit();
  });

  Future<void> golden(
    WidgetTester tester,
    ArchivedBudgetsState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<ArchivedBudgetsCubit>.value(
        value: cubit,
        child: const ArchivedBudgetsPage(),
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(ArchivedBudgetsPage),
      matchesGoldenFile('goldens/archived_budgets_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('histórico con datos ($suffix)', (tester) async {
      await golden(
        tester,
        ArchivedBudgetsState(
          status: ArchivedBudgetsStatus.ready,
          budgets: archivedEntries,
        ),
        'history_with_data_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('histórico vacío ($suffix)', (tester) async {
      await golden(
        tester,
        const ArchivedBudgetsState(status: ArchivedBudgetsStatus.ready),
        'history_empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('histórico con error ($suffix)', (tester) async {
      await golden(
        tester,
        const ArchivedBudgetsState(status: ArchivedBudgetsStatus.failure),
        'history_error_$suffix',
        brightness: brightness,
      );
    });
  }

  // Loading renders skeleton rows only (no animation), so it settles like any
  // other state; kept separate for readability.
  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('histórico en carga (skeleton) ($suffix)', (tester) async {
      await golden(
        tester,
        const ArchivedBudgetsState(),
        'history_loading_$suffix',
        brightness: brightness,
      );
    });
  }
}
