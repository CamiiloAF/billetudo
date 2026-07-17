import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/utils/money_formatter.dart';
import 'package:billetudo/features/budgets/domain/entities/zero_based_summary.dart';
import 'package:billetudo/features/budgets/presentation/widgets/envelope_hero.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../accounts/presentation/widgets/pump_widget.dart';

void main() {
  const money = MoneyFormatter();

  group('EnvelopeHero', () {
    testWidgets(
        'still-to-assign: shows the "unassigned" label and the positive '
        'amount', (tester) async {
      const summary = ZeroBasedSummary(
        currency: 'COP',
        incomeMinor: 500000,
        assignedMinor: 300000,
      );
      await tester.pumpAppWidget(const EnvelopeHero(summary: summary));

      final context = tester.element(find.byType(EnvelopeHero));
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.budgetsEnvelopeUnassignedLabel), findsOneWidget);
      expect(
        find.text(money.format(200000, currencyCode: 'COP')),
        findsOneWidget,
      );
      expect(
        find.text(
          l10n.budgetsEnvelopeCaption(
            money.format(500000, currencyCode: 'COP'),
            money.format(300000, currencyCode: 'COP'),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('over-assigned: shows the "over" label and the absolute value',
        (tester) async {
      const summary = ZeroBasedSummary(
        currency: 'COP',
        incomeMinor: 300000,
        assignedMinor: 500000,
      );
      await tester.pumpAppWidget(const EnvelopeHero(summary: summary));

      final context = tester.element(find.byType(EnvelopeHero));
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.budgetsEnvelopeOverLabel), findsOneWidget);
      // unassignedMinor is -200000; the headline shows the absolute value.
      expect(
        find.text(money.format(200000, currencyCode: 'COP')),
        findsOneWidget,
      );
    });

    testWidgets(
        'all-assigned: shows the celebratory caption instead of the '
        'income/assigned breakdown', (tester) async {
      const summary = ZeroBasedSummary(
        currency: 'COP',
        incomeMinor: 400000,
        assignedMinor: 400000,
      );
      await tester.pumpAppWidget(const EnvelopeHero(summary: summary));

      final context = tester.element(find.byType(EnvelopeHero));
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.budgetsEnvelopeAllAssigned), findsOneWidget);
      expect(
        find.text(money.format(0, currencyCode: 'COP')),
        findsOneWidget,
      );
    });
  });
}
