import 'package:billetudo/features/goals/presentation/widgets/goal_quick_amount_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';
import '../goals_presentation_fixtures.dart';

/// `GoalQuickAmountRow` (design-system/billetudo/pages/metas.md, `Qi3aR`/
/// `HKc12`): the horizontally-scrolling "Aporte rápido" row — a single
/// uniform list of `customAmounts` (the two default $50.000/$100.000 chips
/// are seeded as real `GoalQuickAmount` rows by `CreateGoal`, so they arrive
/// through this same list), every one of them with an inline "x"
/// (`Vspnx`/`tst9V`), then the "+ Nueva" chip
/// (`goal_add_quick_amount_chip.dart`), always last. There is no fixed
/// "Otro monto" chip anymore — the detail's "+ Aportar" CTA already covers
/// that path. The full detail page golden already exercises this row inside
/// the whole page; this file isolates it so both chip-population states are
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

    // Meta sin ningún chip todavía (caso teórico, hoy `CreateGoal` siembra
    // los dos por defecto): solo queda visible "+ Nueva".
    testWidgets('sin chips ($suffix)', (tester) async {
      await golden(
        tester,
        GoalQuickAmountRow(
          currency: 'COP',
          customAmounts: const [],
          onQuickAmount: (_) {},
          onAddNew: () {},
          onRemoveCustom: (_) {},
        ),
        'goal_quick_amount_row_empty_$suffix',
        brightness: brightness,
      );
    });

    // Meta recién creada: los dos chips sembrados por `CreateGoal`
    // ($50.000/$100.000) más un personalizado — todos con su "x" inline,
    // sin distinción visual, seguidos de "+ Nueva".
    testWidgets('todos los chips con "x" + "+ Nueva" ($suffix)',
        (tester) async {
      await golden(
        tester,
        GoalQuickAmountRow(
          currency: 'COP',
          customAmounts: [
            buildGoalQuickAmount(
              id: 'seed1',
              amountMinor: 5000000,
              createdAt: DateTime(2026, 6, 1),
            ),
            buildGoalQuickAmount(
              id: 'seed2',
              amountMinor: 10000000,
              createdAt: DateTime(2026, 6, 1),
            ),
            buildGoalQuickAmount(
              id: 'qa1',
              amountMinor: 750000,
              createdAt: DateTime(2026, 7, 1),
            ),
          ],
          onQuickAmount: (_) {},
          onAddNew: () {},
          onRemoveCustom: (_) {},
        ),
        'goal_quick_amount_row_with_custom_$suffix',
        brightness: brightness,
      );
    });
  }
}
