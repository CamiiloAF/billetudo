import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('valores por defecto', () {
    test('sin filtro activo, todo queda "incluye todo"', () {
      final filter = TransactionFilter();

      expect(filter.hasAccountFilter, isFalse);
      expect(filter.hasCategoryFilter, isFalse);
      expect(filter.hasTypeFilter, isFalse);
      expect(filter.hasTagFilter, isFalse);
      expect(filter.hasBudgetPeriodFilter, isFalse);
      expect(filter.budgetPeriod, isNull);
      expect(filter.sortOrder, TransactionSortOrder.dateDesc);
    });

    test('HU-06b: el filtro de fecha siempre está activo, nunca "sin filtro"',
        () {
      final filter = TransactionFilter();

      expect(filter.datePeriod.isCustomRange, isFalse);
      expect(filter.datePeriod.granularity, DateGranularity.month);
    });
  });

  group('chip Presupuesto — independiente del chip Fecha', () {
    test('con un presupuesto elegido, hasBudgetPeriodFilter se activa', () {
      final window = DatePeriodFilter.budget(
        budgetId: 'budget-1',
        start: DateTime(2026, 7, 1),
        endExclusive: DateTime(2026, 8, 1),
      );

      final filter = TransactionFilter(budgetPeriod: window);

      expect(filter.hasBudgetPeriodFilter, isTrue);
      expect(filter.budgetPeriod, window);
      // El chip Fecha sigue en su default, sin verse afectado.
      expect(filter.datePeriod.isCustomRange, isFalse);
      expect(filter.datePeriod.granularity, DateGranularity.month);
    });

    test('copyWith con budgetPeriod no toca datePeriod ni viceversa', () {
      final budgetWindow = DatePeriodFilter.budget(
        budgetId: 'budget-1',
        start: DateTime(2026, 7, 1),
        endExclusive: DateTime(2026, 8, 1),
      );
      final dateWindow =
          DatePeriodFilter.granular(DateGranularity.year, DateTime(2026, 7));
      final base = TransactionFilter(datePeriod: dateWindow);

      final withBudget = base.copyWith(budgetPeriod: budgetWindow);

      expect(withBudget.budgetPeriod, budgetWindow);
      expect(withBudget.datePeriod, dateWindow);
    });

    test('clearBudgetPeriod vuelve el filtro a null sin afectar datePeriod',
        () {
      final budgetWindow = DatePeriodFilter.budget(
        budgetId: 'budget-1',
        start: DateTime(2026, 7, 1),
        endExclusive: DateTime(2026, 8, 1),
      );
      final dateWindow =
          DatePeriodFilter.granular(DateGranularity.year, DateTime(2026, 7));
      final withBudget = TransactionFilter(
        datePeriod: dateWindow,
        budgetPeriod: budgetWindow,
      );

      final cleared = withBudget.copyWith(clearBudgetPeriod: true);

      expect(cleared.hasBudgetPeriodFilter, isFalse);
      expect(cleared.budgetPeriod, isNull);
      expect(cleared.datePeriod, dateWindow);
    });

    test('copyWith sin mencionar budgetPeriod preserva el existente', () {
      final budgetWindow = DatePeriodFilter.budget(
        budgetId: 'budget-1',
        start: DateTime(2026, 7, 1),
        endExclusive: DateTime(2026, 8, 1),
      );
      final base = TransactionFilter(budgetPeriod: budgetWindow);

      final copy = base.copyWith(searchText: 'café');

      expect(copy.budgetPeriod, budgetWindow);
    });
  });

  group('HU-06 — toggle simétrico de categoría raíz + subcategorías', () {
    test('seleccionar la raíz selecciona también todas sus subcategorías', () {
      final filter = TransactionFilter().toggleRootCategory(
        rootId: 'root-1',
        subcategoryIds: const ['sub-1', 'sub-2'],
      );

      expect(filter.categoryIds, {'root-1', 'sub-1', 'sub-2'});
    });

    test('tocar de nuevo la raíz ya seleccionada deselecciona todo el árbol',
        () {
      final selected = TransactionFilter().toggleRootCategory(
        rootId: 'root-1',
        subcategoryIds: const ['sub-1', 'sub-2'],
      );

      final toggled = selected.toggleRootCategory(
        rootId: 'root-1',
        subcategoryIds: const ['sub-1', 'sub-2'],
      );

      expect(toggled.categoryIds, isEmpty);
    });

    test('deseleccionar una subcategoría no afecta a sus hermanas ni a la raíz',
        () {
      final selected = TransactionFilter().toggleRootCategory(
        rootId: 'root-1',
        subcategoryIds: const ['sub-1', 'sub-2'],
      );

      final partial = selected.toggleSubcategory('sub-1');

      expect(partial.categoryIds, {'root-1', 'sub-2'});
    });

    test('volver a tocar la subcategoría deseleccionada la selecciona de nuevo',
        () {
      final selected = TransactionFilter().toggleRootCategory(
        rootId: 'root-1',
        subcategoryIds: const ['sub-1', 'sub-2'],
      );
      final partial = selected.toggleSubcategory('sub-1');

      final restored = partial.toggleSubcategory('sub-1');

      expect(restored.categoryIds, {'root-1', 'sub-1', 'sub-2'});
    });

    test(
        'tocar la raíz de nuevo tras una deselección parcial de subcategorías '
        'igual limpia todo el árbol', () {
      final partial = TransactionFilter().toggleRootCategory(
        rootId: 'root-1',
        subcategoryIds: const ['sub-1', 'sub-2'],
      ).toggleSubcategory('sub-1');

      final toggled = partial.toggleRootCategory(
        rootId: 'root-1',
        subcategoryIds: const ['sub-1', 'sub-2'],
      );

      expect(toggled.categoryIds, isEmpty);
    });

    test('el toggle de categoría no toca el resto de los filtros', () {
      final filter = TransactionFilter(
        searchText: 'café',
        accountIds: const {'acc-1'},
        types: const {TransactionType.expense},
      ).toggleRootCategory(rootId: 'root-1', subcategoryIds: const ['sub-1']);

      expect(filter.searchText, 'café');
      expect(filter.accountIds, {'acc-1'});
      expect(filter.types, {TransactionType.expense});
    });
  });

  group('copyWith', () {
    test('preserva los campos no mencionados', () {
      final base = TransactionFilter(
        searchText: 'x',
        accountIds: const {'acc-1'},
        sortOrder: TransactionSortOrder.amountDesc,
      );

      final copy = base.copyWith(searchText: 'y');

      expect(copy.searchText, 'y');
      expect(copy.accountIds, {'acc-1'});
      expect(copy.sortOrder, TransactionSortOrder.amountDesc);
    });
  });
}
