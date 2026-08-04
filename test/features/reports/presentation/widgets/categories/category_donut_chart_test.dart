import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/reports/domain/entities/category_breakdown_item.dart';
import 'package:billetudo/features/reports/presentation/widgets/categories/category_donut_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the tap-to-select behaviour of the donut (criteria 1-3 of the
/// "Gráficas — cerrar pendientes de Categorías" HU): a plain tap selects a
/// section persistently (no tap-and-hold needed), tapping the same section
/// again deselects it, and tapping a different section moves the selection
/// — never two sections highlighted at once.
void main() {
  const groceries = CategoryBreakdownItem(
    categoryId: 'cat-mercado',
    name: 'Mercado',
    amountMinor: 1450000,
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
  const items = [groceries, transport, uncategorized];
  const totalMinor = 1450000 + 620000 + 90000;

  Future<void> pumpDonut(
    WidgetTester tester, {
    required int? selectedIndex,
    required ValueChanged<int?> onSectionTap,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: CategoryDonutChart(
                items: items,
                totalMinor: totalMinor,
                selectedIndex: selectedIndex,
                onSectionTap: onSectionTap,
              ),
            ),
          ),
        ),
      );

  /// Fabricates the tap fl_chart would report for tapping section [index],
  /// and invokes the chart's own `touchCallback` directly — tapping the real
  /// rendered geometry of a `PieChart` from a widget test is brittle (the
  /// exact pixel that lands inside a given arc depends on fl_chart's
  /// internal layout math), while this exercises the exact same callback the
  /// real gesture would trigger.
  void simulateTap(WidgetTester tester, int index) {
    final pieChart = tester.widget<PieChart>(find.byType(PieChart));
    final touchCallback = pieChart.data.pieTouchData.touchCallback!;
    touchCallback(
      FlTapUpEvent(
        TapUpDetails(kind: PointerDeviceKind.touch),
      ),
      PieTouchResponse(
        PieTouchedSection(
          PieChartSectionData(value: items[index].amountMinor.toDouble()),
          index,
          0,
          0,
        ),
      ),
    );
  }

  testWidgets('sin selección, el centro muestra el total', (tester) async {
    await pumpDonut(tester, selectedIndex: null, onSectionTap: (_) {});

    expect(find.text('Mercado'), findsNothing);
    expect(find.textContaining('21.600'), findsOneWidget);
  });

  testWidgets(
    'tocar una sección la selecciona y muestra su nombre y monto',
    (tester) async {
      int? reported;
      await pumpDonut(
        tester,
        selectedIndex: null,
        onSectionTap: (value) => reported = value,
      );

      simulateTap(tester, 0);

      expect(reported, 0);
    },
  );

  testWidgets('con selección, el centro muestra nombre y monto de esa sección',
      (tester) async {
    await pumpDonut(tester, selectedIndex: 0, onSectionTap: (_) {});

    expect(find.text('Mercado'), findsOneWidget);
    expect(find.textContaining('14.500'), findsOneWidget);
  });

  testWidgets(
    'con selección, la fila "Sin categoría" muestra ese nombre en el centro',
    (tester) async {
      await pumpDonut(tester, selectedIndex: 2, onSectionTap: (_) {});

      final l10n = await AppLocalizations.delegate.load(const Locale('es'));
      expect(find.text(l10n.reportsCategoriesUncategorized), findsOneWidget);
    },
  );

  testWidgets(
    'tocar de nuevo la sección ya seleccionada la deselecciona',
    (tester) async {
      int? reported = -1;
      await pumpDonut(
        tester,
        selectedIndex: 0,
        onSectionTap: (value) => reported = value,
      );

      simulateTap(tester, 0);

      expect(reported, isNull);
    },
  );

  testWidgets(
    'tocar otra sección mientras una está seleccionada cambia la selección',
    (tester) async {
      int? reported = -1;
      await pumpDonut(
        tester,
        selectedIndex: 0,
        onSectionTap: (value) => reported = value,
      );

      simulateTap(tester, 1);

      expect(reported, 1);
    },
  );
}
