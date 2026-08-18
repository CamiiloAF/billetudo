import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/reports/domain/entities/category_breakdown_item.dart';
import 'package:billetudo/features/reports/presentation/widgets/categories/category_donut_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    List<CategoryBreakdownItem> withItems = items,
    int withTotalMinor = totalMinor,
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
                items: withItems,
                totalMinor: withTotalMinor,
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

  /// Regression guard for the truncated center total (`$2.640.0…`): the hole
  /// was narrower than the figure a real Colombian monthly expense produces.
  /// Neither the selection tests above nor the page goldens covered it — their
  /// fixtures top out at 5 significant digits (`$26.400`), which fits even in
  /// the old 156pt donut. Asserted on the `RenderParagraph` rather than on a
  /// pixel diff so the failure names the cause (the text did not fit) instead
  /// of just reporting changed pixels.
  group('el total del centro se muestra completo', () {
    /// `$2.640.000` — 7 significant digits, the amount that truncated.
    const largeTotalMinor = 264000000;

    /// An amount far past anything a personal budget produces, used only to
    /// pin the lower bound of the auto-shrink fallback.
    const absurdTotalMinor = 999999999999900;

    RenderParagraph amountParagraph(WidgetTester tester, String text) =>
        tester.renderObject<RenderParagraph>(find.text(text));

    testWidgets('un total de 7 dígitos no se trunca ni encoge la fuente',
        (tester) async {
      await pumpDonut(
        tester,
        selectedIndex: null,
        onSectionTap: (_) {},
        withTotalMinor: largeTotalMinor,
      );

      final finder = find.textContaining('2.640.000');
      expect(finder, findsOneWidget);
      final label = tester.widget<Text>(finder);
      expect(
        amountParagraph(tester, label.data!).didExceedMaxLines,
        isFalse,
        reason: 'el total debe caber entero dentro del agujero de la dona',
      );
      expect(
        label.style?.fontSize,
        16,
        reason: 'a este monto el anillo ensanchado basta, sin encoger la letra',
      );
    });

    testWidgets(
        'ningún monto realista se trunca: hasta 8 dígitos entra a tamaño de '
        'diseño', (tester) async {
      // Spans a plausible range of monthly expense totals in COP, from a
      // modest week to an outlier year — the whole band the widened ring is
      // supposed to absorb without shrinking the figure.
      for (final totalMinor in [
        2640000, // $26.400
        26400000, // $264.000
        264000000, // $2.640.000
        1919000000, // $19.190.000
        26400000000, // $264.000.000
      ]) {
        await pumpDonut(
          tester,
          selectedIndex: null,
          onSectionTap: (_) {},
          withTotalMinor: totalMinor,
        );

        final label = tester.widget<Text>(
          find.descendant(
            of: find.byType(CategoryDonutChart),
            matching: find.byWidgetPredicate(
              (widget) => widget is Text && widget.style?.fontWeight != null,
            ),
          ),
        );
        expect(
          amountParagraph(tester, label.data!).didExceedMaxLines,
          isFalse,
          reason: '$totalMinor se truncó en el centro de la dona',
        );
        expect(
          label.style?.fontSize,
          16,
          reason: '$totalMinor no debería necesitar encoger la letra',
        );
      }
    });

    testWidgets('un monto absurdo encoge la letra pero nunca bajo 12pt',
        (tester) async {
      await pumpDonut(
        tester,
        selectedIndex: null,
        onSectionTap: (_) {},
        withTotalMinor: absurdTotalMinor,
      );

      final label = tester.widget<Text>(
        find.descendant(
          of: find.byType(CategoryDonutChart),
          matching: find.byWidgetPredicate(
            (widget) => widget is Text && widget.style?.fontWeight != null,
          ),
        ),
      );
      expect(label.style!.fontSize, lessThan(16));
      expect(
        label.style!.fontSize,
        greaterThanOrEqualTo(12),
        reason: 'por debajo de 12pt la cifra deja de ser legible',
      );
    });

    testWidgets('el monto de una sección seleccionada tampoco se trunca',
        (tester) async {
      const bigGroceries = CategoryBreakdownItem(
        categoryId: 'cat-mercado',
        name: 'Mercado',
        amountMinor: 264000000,
      );
      await pumpDonut(
        tester,
        selectedIndex: 0,
        onSectionTap: (_) {},
        withItems: const [bigGroceries, transport, uncategorized],
        withTotalMinor: 264000000 + 620000 + 90000,
      );

      final finder = find.textContaining('2.640.000');
      expect(finder, findsOneWidget);
      final label = tester.widget<Text>(finder);
      expect(amountParagraph(tester, label.data!).didExceedMaxLines, isFalse);
      expect(find.text('Mercado'), findsOneWidget);
    });
  });
}
