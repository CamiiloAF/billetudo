import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';
import '../../scheduled_payment_fixtures.dart';

/// `ScheduledPaymentHeroCard`/`ScheduledPaymentConfirmNowButton` — "Confirmar
/// ahora" (`Ht24a` in `OY2Kj`, `docs/bugfixes.md` point 1). The full detail
/// page golden (`scheduled_payment_detail_page_golden_test.dart`) already
/// exercises the CTA inside the whole page; this file isolates the widget so
/// the four `showConfirmNow` criteria are each covered on their own, without
/// the rest of the page's content as noise.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  // Fixed relative-to-today date, same reasoning as the page golden: keeps
  // the "en N días" countdown pill stable across days instead of drifting.
  DateTime inDays(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
  }

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
      size: const Size(390, 420),
    );
    await expectLater(
      find.byWidget(child),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('ScheduledPaymentConfirmNowButton standalone ($suffix)',
        (tester) async {
      await golden(
        tester,
        ScheduledPaymentConfirmNowButton(onTap: () {}),
        'scheduled_payment_confirm_now_button_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'ScheduledPaymentHeroCard: automático, no vencido, sin pendiente — '
        'muestra "Confirmar ahora" ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentHeroCard(
          payment: buildScheduledPayment(nextDate: inDays(5)),
          pending: null,
          onTapPending: () {},
          onConfirmNow: () {},
        ),
        'scheduled_payment_hero_card_confirm_now_visible_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'ScheduledPaymentHeroCard: modo manual, no vencido, sin pendiente — '
        'también muestra "Confirmar ahora" ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentHeroCard(
          payment: buildScheduledPayment(
            nextDate: inDays(5),
            requiresConfirmation: true,
          ),
          pending: null,
          onTapPending: () {},
          onConfirmNow: () {},
        ),
        'scheduled_payment_hero_card_confirm_now_visible_manual_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'ScheduledPaymentHeroCard: plantilla borrada (tombstoned) — nunca '
        'muestra "Confirmar ahora" ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentHeroCard(
          payment: buildScheduledPayment(
            nextDate: inDays(5),
            tombstonedAt: DateTime(2026, 8),
          ),
          pending: null,
          onTapPending: () {},
          onConfirmNow: () {},
        ),
        'scheduled_payment_hero_card_confirm_now_hidden_deleted_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'ScheduledPaymentHeroCard: ya hay una ocurrencia pendiente — el CTA '
        'sigue visible (confirma esa ocurrencia) ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentHeroCard(
          payment: buildScheduledPayment(nextDate: inDays(-1)),
          pending: buildPendingOccurrence(),
          onTapPending: () {},
          onConfirmNow: () {},
        ),
        'scheduled_payment_hero_card_confirm_now_visible_pending_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'ScheduledPaymentHeroCard: pago único ya ejecutado (executed) — '
        'nunca muestra "Confirmar ahora" ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentHeroCard(
          payment: buildScheduledPayment(
            frequency: ScheduledPaymentFrequency.once,
            nextDate: inDays(-30),
          ),
          pending: null,
          executed: true,
          onTapPending: () {},
          onConfirmNow: () {},
        ),
        'scheduled_payment_hero_card_confirm_now_hidden_executed_$suffix',
        brightness: brightness,
      );
    });
  }
}
