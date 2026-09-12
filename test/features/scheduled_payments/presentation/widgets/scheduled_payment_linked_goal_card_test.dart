import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_linked_goal.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_linked_goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// The Metas ⇄ Pagos Programados cross-link, PP side (HU-16):
/// `ScheduledPaymentLinkedGoalCard` (`baoEJ` in `a2yR8P`/`tnaj3`), the "META
/// ENLAZADA · Aporte a <meta>" card on a recurring contribution's detail —
/// same chrome as `ScheduledPaymentLinkedDebtCard`, mutually exclusive with
/// it.
void main() {
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
