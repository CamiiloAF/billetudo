import 'package:billetudo/features/budgets/domain/entities/budget_period_view.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_detail_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_detail_state.dart';
import 'package:billetudo/features/budgets/presentation/pages/budget_detail_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import 'budget_golden_fixtures.dart';

class MockBudgetDetailCubit extends MockCubit<BudgetDetailState>
    implements BudgetDetailCubit {}

/// The budget detail: hero + period activity + the floating period stepper
/// (`PeriodStepperPill`).
///
/// Pencil rows (`design-system/billetudo/pages/presupuestos.md`):
/// `detail_recurring_healthy` → `NloPT` / `vHIu4` (Detalle — recurrente sano) ·
/// `detail_overspent` → `DN0GV` / `zW1s4` (Detalle — sobregasto, familia
/// semántica `expense`) ·
/// `detail_one_off` → `QLn6w` / `A5O26l` (Detalle — una única vez; el stepper
/// lee "Ventana única · termina el <fecha>" y ambos chevrons quedan al 40%).
///
/// States with **no row of their own in the spec table**, flagged for the
/// audit: `detail_loading` (`CircularProgressIndicator` centrado),
/// `detail_error` (`BudgetsErrorView`, el `Error State` compartido),
/// `detail_activity_empty` ("Sin movimientos en este periodo"),
/// `detail_load_more` (paginación perezosa "Ver más" de la actividad, HU-04) y
/// `detail_past_period` (stepper en un periodo pasado, HU-05).
///
/// The whole hero is auditable: its days-left caption now comes from
/// `BudgetProgress.daysLeft` (domain), not from `DateTime.now()` inside
/// `build`, so it is deterministic across runs.
void main() {
  late MockBudgetDetailCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() {
    cubit = MockBudgetDetailCubit();
  });

  Future<void> golden(
    WidgetTester tester,
    BudgetDetailState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
    double height = 844,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<BudgetDetailCubit>.value(
        value: cubit,
        child: BudgetDetailPage(onEdit: (_) {}, onClosed: () {}),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: height),
      settle: settle,
    );
    await expectLater(
      find.byType(BudgetDetailPage),
      matchesGoldenFile('goldens/budget_detail_page_$name.png'),
    );
  }

  BudgetDetailState readyState(
    BudgetWithProgress entry, {
    int activityCount = 4,
    int visibleActivityCount = BudgetDetailState.activityPageSize,
    BudgetPeriodView? view,
  }) =>
      BudgetDetailState(
        status: BudgetDetailStatus.ready,
        budget: entry.budget,
        scope: entry.scope,
        view: view ?? buildPeriodView(entry, activityCount: activityCount),
        visibleActivityCount: visibleActivityCount,
      );

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('detalle recurrente sano ($suffix)', (tester) async {
      await golden(
        tester,
        readyState(healthyEntry),
        'detail_recurring_healthy_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('detalle en sobregasto ($suffix)', (tester) async {
      await golden(
        tester,
        readyState(overspentEntry),
        'detail_overspent_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('detalle de una única vez ($suffix)', (tester) async {
      await golden(
        tester,
        readyState(oneOffEntry),
        'detail_one_off_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('detalle sin movimientos en el periodo ($suffix)',
        (tester) async {
      await golden(
        tester,
        readyState(healthyEntry, activityCount: 0),
        'detail_activity_empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('detalle con "Ver más" (actividad paginada) ($suffix)',
        (tester) async {
      await golden(
        tester,
        readyState(healthyEntry, activityCount: 12),
        'detail_load_more_$suffix',
        brightness: brightness,
        height: 1500,
      );
    });

    testWidgets('detalle en un periodo pasado ($suffix)', (tester) async {
      final entry = healthyEntry;
      await golden(
        tester,
        readyState(
          entry,
          view: BudgetPeriodView(
            window: buildWindow(
              start: DateTime(2025, 5, 21),
              endExclusive: DateTime(2025, 6, 21),
              index: 4,
              status: BudgetWindowStatus.past,
            ),
            progress: entry.progress,
            activity: buildActivity(count: 3),
          ),
        ),
        'detail_past_period_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('detalle en carga ($suffix)', (tester) async {
      await golden(
        tester,
        const BudgetDetailState(),
        'detail_loading_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('detalle con error ($suffix)', (tester) async {
      await golden(
        tester,
        const BudgetDetailState(status: BudgetDetailStatus.failure),
        'detail_error_$suffix',
        brightness: brightness,
      );
    });
  }
}
