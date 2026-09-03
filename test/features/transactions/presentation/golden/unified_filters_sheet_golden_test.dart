import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/transactions/domain/entities/budget_period_option.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/unified_filters_cubit.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/unified_filters_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../transaction_fixtures.dart';

/// GitHub issue #7: golden coverage for the unified filters bottom sheet
/// (`UnifiedFiltersSheet`, `presentation/widgets/sheets/`) — the fixed
/// section order, Presupuesto's conditional hiding (criterion #6) and
/// Fecha's locked treatment while a Presupuesto filter is active
/// (criterion #9). Mirrors the "open through a real trigger button" pattern
/// `sheets_golden_test.dart` already uses for the rest of Movimientos'
/// sheets.
class MockUnifiedFiltersCubit extends MockCubit<UnifiedFiltersState>
    implements UnifiedFiltersCubit {}

final DateTime _instant = DateTime(2026, 7, 15);
final int _instantMillis = _instant.millisecondsSinceEpoch;

Category _buildCategory({
  required String id,
  required String name,
  required String icon,
  CategoryKind kind = CategoryKind.expense,
}) =>
    Category(
      id: id,
      name: name,
      kind: kind,
      icon: icon,
      sortOrder: 0,
      createdAt: _instant,
      updatedAt: _instantMillis,
    );

void main() {
  setUpAll(() async {
    registerFallbackValue(TransactionFilter());
    registerFallbackValue(const <BudgetPeriodOption>[]);
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  tearDown(getIt.reset);

  final food = BudgetPeriodOption(
    budgetId: 'budget-1',
    name: 'Comida',
    icon: 'utensils-crossed',
    start: DateTime(2026, 7),
    endExclusive: DateTime(2026, 8),
  );

  final expenseNodes = [
    CategoryNode(
      root: _buildCategory(
        id: 'cat-food',
        name: 'Comida',
        icon: 'utensils-crossed',
      ),
    ),
    CategoryNode(
      root: _buildCategory(
        id: 'cat-transport',
        name: 'Transporte',
        icon: 'bus',
      ),
    ),
  ];

  final incomeNodes = [
    CategoryNode(
      root: _buildCategory(
        id: 'cat-salary',
        name: 'Salario',
        icon: 'briefcase',
        kind: CategoryKind.income,
      ),
    ),
  ];

  final tags = [buildTag(id: 'tag-1', name: 'viaje')];

  /// Opens the sheet through a real trigger button (mirrors how the sheet
  /// actually reaches the screen — scrim, drag handle and the app's bottom
  /// sheet theme included) and captures the whole screen.
  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => UnifiedFiltersSheet.show(
              context,
              initialFilter: TransactionFilter(),
              budgetOptions: const [],
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/unified_filters_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    group('con presupuestos activos ($suffix)', () {
      setUp(() {
        final cubit = MockUnifiedFiltersCubit();
        when(() => cubit.start(
              filter: any(named: 'filter'),
              budgetOptions: any(named: 'budgetOptions'),
            )).thenAnswer((_) async {});
        when(() => cubit.state).thenReturn(
          UnifiedFiltersState(
            status: UnifiedFiltersStatus.ready,
            budgetOptions: [food],
            expenseNodes: expenseNodes,
            incomeNodes: incomeNodes,
            tags: tags,
          ),
        );
        getIt.registerFactory<UnifiedFiltersCubit>(() => cubit);
      });

      testWidgets('orden Presupuesto → Fecha → Tipo → Categoría → Etiqueta',
          (tester) async {
        await golden(tester, 'with_budgets_$suffix', brightness: brightness);
      });
    });

    group('sin presupuestos activos ($suffix)', () {
      setUp(() {
        final cubit = MockUnifiedFiltersCubit();
        when(() => cubit.start(
              filter: any(named: 'filter'),
              budgetOptions: any(named: 'budgetOptions'),
            )).thenAnswer((_) async {});
        when(() => cubit.state).thenReturn(
          UnifiedFiltersState(
            status: UnifiedFiltersStatus.ready,
            expenseNodes: expenseNodes,
            incomeNodes: incomeNodes,
            tags: tags,
          ),
        );
        getIt.registerFactory<UnifiedFiltersCubit>(() => cubit);
      });

      testWidgets(
          'criterio #6: la sección Presupuesto no se renderiza, arranca en '
          'Fecha sin candado', (tester) async {
        await golden(
          tester,
          'no_budgets_$suffix',
          brightness: brightness,
        );
      });
    });

    group('con presupuesto activo bloqueando Fecha ($suffix)', () {
      setUp(() {
        final cubit = MockUnifiedFiltersCubit();
        when(() => cubit.start(
              filter: any(named: 'filter'),
              budgetOptions: any(named: 'budgetOptions'),
            )).thenAnswer((_) async {});
        when(() => cubit.state).thenReturn(
          UnifiedFiltersState(
            status: UnifiedFiltersStatus.ready,
            budgetOptions: [food],
            selectedBudgetId: 'budget-1',
            types: const {TransactionType.expense},
            categoryIds: const {'cat-food'},
            expenseNodes: expenseNodes,
            incomeNodes: incomeNodes,
            tags: tags,
            tagIds: const {'tag-1'},
          ),
        );
        getIt.registerFactory<UnifiedFiltersCubit>(() => cubit);
      });

      testWidgets(
          'criterio #9: icono lock + leyenda a opacidad plena, controles a '
          '0.4 y sin interacción', (tester) async {
        await golden(
          tester,
          'budget_locks_date_$suffix',
          brightness: brightness,
        );
      });
    });
  }
}
