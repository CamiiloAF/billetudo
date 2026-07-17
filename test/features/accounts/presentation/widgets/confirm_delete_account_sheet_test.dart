import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/widgets/budget_usage_notice.dart';
import 'package:billetudo/features/accounts/domain/entities/account_deletion_impact.dart';
import 'package:billetudo/features/accounts/presentation/widgets/sheets/confirm_delete_account_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

void main() {
  group('aviso de impacto en presupuestos (Presupuestos HU-06)', () {
    // Mirrors the category sheets: the impact line is rendered by the shared
    // `BudgetUsageNotice` widget, not folded into `SheetMessage.message`.
    testWidgets('budgetCount > 0 agrega el aviso con el conteo',
        (tester) async {
      const impact = AccountDeletionImpact(
        transactionCount: 0,
        goalCount: 0,
        debtCount: 0,
        isLastAccount: false,
        budgetCount: 2,
      );
      await tester
          .pumpAppWidget(const ConfirmDeleteAccountSheet(impact: impact));

      final context = tester.element(find.byType(ConfirmDeleteAccountSheet));
      final l10n = AppLocalizations.of(context);
      expect(find.byType(BudgetUsageNotice), findsOneWidget);
      expect(find.text(l10n.deleteImpactBudgets(2)), findsOneWidget);
    });

    testWidgets('budgetCount 0 no agrega ningún aviso', (tester) async {
      const impact = AccountDeletionImpact(
        transactionCount: 0,
        goalCount: 0,
        debtCount: 0,
        isLastAccount: false,
      );
      await tester
          .pumpAppWidget(const ConfirmDeleteAccountSheet(impact: impact));

      final context = tester.element(find.byType(ConfirmDeleteAccountSheet));
      final l10n = AppLocalizations.of(context);
      expect(find.textContaining(l10n.deleteImpactBudgets(1)), findsNothing);
      expect(find.text(l10n.accountDeleteSheetMessage), findsOneWidget);
    });

    testWidgets(
        'con transacciones y presupuestos, ambos avisos conviven en el sheet',
        (tester) async {
      const impact = AccountDeletionImpact(
        transactionCount: 5,
        goalCount: 0,
        debtCount: 0,
        isLastAccount: false,
        budgetCount: 3,
      );
      await tester
          .pumpAppWidget(const ConfirmDeleteAccountSheet(impact: impact));

      final context = tester.element(find.byType(ConfirmDeleteAccountSheet));
      final l10n = AppLocalizations.of(context);
      expect(find.text(l10n.accountDeleteSheetImpact(5)), findsOneWidget);
      expect(find.text(l10n.deleteImpactBudgets(3)), findsOneWidget);
    });
  });
}
