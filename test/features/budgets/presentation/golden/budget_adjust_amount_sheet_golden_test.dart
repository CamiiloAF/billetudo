import 'package:billetudo/features/budgets/presentation/utils/budget_adjustment_windows.dart';
import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_adjust_amount_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';
import 'budget_golden_fixtures.dart';

/// "Ajustar monto — solo el próximo período" (`A8ZfHd`/`D0EoN` crear,
/// `k6fKsZ`/`PPzUv` editar/cancelar): the single field over the read-only
/// current-amount `Info Row`, plus the explainer tira that always spells out
/// the fork mechanic. [BudgetAdjustAmountSheet.pendingAmountMinor] is what
/// switches "crear" (single primary CTA) into "editar/cancelar" (adds the
/// secondary "Quitar ajuste").
///
/// `windows` is built from a fixed `now` (never `DateTime.now()`), so the
/// "próximo período"/"resume" date labels stay deterministic across runs —
/// same discipline as `budget_golden_fixtures.dart`.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  final windows = BudgetAdjustmentWindows(
    healthyEntry.budget,
    DateTime(2025, 7, 25),
  );

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    int? pendingAmountMinor,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => BudgetAdjustAmountSheet.show(
              context,
              currentAmountMinor: healthyEntry.budget.amountMinor,
              currency: healthyEntry.budget.currency,
              windows: windows,
              pendingAmountMinor: pendingAmountMinor,
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
      matchesGoldenFile('goldens/sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('ajustar monto: crear, sin ajuste pendiente ($suffix)',
        (tester) async {
      await golden(
        tester,
        'adjust_amount_create_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'ajustar monto: editar/cancelar, con ajuste ya pendiente ($suffix)',
        (tester) async {
      await golden(
        tester,
        'adjust_amount_edit_$suffix',
        brightness: brightness,
        pendingAmountMinor: 200000000,
      );
    });
  }
}
