import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/transactions/domain/entities/budget_period_option.dart';
import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/tag.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/unified_filters_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../usecase_mocks.dart';

void main() {
  late MockWatchCategories watchCategories;
  late MockWatchTags watchTags;

  final food = BudgetPeriodOption(
    budgetId: 'budget-1',
    name: 'Comida',
    start: DateTime(2026, 7),
    endExclusive: DateTime(2026, 8),
  );
  final travel = BudgetPeriodOption(
    budgetId: 'budget-2',
    name: 'Viaje',
    start: DateTime(2026, 7),
    endExclusive: DateTime(2026, 8),
  );

  setUp(() {
    watchCategories = MockWatchCategories();
    watchTags = MockWatchTags();
    when(() => watchCategories(CategoryKind.expense))
        .thenAnswer((_) => Stream.value(const Right(<CategoryNode>[])));
    when(() => watchCategories(CategoryKind.income))
        .thenAnswer((_) => Stream.value(const Right(<CategoryNode>[])));
    when(() => watchTags()).thenAnswer((_) => Stream.value(const Right(<Tag>[])));
  });

  UnifiedFiltersCubit build() => UnifiedFiltersCubit(watchCategories, watchTags);

  group('start', () {
    blocTest<UnifiedFiltersCubit, UnifiedFiltersState>(
      // Criterion #11: an untouched dimension is never reset when the sheet
      // opens — it seeds every working value from the already-applied filter.
      'seeds every working value from the currently applied filter',
      build: build,
      act: (cubit) async {
        await cubit.start(
          filter: TransactionFilter(
            categoryIds: const {'cat-1'},
            types: const {TransactionType.expense},
            tagIds: const {'tag-1'},
            datePeriod: DatePeriodFilter.granular(
              DateGranularity.week,
              DateTime(2026, 7, 6),
            ),
            budgetPeriod: DatePeriodFilter.budget(
              budgetId: 'budget-1',
              start: DateTime(2026, 7),
              endExclusive: DateTime(2026, 8),
            ),
          ),
          budgetOptions: [food, travel],
        );
      },
      verify: (cubit) {
        expect(cubit.state.categoryIds, {'cat-1'});
        expect(cubit.state.types, {TransactionType.expense});
        expect(cubit.state.tagIds, {'tag-1'});
        expect(cubit.state.datePeriod.granularity, DateGranularity.week);
        expect(cubit.state.selectedBudgetId, 'budget-1');
        expect(cubit.state.budgetOptions, [food, travel]);
      },
    );

    blocTest<UnifiedFiltersCubit, UnifiedFiltersState>(
      'hasBudgets is false when the caller passes no active budgets '
      '(criterio #6)',
      build: build,
      act: (cubit) => cubit.start(filter: TransactionFilter(), budgetOptions: const []),
      verify: (cubit) {
        expect(cubit.state.hasBudgets, isFalse);
        expect(cubit.state.isDateLockedByBudget, isFalse);
      },
    );
  });

  group('exclusión mutua Presupuesto <-> Fecha', () {
    blocTest<UnifiedFiltersCubit, UnifiedFiltersState>(
      // Criterion #7: selecting a budget clears any active date filter in
      // the same event.
      'selectBudget limpia inmediatamente el filtro de fecha activo',
      build: build,
      act: (cubit) async {
        await cubit.start(
          filter: TransactionFilter(
            datePeriod: DatePeriodFilter.granular(
              DateGranularity.week,
              DateTime(2026, 7, 6),
            ),
          ),
          budgetOptions: [food],
        );
        cubit.selectBudget('budget-1');
      },
      verify: (cubit) {
        expect(cubit.state.selectedBudgetId, 'budget-1');
        expect(cubit.state.isDateActive, isFalse);
        expect(cubit.state.datePeriod, DatePeriodFilter.thisMonth());
      },
    );

    blocTest<UnifiedFiltersCubit, UnifiedFiltersState>(
      // Criterion #8: picking a new granularity clears any active budget
      // filter in the same event.
      'granularitySelected limpia inmediatamente el presupuesto activo',
      build: build,
      act: (cubit) async {
        await cubit.start(
          filter: TransactionFilter(
            budgetPeriod: DatePeriodFilter.budget(
              budgetId: 'budget-1',
              start: DateTime(2026, 7),
              endExclusive: DateTime(2026, 8),
            ),
          ),
          budgetOptions: [food],
        );
        cubit.granularitySelected(DateGranularity.year);
      },
      verify: (cubit) {
        expect(cubit.state.isBudgetActive, isFalse);
        expect(cubit.state.selectedBudgetId, isNull);
        expect(cubit.state.datePeriod.granularity, DateGranularity.year);
      },
    );

    blocTest<UnifiedFiltersCubit, UnifiedFiltersState>(
      'step limpia inmediatamente el presupuesto activo (criterio #8)',
      build: build,
      act: (cubit) async {
        await cubit.start(
          filter: TransactionFilter(
            budgetPeriod: DatePeriodFilter.budget(
              budgetId: 'budget-1',
              start: DateTime(2026, 7),
              endExclusive: DateTime(2026, 8),
            ),
          ),
          budgetOptions: [food],
        );
        cubit.step(1);
      },
      verify: (cubit) => expect(cubit.state.isBudgetActive, isFalse),
    );

    blocTest<UnifiedFiltersCubit, UnifiedFiltersState>(
      'applyCustomDateRange limpia inmediatamente el presupuesto activo '
      '(criterio #8)',
      build: build,
      act: (cubit) async {
        await cubit.start(
          filter: TransactionFilter(
            budgetPeriod: DatePeriodFilter.budget(
              budgetId: 'budget-1',
              start: DateTime(2026, 7),
              endExclusive: DateTime(2026, 8),
            ),
          ),
          budgetOptions: [food],
        );
        cubit.applyCustomDateRange(
          start: DateTime(2026, 7, 1),
          end: DateTime(2026, 7, 10),
        );
      },
      verify: (cubit) {
        expect(cubit.state.isBudgetActive, isFalse);
        expect(cubit.state.datePeriod.isCustomRange, isTrue);
      },
    );

    blocTest<UnifiedFiltersCubit, UnifiedFiltersState>(
      'isDateLockedByBudget refleja el presupuesto activo cuando hay '
      'presupuestos (criterio #9)',
      build: build,
      act: (cubit) async {
        await cubit.start(filter: TransactionFilter(), budgetOptions: [food]);
        cubit.selectBudget('budget-1');
      },
      verify: (cubit) => expect(cubit.state.isDateLockedByBudget, isTrue),
    );
  });

  group('buildResult', () {
    blocTest<UnifiedFiltersCubit, UnifiedFiltersState>(
      'resuelve budgetPeriod desde el presupuesto seleccionado',
      build: build,
      act: (cubit) async {
        await cubit.start(filter: TransactionFilter(), budgetOptions: [food]);
        cubit.selectBudget('budget-1');
      },
      verify: (cubit) {
        final result = cubit.buildResult();
        expect(result.budgetPeriod?.budgetId, 'budget-1');
        expect(result.budgetPeriod?.start, food.start);
        expect(result.budgetPeriod?.endExclusive, food.endExclusive);
      },
    );

    blocTest<UnifiedFiltersCubit, UnifiedFiltersState>(
      'resuelve budgetPeriod null cuando no hay presupuesto seleccionado',
      build: build,
      act: (cubit) => cubit.start(filter: TransactionFilter(), budgetOptions: [food]),
      verify: (cubit) => expect(cubit.buildResult().budgetPeriod, isNull),
    );
  });

  group('clearAll', () {
    blocTest<UnifiedFiltersCubit, UnifiedFiltersState>(
      'restablece cada dimensión sin perder las listas ya cargadas',
      build: build,
      act: (cubit) async {
        await cubit.start(
          filter: TransactionFilter(
            categoryIds: const {'cat-1'},
            tagIds: const {'tag-1'},
            types: const {TransactionType.income},
            budgetPeriod: DatePeriodFilter.budget(
              budgetId: 'budget-1',
              start: DateTime(2026, 7),
              endExclusive: DateTime(2026, 8),
            ),
          ),
          budgetOptions: [food],
        );
        cubit.clearAll();
      },
      verify: (cubit) {
        expect(cubit.state.categoryIds, isEmpty);
        expect(cubit.state.tagIds, isEmpty);
        expect(cubit.state.types, isEmpty);
        expect(cubit.state.selectedBudgetId, isNull);
        expect(cubit.state.datePeriod, DatePeriodFilter.thisMonth());
        expect(cubit.state.budgetOptions, [food]);
      },
    );
  });

  group('toggles', () {
    blocTest<UnifiedFiltersCubit, UnifiedFiltersState>(
      'toggleType agrega y quita el tipo',
      build: build,
      act: (cubit) async {
        await cubit.start(filter: TransactionFilter(), budgetOptions: const []);
        cubit.toggleType(TransactionType.expense);
      },
      verify: (cubit) => expect(cubit.state.types, {TransactionType.expense}),
    );

    blocTest<UnifiedFiltersCubit, UnifiedFiltersState>(
      'toggleRootCategory selecciona la raíz y sus subcategorías en bloque',
      build: build,
      act: (cubit) async {
        await cubit.start(filter: TransactionFilter(), budgetOptions: const []);
        cubit.toggleRootCategory(
          CategoryNode(
            root: Category(
              id: 'root-1',
              name: 'Comida y bebida',
              kind: CategoryKind.expense,
              sortOrder: 0,
              createdAt: DateTime(2026),
              updatedAt: 0,
            ),
            subcategories: [
              Category(
                id: 'sub-1',
                name: 'Restaurantes',
                kind: CategoryKind.expense,
                parentId: 'root-1',
                sortOrder: 0,
                createdAt: DateTime(2026),
                updatedAt: 0,
              ),
            ],
          ),
        );
      },
      verify: (cubit) => expect(cubit.state.categoryIds, {'root-1', 'sub-1'}),
    );

    blocTest<UnifiedFiltersCubit, UnifiedFiltersState>(
      'toggleTag agrega y quita la etiqueta',
      build: build,
      act: (cubit) async {
        await cubit.start(filter: TransactionFilter(), budgetOptions: const []);
        cubit.toggleTag('tag-1');
        cubit.toggleTag('tag-1');
      },
      verify: (cubit) => expect(cubit.state.tagIds, isEmpty),
    );
  });
}
