import 'package:billetudo/features/budgets/domain/entities/budget_scheduled_item.dart';
import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_scheduled_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';
import 'budget_golden_fixtures.dart';

/// The "Pagos programados del período" sheet (HU-12), opened from the
/// detail hero's "Programado" entry point. Read-only, no confirm button.
///
/// Pencil rows (`design-system/billetudo/pages/presupuestos.md`):
/// `sheet_scheduled_with_data` → `hFPFU` / `HH9m9` (con datos: `SheetHead`
/// with the "Suman $X de lo reservado este período" hint + one
/// `BudgetScheduledRow` per occurrence) ·
/// `sheet_scheduled_empty` → `Tg476` / `ZCYip` (vacío: shared `EmptyState`,
/// no CTA — the sheet has no action to take — and the head keeps only its
/// title, no hint repeating the empty message).
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required List<BudgetScheduledItem> items,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => BudgetScheduledSheet.show(
              context,
              items: items,
              totalMinor: 27000000,
              currency: 'COP',
              onOpenScheduledPayment: (_) {},
              onSeeAllScheduled: () {},
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

    testWidgets('pagos programados con datos ($suffix)', (tester) async {
      await golden(
        tester,
        'scheduled_with_data_$suffix',
        brightness: brightness,
        items: buildScheduledItems(),
      );
    });

    testWidgets('pagos programados vacío ($suffix)', (tester) async {
      await golden(
        tester,
        'scheduled_empty_$suffix',
        brightness: brightness,
        items: const [],
      );
    });
  }
}
