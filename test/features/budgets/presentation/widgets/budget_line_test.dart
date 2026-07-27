import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_line.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../accounts/presentation/widgets/pump_widget.dart';
import '../../domain/budget_fixtures.dart';

void main() {
  BudgetWithProgress entry({
    required String name,
    required int spentMinor,
    int scheduledMinor = 0,
    BudgetScope scope = const BudgetScope.empty(),
  }) =>
      BudgetWithProgress(
        budget: buildBudget(name: name, startDate: DateTime(2026, 7)),
        scope: scope,
        window: BudgetPeriodWindow(
          start: DateTime(2026, 7),
          endExclusive: DateTime(2026, 8),
          index: 0,
          status: BudgetWindowStatus.current,
          hasPrevious: false,
          hasNext: true,
        ),
        progress: BudgetProgress(
          amountMinor: 600000,
          spentMinor: spentMinor,
          daysLeft: 18,
          scheduledMinor: scheduledMinor,
        ),
      );

  Future<void> pump(WidgetTester tester, BudgetWithProgress value) =>
      tester.pumpAppWidget(
        SizedBox(
          width: 350,
          child: BudgetLine(entry: value, onTap: () {}),
        ),
      );

  group('BudgetLine', () {
    testWidgets(
        'keeps the percent visible with a long name and a long scope '
        '(`vdyCS` is anchored right, not glued to the meta string)',
        (tester) async {
      await pump(
        tester,
        entry(
          name: 'Tarjeta de crédito Bancolombia para gastos del hogar',
          spentMinor: 492000,
          scope: const BudgetScope(
            accounts: [
              BudgetScopeRef(id: 'a1', referentAlive: true),
              BudgetScopeRef(id: 'a2', referentAlive: true),
            ],
            categories: [
              BudgetScopeRef(id: 'c1', referentAlive: true),
              BudgetScopeRef(id: 'c2', referentAlive: true),
              BudgetScopeRef(id: 'c3', referentAlive: true),
            ],
          ),
        ),
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(BudgetLine)));
      expect(find.text(l10n.budgetPercent(82)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the remaining amount with the `\$` symbol, no code',
        (tester) async {
      await pump(tester, entry(name: 'Mercado', spentMinor: 492000));

      expect(find.text(r'$1.080'), findsOneWidget);
      expect(find.textContaining('COP'), findsNothing);
    });

    testWidgets(
        'overspent paints only the percent and the right block red — the '
        'meta line stays `\$text-secondary`', (tester) async {
      await pump(tester, entry(name: 'Restaurantes', spentMinor: 720000));

      final context = tester.element(find.byType(BudgetLine));
      final colors = context.colors;
      final l10n = AppLocalizations.of(context);

      final percent = tester.widget<Text>(find.text(l10n.budgetPercent(120)));
      expect(percent.style?.color, colors.expenseText);

      final amount = tester.widget<Text>(find.text(r'$1.200'));
      expect(amount.style?.color, colors.expenseText);

      final meta = tester.widget<Text>(
        find.textContaining(l10n.budgetScopeGlobal),
      );
      expect(meta.style?.color, colors.textSecondary);
    });

    testWidgets(
        'HU-12: a row with nothing scheduled shows no calendar-clock icon '
        'and no third bar segment (zero regression)', (tester) async {
      await pump(tester, entry(name: 'Mercado', spentMinor: 492000));

      expect(find.byIcon(LucideIcons.calendarClock), findsNothing);

      final bar = tester.widget<BudgetProgressBar>(
        find.byType(BudgetProgressBar),
      );
      expect(bar.scheduledFraction, 0);
      expect(bar.scheduledAtRisk, isFalse);
    });

    testWidgets(
        'HU-12: a healthy scheduled amount adds a `\$text-secondary` '
        'calendar-clock icon and a `\$primary-light` bar segment',
        (tester) async {
      await pump(
        tester,
        entry(
          name: 'Mercado del mes',
          spentMinor: 492000,
          scheduledMinor: 50000,
        ),
      );

      final context = tester.element(find.byType(BudgetLine));
      final colors = context.colors;

      final icon = tester.widget<Icon>(
        find.byIcon(LucideIcons.calendarClock),
      );
      expect(icon.color, colors.textSecondary);

      final bar = tester.widget<BudgetProgressBar>(
        find.byType(BudgetProgressBar),
      );
      expect(bar.scheduledFraction, greaterThan(0));
      expect(bar.scheduledAtRisk, isFalse);
    });

    testWidgets(
        'HU-12: a projected overdraw risk shows "Podría exceder por" in '
        '`\$amber-text`, an amber calendar-clock icon and an `\$amber` bar '
        'segment', (tester) async {
      await pump(
        tester,
        entry(
          name: 'Tarjeta de crédito',
          spentMinor: 492000,
          scheduledMinor: 150000,
        ),
      );

      final context = tester.element(find.byType(BudgetLine));
      final colors = context.colors;
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.budgetAtRiskLabel), findsOneWidget);
      final label = tester.widget<Text>(find.text(l10n.budgetAtRiskLabel));
      expect(label.style?.color, colors.amberText);

      // spentMinor + scheduledMinor - amountMinor = 492000 + 150000 - 600000.
      final amount = tester.widget<Text>(find.text(r'$420'));
      expect(amount.style?.color, colors.amberText);

      final icon = tester.widget<Icon>(
        find.byIcon(LucideIcons.calendarClock),
      );
      expect(icon.color, colors.amberText);

      // The `%` itself stays gray in risk — only the icon/stack carry amber
      // (matches the `.pen` demo `kFB7X`, not a literal reading of the `.md`).
      final percent = tester.widget<Text>(find.text(l10n.budgetPercent(82)));
      expect(percent.style?.color, colors.textSecondary);

      final bar = tester.widget<BudgetProgressBar>(
        find.byType(BudgetProgressBar),
      );
      expect(bar.scheduledAtRisk, isTrue);
      expect(bar.scheduledFraction, greaterThan(0));
    });
  });
}
