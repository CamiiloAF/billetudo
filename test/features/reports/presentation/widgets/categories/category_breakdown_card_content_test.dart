import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/reports/domain/entities/category_breakdown.dart';
import 'package:billetudo/features/reports/domain/entities/category_breakdown_item.dart';
import 'package:billetudo/features/reports/domain/entities/date_range.dart';
import 'package:billetudo/features/reports/presentation/cubit/category_breakdown_state.dart';
import 'package:billetudo/features/reports/presentation/widgets/categories/category_breakdown_card_content.dart';
import 'package:billetudo/features/reports/presentation/widgets/categories/category_breakdown_row.dart';
import 'package:billetudo/features/reports/presentation/widgets/categories/category_donut_chart.dart';
import 'package:billetudo/features/reports/presentation/widgets/categories/category_view_subcategories_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the in-place drill-down of `CategoryBreakdownCardContent`
/// (criteria 4-7 of the "Gráficas — cerrar pendientes de Categorías" HU): the
/// "Ver subcategorías"/"Atrás" pill's three states, and moving between the
/// root donut and a category's subcategory donut.
void main() {
  const supermercado = CategoryBreakdownItem(
    categoryId: 'cat-mercado-supermercado',
    name: 'Supermercado',
    amountMinor: 1050000,
  );
  const plazaDeMercado = CategoryBreakdownItem(
    categoryId: 'cat-mercado-mercado-local',
    name: 'Plaza de mercado',
    amountMinor: 400000,
  );
  const groceries = CategoryBreakdownItem(
    categoryId: 'cat-mercado',
    name: 'Mercado',
    amountMinor: 1450000,
    subcategories: [supermercado, plazaDeMercado],
  );
  const transport = CategoryBreakdownItem(
    categoryId: 'cat-transporte',
    name: 'Transporte',
    amountMinor: 620000,
  );
  const uncategorized = CategoryBreakdownItem(
    categoryId: null,
    name: null,
    amountMinor: 90000,
  );

  final range = DateRange(
    start: DateTime(2026, 2),
    endExclusive: DateTime(2026, 8),
    granularity: DateGranularity.monthly,
  );

  CategoryBreakdownState readyState() => CategoryBreakdownState(
        status: CategoryBreakdownStatus.ready,
        breakdown: CategoryBreakdown(
          items: const [groceries, transport, uncategorized],
          totalMinor: 1450000 + 620000 + 90000,
          range: range,
        ),
      );

  Future<void> pumpContent(
    WidgetTester tester, {
    required CategoryBreakdownState state,
    ValueChanged<String>? onOpenCategoryMovements,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryBreakdownCardContent(
                state: state,
                rangeCaption: 'feb - jul 2026',
                onAddMovement: () {},
                onOpenCategoryMovements: onOpenCategoryMovements,
              ),
            ),
          ),
        ),
      );

  CategoryDrillDownLinkState linkState(WidgetTester tester) => tester
      .widget<CategoryViewSubcategoriesLink>(
        find.byType(CategoryViewSubcategoriesLink),
      )
      .state;

  List<CategoryBreakdownItem> donutItems(WidgetTester tester) =>
      tester.widget<CategoryDonutChart>(find.byType(CategoryDonutChart)).items;

  void selectDonutSection(WidgetTester tester, int index) {
    tester
        .widget<CategoryDonutChart>(find.byType(CategoryDonutChart))
        .onSectionTap(index);
  }

  void tapLink(WidgetTester tester) {
    tester
        .widget<CategoryViewSubcategoriesLink>(
          find.byType(CategoryViewSubcategoriesLink),
        )
        .onTap!();
  }

  testWidgets(
    'sin selección, el pill de profundizar está deshabilitado',
    (tester) async {
      await pumpContent(tester, state: readyState());

      expect(linkState(tester), CategoryDrillDownLinkState.disabled);
    },
  );

  testWidgets(
    'con selección de una categoría con subcategorías, el pill se habilita',
    (tester) async {
      await pumpContent(tester, state: readyState());

      selectDonutSection(tester, 0); // Mercado, has subcategories
      await tester.pump();

      expect(linkState(tester), CategoryDrillDownLinkState.viewSubcategories);
    },
  );

  testWidgets(
    'con selección de una categoría sin subcategorías, el pill sigue '
    'deshabilitado',
    (tester) async {
      await pumpContent(tester, state: readyState());

      selectDonutSection(tester, 1); // Transporte, no subcategories
      await tester.pump();

      expect(linkState(tester), CategoryDrillDownLinkState.disabled);
    },
  );

  testWidgets(
    'tocar el pill habilitado profundiza al donut de subcategorías y '
    'cambia el pill a "Atrás"',
    (tester) async {
      await pumpContent(tester, state: readyState());

      selectDonutSection(tester, 0);
      await tester.pump();
      tapLink(tester);
      await tester.pump();

      expect(donutItems(tester), [supermercado, plazaDeMercado]);
      expect(linkState(tester), CategoryDrillDownLinkState.back);
    },
  );

  testWidgets(
    'tocar "Atrás" vuelve al donut raíz sin selección',
    (tester) async {
      await pumpContent(tester, state: readyState());

      selectDonutSection(tester, 0);
      await tester.pump();
      tapLink(tester); // drill in
      await tester.pump();
      tapLink(tester); // back
      await tester.pump();

      expect(donutItems(tester), [groceries, transport, uncategorized]);
      expect(linkState(tester), CategoryDrillDownLinkState.disabled);
    },
  );

  testWidgets(
    'tocar una fila con categoryId navega a Movimientos con ese id',
    (tester) async {
      String? openedCategoryId;
      await pumpContent(
        tester,
        state: readyState(),
        onOpenCategoryMovements: (id) => openedCategoryId = id,
      );

      final rows = tester.widgetList<CategoryBreakdownRow>(
        find.byType(CategoryBreakdownRow),
      );
      final groceriesRow =
          rows.firstWhere((row) => row.item.categoryId == 'cat-mercado');
      groceriesRow.onTap!();

      expect(openedCategoryId, 'cat-mercado');
    },
  );

  testWidgets(
    '"Sin categoría" no dispara navegación (onTap null)',
    (tester) async {
      var opened = false;
      await pumpContent(
        tester,
        state: readyState(),
        onOpenCategoryMovements: (_) => opened = true,
      );

      final rows = tester.widgetList<CategoryBreakdownRow>(
        find.byType(CategoryBreakdownRow),
      );
      final uncategorizedRow =
          rows.firstWhere((row) => row.item.categoryId == null);

      expect(uncategorizedRow.onTap, isNull);
      expect(opened, isFalse);
    },
  );
}
