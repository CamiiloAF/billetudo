import 'package:billetudo/features/goals/presentation/widgets/goal_quick_amount_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';
import '../goals_presentation_fixtures.dart';

/// `GoalQuickAmountRow` (design-system/billetudo/pages/metas.md, `Qi3aR`/
/// `HKc12`): the horizontally-scrolling "Aporte rápido" row — the two fixed
/// $50.000/$100.000 chips, then the goal's own custom chips (oldest first,
/// each with an inline "x", `Vspnx`/`tst9V`), then the fixed "Otro monto"
/// chip and the "+ Nueva" chip (`goal_add_quick_amount_chip.dart`), always
/// last. The full detail page golden already exercises this row inside the
/// whole page; this file isolates it so both chip-population states are
/// covered without the rest of the page as noise.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    Widget child,
    String name, {
    required Brightness brightness,
  }) async {
    await pumpGolden(
      tester,
      Padding(padding: const EdgeInsets.all(16), child: child),
      brightness: brightness,
      size: const Size(390, 100),
    );
    await expectLater(
      find.byWidget(child),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    // Meta recién creada: sin aportes rápidos propios todavía — solo los dos
    // chips fijos, seguidos de "Otro monto" y "+ Nueva".
    testWidgets('solo chips fijos, sin personalizados ($suffix)',
        (tester) async {
      await golden(
        tester,
        GoalQuickAmountRow(
          currency: 'COP',
          customAmounts: const [],
          onQuickAmount: (_) {},
          onOther: () {},
          onAddNew: () {},
          onRemoveCustom: (_) {},
        ),
        'goal_quick_amount_row_fixed_only_$suffix',
        brightness: brightness,
      );
    });

    // Con chips personalizados: cada uno con su "x" inline (`Vspnx`/`tst9V`),
    // y "Otro monto"/"+ Nueva" siguen visibles al final, scrolleable.
    testWidgets(
        'chips personalizados con "x" + "Otro monto" + "+ Nueva" ($suffix)',
        (tester) async {
      await golden(
        tester,
        GoalQuickAmountRow(
          currency: 'COP',
          customAmounts: [
            buildGoalQuickAmount(
              id: 'qa1',
              amountMinor: 3000000,
              createdAt: DateTime(2026, 6, 1),
            ),
            buildGoalQuickAmount(
              id: 'qa2',
              amountMinor: 750000,
              createdAt: DateTime(2026, 7, 1),
            ),
          ],
          onQuickAmount: (_) {},
          onOther: () {},
          onAddNew: () {},
          onRemoveCustom: (_) {},
        ),
        'goal_quick_amount_row_with_custom_$suffix',
        brightness: brightness,
      );
    });
  }
}
