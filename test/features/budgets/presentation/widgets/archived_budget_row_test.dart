import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/features/budgets/presentation/utils/budget_format.dart';
import 'package:billetudo/features/budgets/presentation/widgets/archived_budget_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../accounts/presentation/widgets/pump_widget.dart';
import '../golden/budget_golden_fixtures.dart';

void main() {
  group('ArchivedBudgetRow', () {
    testWidgets('shows the closed-on date, the scope and the "within" result '
        'with its own icon', (tester) async {
      final entry = archivedEntries.first;
      await tester.pumpAppWidget(
        ArchivedBudgetRow(entry: entry, onReactivate: () {}),
      );

      final context = tester.element(find.byType(ArchivedBudgetRow));
      final l10n = AppLocalizations.of(context);

      expect(
        find.text(
          l10n.budgetClosedOn(BudgetFormat.dayMonth(entry.budget.archivedAt!)),
        ),
        findsOneWidget,
      );
      expect(
        find.text(BudgetFormat.scopeLabel(l10n, entry.scope)),
        findsOneWidget,
      );
      expect(find.text(l10n.budgetResultWithin), findsOneWidget);
      // The check icon is present in the healthy case too, not only on
      // overspend.
      expect(find.byIcon(LucideIcons.circleCheckBig), findsOneWidget);
      expect(find.byIcon(LucideIcons.archiveRestore), findsOneWidget);
    });

    testWidgets('the footer reactivates', (tester) async {
      var reactivated = 0;
      await tester.pumpAppWidget(
        ArchivedBudgetRow(
          entry: archivedEntries.first,
          onReactivate: () => reactivated++,
        ),
      );

      await tester.tap(find.byType(ArchivedBudgetRowFooter));
      await tester.pump();

      expect(reactivated, 1);
    });

    testWidgets('an overspent close wears `circle-minus`', (tester) async {
      final overspent = archivedEntries.firstWhere(
        (entry) => entry.progress.isOverspent,
      );
      await tester.pumpAppWidget(
        ArchivedBudgetRow(entry: overspent, onReactivate: () {}),
      );

      expect(find.byIcon(LucideIcons.circleMinus), findsOneWidget);
      expect(find.byIcon(LucideIcons.circleCheckBig), findsNothing);
    });
  });
}
