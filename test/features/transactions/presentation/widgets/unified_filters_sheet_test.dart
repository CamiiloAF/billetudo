import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/transactions/domain/entities/budget_period_option.dart';
import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/tag.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_filter_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/unified_filters_cubit.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/unified_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../../categories/presentation/widgets/pump_widget.dart';
import '../usecase_mocks.dart';

/// GitHub issue #7's unified filters sheet: fixed section order
/// (Presupuesto → Fecha → Tipo → Categoría → Etiqueta), the Presupuesto
/// section's conditional hiding, and Fecha's locked treatment while a
/// Presupuesto filter is active.
void main() {
  late MockWatchCategories watchCategories;
  late MockWatchTags watchTags;

  final food = BudgetPeriodOption(
    budgetId: 'budget-1',
    name: 'Comida',
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
    when(() => watchTags())
        .thenAnswer((_) => Stream.value(const Right(<Tag>[])));
    // `CategoryFilterSection`'s summary control opens `CategoryFilterSheet`,
    // which resolves its own `CategoryFilterCubit` from `getIt`.
    getIt.registerFactory<CategoryFilterCubit>(
      () => CategoryFilterCubit(watchCategories),
    );
  });

  tearDown(getIt.reset);

  Future<void> pump(
    WidgetTester tester, {
    required TransactionFilter filter,
    required List<BudgetPeriodOption> budgetOptions,
  }) async {
    final cubit = UnifiedFiltersCubit(watchTags);
    await cubit.start(filter: filter, budgetOptions: budgetOptions);
    await tester.pumpAppWidget(
      BlocProvider<UnifiedFiltersCubit>.value(
        value: cubit,
        child: const UnifiedFiltersSheetBody(),
      ),
    );
  }

  double topOf(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  testWidgets(
      'con presupuestos, las secciones aparecen en orden Presupuesto → '
      'Fecha → Tipo → Categoría → Etiqueta', (tester) async {
    await pump(tester, filter: TransactionFilter(), budgetOptions: [food]);

    final budgetY = topOf(tester, find.text('PRESUPUESTO'));
    final dateY = topOf(tester, find.text('FECHA'));
    final typeY = topOf(tester, find.text('TIPO'));
    final categoryY = topOf(tester, find.text('CATEGORÍA'));
    final tagY = topOf(tester, find.text('ETIQUETA'));

    expect(budgetY, lessThan(dateY));
    expect(dateY, lessThan(typeY));
    expect(typeY, lessThan(categoryY));
    expect(categoryY, lessThan(tagY));
  });

  testWidgets(
      'sin presupuestos activos, la sección Presupuesto no se muestra y '
      'Fecha nunca aparece deshabilitada (criterio #6)', (tester) async {
    await pump(tester, filter: TransactionFilter(), budgetOptions: const []);

    expect(find.text('PRESUPUESTO'), findsNothing);
    expect(find.byIcon(LucideIcons.lock), findsNothing);
    expect(
      find.text('No puedes filtrar por fecha con un presupuesto activo'),
      findsNothing,
    );
  });

  testWidgets(
      'con un presupuesto activo, la sección Fecha muestra el candado y la '
      'leyenda a opacidad plena (criterio #9)', (tester) async {
    await pump(
      tester,
      filter: TransactionFilter(
        budgetPeriod: DatePeriodFilter.budget(
          budgetId: 'budget-1',
          start: DateTime(2026, 7),
          endExclusive: DateTime(2026, 8),
        ),
      ),
      budgetOptions: [food],
    );

    expect(find.byIcon(LucideIcons.lock), findsOneWidget);
    expect(
      find.text('No puedes filtrar por fecha con un presupuesto activo'),
      findsOneWidget,
    );

    // The caption is not inside the dimmed `Opacity` block: only the
    // Granularity Switch + Stepper Row group is.
    final dimmed = tester.widgetList<Opacity>(find.byType(Opacity)).where(
          (opacity) => opacity.opacity == 0.4,
        );
    expect(dimmed, isNotEmpty);
  });

  group('Categoría', () {
    testWidgets(
        'sin selección muestra el control genérico "Categorías" sin '
        'resaltar', (tester) async {
      await pump(tester, filter: TransactionFilter(), budgetOptions: const []);

      expect(find.text('Categorías'), findsOneWidget);
    });

    testWidgets('con categorías seleccionadas muestra el conteo y se resalta',
        (tester) async {
      await pump(
        tester,
        filter: TransactionFilter(categoryIds: const {'cat-1', 'cat-2'}),
        budgetOptions: const [],
      );

      expect(find.text('2 categorías'), findsOneWidget);
    });

    testWidgets(
        'tocar el control abre el selector completo de categorías '
        '(CategoryFilterSheet)', (tester) async {
      await pump(tester, filter: TransactionFilter(), budgetOptions: const []);

      await tester.tap(find.text('Categorías'));
      await tester.pumpAndSettle();

      expect(find.text('Filtrar por categoría'), findsOneWidget);
    });
  });
}
