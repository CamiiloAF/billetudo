import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/features/budgets/presentation/widgets/sheets/budgets_menu_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../accounts/presentation/widgets/pump_widget.dart';

void main() {
  group('BudgetsMenuSheet', () {
    testWidgets('always offers the three options of `TmOGV`', (tester) async {
      await tester.pumpAppWidget(
        const BudgetsMenuSheet(envelopeEnabled: false),
      );

      final context = tester.element(find.byType(BudgetsMenuSheet));
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.budgetsMenuHistory), findsOneWidget);
      expect(find.text(l10n.budgetsMenuHistorySubtitle), findsOneWidget);
      expect(find.text(l10n.budgetsMenuEnableEnvelope), findsOneWidget);
      expect(
        find.text(l10n.budgetsMenuEnableEnvelopeSubtitle),
        findsOneWidget,
      );
      expect(find.text(l10n.envelopeInfoTitle), findsOneWidget);
      expect(find.text(l10n.budgetsMenuOptions), findsOneWidget);
    });

    testWidgets('with envelope mode on, the middle row turns it off',
        (tester) async {
      await tester.pumpAppWidget(
        const BudgetsMenuSheet(envelopeEnabled: true),
      );

      final context = tester.element(find.byType(BudgetsMenuSheet));
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.budgetsMenuDisableEnvelope), findsOneWidget);
      expect(
        find.text(l10n.budgetsMenuDisableEnvelopeSubtitle),
        findsOneWidget,
      );
      expect(find.text(l10n.budgetsMenuEnableEnvelope), findsNothing);
    });

    testWidgets('each row pops its own action', (tester) async {
      BudgetsMenuAction? result;
      await tester.pumpAppWidget(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await BudgetsMenuSheet.show(
                context,
                envelopeEnabled: false,
              );
            },
            child: const Text('open'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(BudgetsMenuSheet));
      final l10n = AppLocalizations.of(context);
      await tester.tap(find.text(l10n.budgetsMenuHistory));
      await tester.pumpAndSettle();

      expect(result, BudgetsMenuAction.history);
    });
  });
}
