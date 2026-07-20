import 'package:billetudo/features/home/domain/entities/month_spending.dart';
import 'package:billetudo/features/home/presentation/widgets/home_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

void main() {
  final month = DateTime(2026, 7);

  MonthSpending spendingWith(int totalMinor, {String currency = 'COP'}) =>
      MonthSpending(
        month: month,
        subtotals: totalMinor == 0
            ? const []
            : [CurrencySpending(currency: currency, totalMinor: totalMinor)],
        displayCurrency: currency,
      );

  Widget hero(
    MonthSpending spending, {
    VoidCallback? onMonthTap,
    VoidCallback? onCreateBudget,
  }) =>
      HomeHeroCard(
        spending: spending,
        monthLabel: 'Julio',
        onMonthTap: onMonthTap ?? () {},
        onCreateBudget: onCreateBudget ?? () {},
      );

  testWidgets('con gastos: muestra "Gastado en <mes>", el monto y el chip',
      (tester) async {
    await tester.pumpHomeWidget(hero(spendingWith(126900)));

    expect(find.text('Gastado en Julio'), findsOneWidget);
    // 126900 cents => 1.269 COP (COP shows no decimals), from an int.
    expect(find.textContaining('1.269'), findsOneWidget);
    // The month selector chip repeats the label.
    expect(find.text('Julio'), findsOneWidget);
  });

  testWidgets(
      'con gastos: muestra la invitación a presupuesto, no el "sin '
      'gastos"', (tester) async {
    await tester.pumpHomeWidget(hero(spendingWith(50000)));

    expect(
      find.text('Define un presupuesto para ver cuánto te queda este mes'),
      findsOneWidget,
    );
    expect(find.text('Aún no hay gastos este mes'), findsNothing);
  });

  testWidgets('sin gastos: muestra "Aún no hay gastos" y NO la invitación',
      (tester) async {
    await tester.pumpHomeWidget(hero(spendingWith(0)));

    expect(find.text('Aún no hay gastos este mes'), findsOneWidget);
    expect(
      find.text('Define un presupuesto para ver cuánto te queda este mes'),
      findsNothing,
    );
    // A $0 hero, never inventing a budget cap (COP shows no decimals).
    expect(find.text(r'$0'), findsOneWidget);
  });

  testWidgets('tocar el chip de mes dispara onMonthTap (HU-04)',
      (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(
      hero(spendingWith(50000), onMonthTap: () => tapped++),
    );

    await tester.tap(find.byType(MonthSelectorChip));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('tocar la invitación dispara onCreateBudget (HU-03)',
      (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(
      hero(spendingWith(50000), onCreateBudget: () => tapped++),
    );

    await tester.tap(find.byType(BudgetInvitationLink));
    await tester.pump();

    expect(tapped, 1);
  });
}
