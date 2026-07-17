import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/widgets/budget_usage_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/accounts/presentation/widgets/pump_widget.dart';

void main() {
  group('BudgetUsageNotice', () {
    testWidgets('renders nothing when count is 0', (tester) async {
      await tester.pumpAppWidget(const BudgetUsageNotice(count: 0));

      final sizedBoxUnderNotice = find.descendant(
        of: find.byType(BudgetUsageNotice),
        matching: find.byType(SizedBox),
      );
      expect(sizedBoxUnderNotice, findsOneWidget);
      final sizedBox = tester.widget<SizedBox>(sizedBoxUnderNotice);
      expect(sizedBox.width, 0);
      expect(sizedBox.height, 0);
      expect(
        find.descendant(
          of: find.byType(BudgetUsageNotice),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
    });

    testWidgets('shows the singular impact message when count is 1',
        (tester) async {
      await tester.pumpAppWidget(const BudgetUsageNotice(count: 1));

      final context = tester.element(find.byType(BudgetUsageNotice));
      final l10n = AppLocalizations.of(context);
      expect(find.text(l10n.deleteImpactBudgets(1)), findsOneWidget);
    });

    testWidgets('shows the plural impact message when count > 1',
        (tester) async {
      await tester.pumpAppWidget(const BudgetUsageNotice(count: 3));

      final context = tester.element(find.byType(BudgetUsageNotice));
      final l10n = AppLocalizations.of(context);
      expect(find.text(l10n.deleteImpactBudgets(3)), findsOneWidget);
    });
  });
}
