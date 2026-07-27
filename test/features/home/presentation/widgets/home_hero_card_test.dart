import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/home/domain/entities/month_spending.dart';
import 'package:billetudo/features/home/presentation/widgets/home_hero_budget_progress.dart';
import 'package:billetudo/features/home/presentation/widgets/home_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../home_fixtures.dart';
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
    BudgetWithProgress? budgetProgress,
  }) =>
      HomeHeroCard(
        spending: spending,
        monthLabel: 'Julio',
        onMonthTap: onMonthTap ?? () {},
        onCreateBudget: onCreateBudget ?? () {},
        budgetProgress: budgetProgress,
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

  group('con presupuesto global mensual (HU-03, aOhoY)', () {
    testWidgets(
        'con budgetProgress: renderiza la barra en vez de la invitación o '
        'el mensaje de "sin gastos"', (tester) async {
      final budgetProgress = buildHomeBudgetProgress(
        amountMinor: 600000,
        spentMinor: 300000,
        daysLeft: 12,
      );
      await tester.pumpHomeWidget(
        hero(spendingWith(300000), budgetProgress: budgetProgress),
      );

      expect(find.byType(HomeHeroBudgetProgress), findsOneWidget);
      expect(find.byType(BudgetInvitationLink), findsNothing);
      expect(find.text('Aún no hay gastos este mes'), findsNothing);
    });

    testWidgets('muestra el porcentaje y el monto gastado correctos',
        (tester) async {
      final budgetProgress = buildHomeBudgetProgress(
        amountMinor: 600000,
        spentMinor: 300000,
        daysLeft: 12,
      );
      await tester.pumpHomeWidget(
        hero(spendingWith(300000), budgetProgress: budgetProgress),
      );

      // 300000 / 600000 = 50%, $3.000 (COP shows no decimals, cents to
      // pesos).
      expect(find.textContaining('50%'), findsOneWidget);
      expect(find.textContaining('3.000'), findsOneWidget);
    });

    testWidgets('muestra los días restantes de la ventana', (tester) async {
      final budgetProgress = buildHomeBudgetProgress(
        amountMinor: 600000,
        spentMinor: 300000,
        daysLeft: 12,
      );
      await tester.pumpHomeWidget(
        hero(spendingWith(300000), budgetProgress: budgetProgress),
      );

      expect(find.textContaining('12'), findsOneWidget);
    });

    testWidgets(
        'sin budgetProgress: cae de vuelta a la invitación con gastos '
        '(HU-03)', (tester) async {
      await tester.pumpHomeWidget(hero(spendingWith(50000)));

      expect(find.byType(HomeHeroBudgetProgress), findsNothing);
      expect(find.byType(BudgetInvitationLink), findsOneWidget);
    });

    testWidgets('sin budgetProgress y sin gastos: cae al mensaje "sin gastos"',
        (tester) async {
      await tester.pumpHomeWidget(hero(spendingWith(0)));

      expect(find.byType(HomeHeroBudgetProgress), findsNothing);
      expect(find.text('Aún no hay gastos este mes'), findsOneWidget);
    });
  });
}
