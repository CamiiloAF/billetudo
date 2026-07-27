import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_threshold_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// The alert-threshold sheet (HU-08): presets 70/80/90 + Personalizado +
/// "No avisarme", default 80.
///
/// Pencil row (`design-system/billetudo/pages/presupuestos.md`):
/// `threshold_preset_80`, `threshold_custom` and `threshold_off` → `m3jomu` /
/// `GNQ49` (Sheet — umbral de alerta). The three business states the sheet can
/// open in: a preset selected (the 80% default), a custom value selected (85%,
/// which highlights the stepper value in `$primary` and leaves every preset
/// unchecked) and "No avisarme" (`pct == null`, a real savable value — not the
/// same as dismissing the sheet).
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    int? selected,
    String name, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                BudgetThresholdSheet.show(context, selected: selected),
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

    testWidgets('umbral: preset 80% (default) ($suffix)', (tester) async {
      await golden(
        tester,
        80,
        'threshold_preset_80_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('umbral: personalizado 85% ($suffix)', (tester) async {
      await golden(
        tester,
        85,
        'threshold_custom_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('umbral: no avisarme ($suffix)', (tester) async {
      await golden(
        tester,
        null,
        'threshold_off_$suffix',
        brightness: brightness,
      );
    });
  }
}
