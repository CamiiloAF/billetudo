import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_scheduled_entry_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// HU-12: the "Programado" entry point (`s09qcC`/`pb88i`) — its own card
/// under the hero, switching to `$amber`/`$amber-text` when [atRisk] (a
/// projected overdraw), the documented exception to the sober palette.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool atRisk,
    VoidCallback? onTap,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: BudgetScheduledEntryCard(
              label: 'Programado',
              sub: atRisk
                  ? 'Excedería el presupuesto por \$90.000'
                  : '2 pagos próximos',
              amountLabel: '\$270.000',
              atRisk: atRisk,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      );

  testWidgets(
      r'sano: icon-wrap and amount use $primary/$primary-soft, not '
      'amber', (tester) async {
    await pump(tester, atRisk: false);

    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.calendarClock));
    expect(icon.color, AppColors.light.primary);

    final amount = tester.widget<Text>(find.text(r'$270.000'));
    expect(amount.style?.color, AppColors.light.textPrimary);
  });

  testWidgets(r'riesgo: icon-wrap, sub and amount switch to $amber/$amber-text',
      (tester) async {
    await pump(tester, atRisk: true);

    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.calendarClock));
    expect(icon.color, AppColors.light.amber);

    final amount = tester.widget<Text>(find.text(r'$270.000'));
    expect(amount.style?.color, AppColors.light.amberText);

    final sub = tester.widget<Text>(
      find.text('Excedería el presupuesto por \$90.000'),
    );
    expect(sub.style?.color, AppColors.light.amberText);
  });

  testWidgets('the whole card is tappable', (tester) async {
    var tapped = false;
    await pump(tester, atRisk: false, onTap: () => tapped = true);

    await tester.tap(find.byType(BudgetScheduledEntryCard));
    expect(tapped, isTrue);
  });
}
