import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_threshold_custom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// Where the "Personalizado ›" chevron of `m3jomu/bWlly` leads.
///
/// **No Pencil frame exists for this destination**: `billetudo.pen` draws the
/// chevron but never designs what it opens, so this golden has nothing to be
/// audited against — it only locks the current, primitives-only composition
/// (`Bottom Sheet Base` head + stepper + `Button/Primary`) so it can't drift
/// silently before design ships the real frame.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required int initial,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                BudgetThresholdCustomSheet.show(context, initial: initial),
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

    testWidgets('umbral personalizado: stepper en 85% ($suffix)',
        (tester) async {
      await golden(
        tester,
        'threshold_custom_stepper_$suffix',
        brightness: brightness,
        initial: 85,
      );
    });

    testWidgets(
        'umbral personalizado: stepper en mínimo 5% (menos deshabilitado) ($suffix)',
        (tester) async {
      await golden(
        tester,
        'threshold_custom_stepper_min_$suffix',
        brightness: brightness,
        initial: 5,
      );
    });

    testWidgets(
        'umbral personalizado: stepper en máximo 100% (más deshabilitado) ($suffix)',
        (tester) async {
      await golden(
        tester,
        'threshold_custom_stepper_max_$suffix',
        brightness: brightness,
        initial: 100,
      );
    });
  }
}
