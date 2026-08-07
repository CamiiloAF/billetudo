import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/home/domain/entities/month_spending.dart';
import 'package:billetudo/features/home/presentation/widgets/home_hero_budget_progress.dart';
import 'package:billetudo/features/home/presentation/widgets/home_hero_card.dart';
import 'package:billetudo/features/home/presentation/widgets/month_selector_chip.dart';
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
    VoidCallback? onCreateBudget,
    VoidCallback? onOpenBudget,
    VoidCallback? onPreviousPeriod,
    VoidCallback? onNextPeriod,
    VoidCallback? onOpenMonthPicker,
    BudgetWithProgress? budgetProgress,
  }) =>
      HomeHeroCard(
        spending: spending,
        monthLabel: 'Julio',
        onCreateBudget: onCreateBudget ?? () {},
        onOpenBudget: onOpenBudget,
        onPreviousPeriod: onPreviousPeriod,
        onNextPeriod: onNextPeriod,
        onOpenMonthPicker: onOpenMonthPicker,
        budgetProgress: budgetProgress,
      );

  testWidgets(
      'sin presupuesto: muestra "Gastado en <mes>" y el monto, con el '
      'MonthSelectorChip (HU-04, restaurado)', (tester) async {
    await tester.pumpHomeWidget(
      hero(spendingWith(126900), onOpenMonthPicker: () {}),
    );

    expect(find.text('Gastado en Julio'), findsOneWidget);
    // 126900 cents => 1.269 COP (COP shows no decimals), from an int.
    expect(find.textContaining('1.269'), findsOneWidget);
    // Criterion 5: no budget-period stepper without a featured budget — the
    // calendar-month chip takes its spot instead.
    expect(find.byType(HeroPeriodStepper), findsNothing);
    expect(find.byType(MonthSelectorChip), findsOneWidget);
  });

  testWidgets(
      'sin presupuesto: tocar el MonthSelectorChip dispara onOpenMonthPicker',
      (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(
      hero(spendingWith(126900), onOpenMonthPicker: () => tapped++),
    );

    await tester.tap(find.byType(MonthSelectorChip));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets(
      'sin presupuesto y sin onOpenMonthPicker: no renderiza el chip '
      '(nada que tocar)', (tester) async {
    await tester.pumpHomeWidget(hero(spendingWith(126900)));

    expect(find.byType(MonthSelectorChip), findsNothing);
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

  group('con presupuesto destacado (HU-03/HU-05, aOhoY)', () {
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
        'con budgetProgress: nunca renderiza el MonthSelectorChip, aunque '
        'se le pase onOpenMonthPicker — el stepper toma su lugar',
        (tester) async {
      final budgetProgress = buildHomeBudgetProgress();
      await tester.pumpHomeWidget(
        hero(
          spendingWith(300000),
          budgetProgress: budgetProgress,
          onOpenMonthPicker: () {},
        ),
      );

      expect(find.byType(MonthSelectorChip), findsNothing);
      expect(find.byType(HeroPeriodStepper), findsOneWidget);
    });

    testWidgets(
        'criterio 3: el stepper muestra la ventana real del presupuesto, '
        'nunca un nombre de mes calendario', (tester) async {
      final budgetProgress = buildHomeBudgetProgress();
      await tester.pumpHomeWidget(
        hero(spendingWith(300000), budgetProgress: budgetProgress),
      );

      // The fixture's window is `[2026-07-01, 2026-08-01)`, so its real
      // range is "1–31 jul" — never "Julio" (the calendar-month label).
      expect(find.text('1–31 jul'), findsOneWidget);
      expect(find.text('Gastado en Julio'), findsNothing);
      expect(find.byType(HeroPeriodStepper), findsOneWidget);
      // Its status half reads separately (xBv3N `b9eQy`).
      expect(find.text('· vigente'), findsOneWidget);
    });

    testWidgets(
        'regresión: el monto usa spentMinor de la ventana del presupuesto, '
        'no el total del mes calendario cuando difieren (ej. presupuesto '
        'anclado el 27)', (tester) async {
      // `spending` mimics the current-calendar-month total the cubit always
      // computes as a fallback; `budgetProgress.spentMinor` is the featured
      // budget's own (differently-anchored) window total. They must not be
      // conflated — the hero's big amount is what is "spent" in the
      // budget's real period, not August's calendar total.
      final budgetProgress = buildHomeBudgetProgress(
        amountMinor: 600000,
        spentMinor: 150000,
      );
      await tester.pumpHomeWidget(
        hero(spendingWith(900000), budgetProgress: budgetProgress),
      );

      expect(find.textContaining('1.500'), findsOneWidget);
      expect(find.textContaining('9.000'), findsNothing);
    });

    testWidgets(
        'diseño xBv3N: muestra el kicker "Gastado" sobre el monto en vez '
        'de la leyenda "Gastado en <mes>"', (tester) async {
      final budgetProgress = buildHomeBudgetProgress();
      await tester.pumpHomeWidget(
        hero(spendingWith(300000), budgetProgress: budgetProgress),
      );

      expect(find.text('Gastado'), findsOneWidget);
      expect(find.text('Gastado en Julio'), findsNothing);
    });

    testWidgets(
        'diseño xBv3N: el stepper queda entre el monto y la barra de '
        'progreso', (tester) async {
      final budgetProgress = buildHomeBudgetProgress();
      await tester.pumpHomeWidget(
        hero(spendingWith(300000), budgetProgress: budgetProgress),
      );

      // Vertical order on screen (criterion 3): balance → stepper → budget
      // progress bar, never the old top/bottom placement.
      final amountY = tester.getTopLeft(find.textContaining('3.000').first).dy;
      final stepperY = tester.getTopLeft(find.byType(HeroPeriodStepper)).dy;
      final progressY =
          tester.getTopLeft(find.byType(HomeHeroBudgetProgress)).dy;

      expect(stepperY, greaterThan(amountY));
      expect(progressY, greaterThan(stepperY));
    });

    testWidgets(
        'criterio 4: los chevrons respetan hasPrevious/hasNext y navegan '
        'cuando están habilitados', (tester) async {
      var previousTapped = 0;
      var nextTapped = 0;
      // hasPrevious: false, hasNext: true (default fixture window).
      final budgetProgress = buildHomeBudgetProgress();
      await tester.pumpHomeWidget(
        hero(
          spendingWith(300000),
          budgetProgress: budgetProgress,
          onPreviousPeriod: () => previousTapped++,
          onNextPeriod: () => nextTapped++,
        ),
      );

      final chevrons = tester.widgetList<HeroPeriodChevron>(
        find.byType(HeroPeriodChevron),
      );
      expect(chevrons.length, 2);
      expect(chevrons.first.onPressed, isNull,
          reason: 'hasPrevious is false at the fixture window bounds');
      expect(chevrons.last.onPressed, isNotNull);

      await tester.tap(find.byType(HeroPeriodChevron).last);
      await tester.pump();
      expect(nextTapped, 1);
      expect(previousTapped, 0);
    });

    testWidgets(
        'regresión: tocar un chevron deshabilitado no dispara onOpenBudget '
        '(el tap no debe caer al InkWell del hero)', (tester) async {
      var openBudgetTapped = 0;
      var previousTapped = 0;
      // hasPrevious: false at the fixture window bounds, so the left
      // chevron renders disabled.
      final budgetProgress = buildHomeBudgetProgress();
      await tester.pumpHomeWidget(
        hero(
          spendingWith(300000),
          budgetProgress: budgetProgress,
          onOpenBudget: () => openBudgetTapped++,
          onPreviousPeriod: () => previousTapped++,
        ),
      );

      await tester.tap(find.byType(HeroPeriodChevron).first);
      await tester.pump();

      expect(previousTapped, 0);
      expect(openBudgetTapped, 0,
          reason: 'a disabled chevron must swallow the tap, not let it '
              "fall through to the card's own onOpenBudget");
    });

    testWidgets('criterio 6: tocar el hero dispara onOpenBudget',
        (tester) async {
      var tapped = 0;
      final budgetProgress = buildHomeBudgetProgress();
      await tester.pumpHomeWidget(
        hero(
          spendingWith(300000),
          budgetProgress: budgetProgress,
          onOpenBudget: () => tapped++,
        ),
      );

      await tester.tap(find.byType(HomeHeroCard));
      await tester.pump();

      expect(tapped, 1);
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
