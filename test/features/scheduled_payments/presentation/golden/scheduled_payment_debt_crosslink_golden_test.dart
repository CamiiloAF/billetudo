import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_linked_debt.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_debt_chip.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_linked_debt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// The Deudas ⇄ Pagos Programados cross-link, PP side (HU-03):
///   - `ScheduledPaymentLinkedDebtCard` (`M7Ijh`), the "Cuota de: <deuda>" card
///     on a cuota's detail — captured for both directions (Yo debo / Me deben).
///   - `ScheduledDebtChip` (`Y5FQT`), the subtle `$primary-soft` "Deuda" badge
///     appended to a `ScheduledCard`'s chip row.
/// Each in light and dark.
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
      size: const Size(390, 240),
    );
    await expectLater(
      find.byType(Padding).first,
      matchesGoldenFile('goldens/scheduled_debt_crosslink_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('linked debt card, yo debo ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentLinkedDebtCard(
          debt: const ScheduledPaymentLinkedDebt(
            id: 'd1',
            name: 'Crédito vehicular',
            iOwe: true,
          ),
          onTap: () {},
        ),
        'linked_card_i_owe_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('linked debt card, me deben ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentLinkedDebtCard(
          debt: const ScheduledPaymentLinkedDebt(
            id: 'd2',
            name: 'Le presté a Andrés',
            iOwe: false,
          ),
          onTap: () {},
        ),
        'linked_card_owed_to_me_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('debt chip ($suffix)', (tester) async {
      await golden(
        tester,
        const ScheduledDebtChip(),
        'debt_chip_$suffix',
        brightness: brightness,
      );
    });
  }
}
