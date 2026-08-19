import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_linked_goal.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_linked_goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// The Metas ⇄ Pagos Programados cross-link, PP side (HU-16):
/// `ScheduledPaymentLinkedGoalCard` (`baoEJ` in `a2yR8P`/`tnaj3`), the "META
/// ENLAZADA · Aporte a <meta>" card on a recurring contribution's detail —
/// same chrome as `ScheduledPaymentLinkedDebtCard`, mutually exclusive with
/// it. Light and dark.
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
      Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
      brightness: brightness,
      size: const Size(390, 200),
    );
    await expectLater(
      find.byType(Padding).first,
      matchesGoldenFile('goldens/scheduled_goal_crosslink_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('linked goal card ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentLinkedGoalCard(
          goal: const ScheduledPaymentLinkedGoal(
            id: 'g1',
            name: 'Viaje a Cartagena',
          ),
          onTap: () {},
        ),
        'linked_card_$suffix',
        brightness: brightness,
      );
    });
  }

  testWidgets('tocarla navega al detalle de la meta', (tester) async {
    String? tappedGoalId;
    await pumpGolden(
      tester,
      ScheduledPaymentLinkedGoalCard(
        goal: const ScheduledPaymentLinkedGoal(id: 'g1', name: 'Viaje'),
        onTap: () => tappedGoalId = 'g1',
      ),
      brightness: Brightness.light,
    );

    await tester.tap(find.text('Viaje'));
    await tester.pumpAndSettle();

    expect(tappedGoalId, 'g1');
  });
}
