import 'package:billetudo/features/transactions/domain/entities/budget_period_option.dart';
import 'package:billetudo/features/transactions/presentation/cubit/budget_period_filter_cubit.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/budget_period_filter_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../categories/presentation/widgets/pump_widget.dart';

class MockBudgetPeriodFilterCubit extends MockCubit<BudgetPeriodFilterState>
    implements BudgetPeriodFilterCubit {}

void main() {
  late MockBudgetPeriodFilterCubit cubit;

  final food = BudgetPeriodOption(
    budgetId: 'a',
    name: 'Comida',
    start: DateTime(2026, 7),
    endExclusive: DateTime(2026, 8),
  );
  final transport = BudgetPeriodOption(
    budgetId: 'b',
    name: 'Transporte',
    start: DateTime(2026, 7),
    endExclusive: DateTime(2026, 8),
  );

  setUp(() => cubit = MockBudgetPeriodFilterCubit());

  Future<void> pump(WidgetTester tester, BudgetPeriodFilterState state) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpAppWidget(
      BlocProvider<BudgetPeriodFilterCubit>.value(
        value: cubit,
        child: const BudgetPeriodFilterSheetBody(),
      ),
    );
  }

  testWidgets('lista los presupuestos activos con nombre y período', (
    tester,
  ) async {
    await pump(
      tester,
      BudgetPeriodFilterState(
        status: BudgetPeriodFilterStatus.ready,
        options: [food, transport],
      ),
    );

    expect(find.text('Comida'), findsOneWidget);
    expect(find.text('Transporte'), findsOneWidget);
  });

  testWidgets('marca con check solo la fila seleccionada', (tester) async {
    await pump(
      tester,
      BudgetPeriodFilterState(
        status: BudgetPeriodFilterStatus.ready,
        options: [food, transport],
        selectedBudgetId: 'a',
      ),
    );

    // The check icon only renders inside the selected row's trailing slot,
    // never in the unselected sibling.
    expect(find.byIcon(LucideIcons.check), findsOneWidget);
  });

  testWidgets('tocar una fila llama a select con su id', (tester) async {
    await pump(
      tester,
      BudgetPeriodFilterState(
        status: BudgetPeriodFilterStatus.ready,
        options: [food, transport],
      ),
    );

    await tester.tap(find.text('Transporte'));
    verify(() => cubit.select('b')).called(1);
  });

  testWidgets('Limpiar llama a clear', (tester) async {
    await pump(
      tester,
      BudgetPeriodFilterState(
        status: BudgetPeriodFilterStatus.ready,
        options: [food],
        selectedBudgetId: 'a',
      ),
    );

    await tester.tap(find.text('Limpiar'));
    verify(() => cubit.clear()).called(1);
  });

  testWidgets('Aplicar sin presupuestos activos muestra el estado vacío', (
    tester,
  ) async {
    await pump(
      tester,
      const BudgetPeriodFilterState(status: BudgetPeriodFilterStatus.ready),
    );

    expect(find.text('No tienes presupuestos activos'), findsOneWidget);
  });

  testWidgets('Aplicar con selección cierra la hoja con la ventana elegida', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(
      BudgetPeriodFilterState(
        status: BudgetPeriodFilterStatus.ready,
        options: [food],
        selectedBudgetId: 'a',
      ),
    );

    BudgetPeriodFilterResult? popped;
    await tester.pumpAppWidget(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            popped = await Navigator.of(context).push<BudgetPeriodFilterResult>(
              MaterialPageRoute(
                builder: (_) => BlocProvider<BudgetPeriodFilterCubit>.value(
                  value: cubit,
                  child: const BudgetPeriodFilterSheetBody(),
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(popped, isNotNull);
    expect(popped!.window!.budgetId, 'a');
  });
}
