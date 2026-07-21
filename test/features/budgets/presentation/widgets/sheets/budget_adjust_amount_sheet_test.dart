import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/budgets/presentation/utils/budget_adjustment_windows.dart';
import 'package:billetudo/features/budgets/presentation/utils/budget_format.dart';
import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_adjust_amount_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../domain/budget_fixtures.dart';

/// "Ajustar monto — este período" (fix-budget-adjust-current-period): the
/// mechanism now retargets the fork to `currentWindow` (the amount rules
/// starting *today*, not the next cycle), so the sheet must label the new
/// amount and the explainer dates with `windows.current`/`windows.next`, not
/// `windows.next`/`windows.resume` — see `BudgetAdjustmentWindows` and
/// `docs/dev-runs/fix-budget-adjust-current-period.md` for the retargeted
/// window roles. This locks that contract at the widget level, independent
/// of the golden pixels.
void main() {
  final budget = buildBudget(
    id: 'bud-tarjeta',
    name: 'Tarjeta de crédito',
    amountMinor: 450000000,
    // Anchored well before `now` below so `currentWindow.index > 0` — the
    // general (fork of 3 parts) shape, not the `index == 0` edge case.
    startDate: DateTime(2025, 1, 21),
  );
  final now = DateTime(2025, 7, 25);
  final windows = BudgetAdjustmentWindows(budget, now);

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BudgetAdjustAmountSheet(
              currentAmountMinor: budget.amountMinor,
              currency: budget.currency,
              windows: windows,
            ),
          ),
        ),
      );

  testWidgets(
      'labels the new amount with the CURRENT period range, not the next one',
      (tester) async {
    await pump(tester);

    final currentRange = BudgetFormat.rangeLabel(windows.current);
    final nextRange = BudgetFormat.rangeLabel(windows.next);

    // The amount typed in this sheet takes effect for the rest of the
    // *current* cycle (AC1/AC3) — its label must say so, not name the next
    // cycle's range.
    expect(
      find.textContaining(currentRange, findRichText: true),
      findsWidgets,
      reason: 'the "new amount" label should quote the current period '
          '($currentRange), the one the adjustment actually covers',
    );
    expect(
      find.textContaining(nextRange, findRichText: true),
      findsNothing,
      reason: 'the "new amount" label still names the next period '
          '($nextRange) — the fork was retargeted to the current period but '
          'this label was not',
    );
  });

  testWidgets(
      'the explainer names effectiveFrom = current period start, '
      'resumeFrom = next period start', (tester) async {
    await pump(tester);

    final effectiveFrom = BudgetFormat.dayMonth(windows.current.start);
    final resumeFrom = BudgetFormat.dayMonth(windows.next.start);
    final wrongEffectiveFrom = BudgetFormat.dayMonth(windows.next.start);
    final wrongResumeFrom = BudgetFormat.dayMonth(windows.resume.start);

    expect(
      find.textContaining(effectiveFrom, findRichText: true),
      findsWidgets,
      reason: 'the explainer should say the new amount starts on '
          '$effectiveFrom (currentWindow.start), per AC3',
    );
    expect(
      find.textContaining(resumeFrom, findRichText: true),
      findsWidgets,
      reason: 'the explainer should say the original amount resumes on '
          '$resumeFrom (nextWindow.start), per AC3',
    );
    // Both wrong-labels checks are meaningful only when they differ from the
    // correct dates for this fixture (guards against a false pass if the
    // fixture ever makes current/next/resume collide by coincidence).
    expect(wrongEffectiveFrom, isNot(effectiveFrom));
    expect(wrongResumeFrom, isNot(resumeFrom));
    expect(
      find.textContaining(wrongResumeFrom, findRichText: true),
      findsNothing,
      reason: 'the explainer still names the period-after-next '
          '($wrongResumeFrom) as the resume date — a leftover from the old '
          '"next period" mechanic',
    );
  });
}
