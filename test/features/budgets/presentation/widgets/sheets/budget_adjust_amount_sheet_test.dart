import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/budgets/domain/services/budget_period_calculator.dart';
import 'package:billetudo/features/budgets/presentation/utils/budget_adjustment_windows.dart';
import 'package:billetudo/features/budgets/presentation/utils/budget_format.dart';
import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_adjust_amount_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../domain/budget_fixtures.dart';

/// "Ajustar monto" (per-period override, design `A8ZfHd`/`D0EoN`): the amount
/// applies to the window the stepper is showing (`windows.target`), so the
/// field label names that window's range and shows the base amount inline
/// ("Actual $X"); the explainer names `windows.resume.start` as the date the
/// base amount takes back over. This locks that contract at the widget level,
/// independent of the golden pixels.
void main() {
  final budget = buildBudget(
    id: 'bud-tarjeta',
    name: 'Tarjeta de crédito',
    amountMinor: 450000000,
    startDate: DateTime(2025, 1, 21),
  );
  final now = DateTime(2025, 7, 25);
  final calculator = BudgetPeriodCalculator(budget);
  final visible = calculator.currentWindow(now);
  final windows = BudgetAdjustmentWindows(budget, visible, now);

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

  testWidgets('labels the new amount with the TARGET (visible) period range', (
    tester,
  ) async {
    await pump(tester);

    final targetRange = BudgetFormat.rangeLabel(windows.target, 'es');
    final resumeRange = BudgetFormat.rangeLabel(windows.resume, 'es');
    // Guard against a fixture where target/resume ranges collide.
    expect(targetRange, isNot(resumeRange));

    // The amount typed here takes effect for the visible/target cycle — the
    // "new amount" label must quote that period's range.
    expect(
      find.textContaining(targetRange, findRichText: true),
      findsWidgets,
      reason: 'the "new amount" label should quote the target period '
          '($targetRange), the one the override actually covers',
    );
  });

  testWidgets(
      'the explainer names the resume date = the window after the target', (
    tester,
  ) async {
    await pump(tester);

    final resumeFrom = BudgetFormat.dayMonth(windows.resume.start, 'es');
    final targetStart = BudgetFormat.dayMonth(windows.target.start, 'es');

    expect(
      find.textContaining(resumeFrom, findRichText: true),
      findsWidgets,
      reason: 'the explainer should say the base amount resumes on '
          '$resumeFrom (the window after target)',
    );
    // Guards against a false pass if the fixture ever makes the windows
    // collide by coincidence.
    expect(targetStart, isNot(resumeFrom));
  });
}
