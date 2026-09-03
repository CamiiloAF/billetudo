import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/home/domain/entities/hero_state.dart';
import 'package:billetudo/features/home/domain/entities/month_spending.dart';
import 'package:billetudo/features/home/presentation/widgets/home_hero_budget_progress.dart';
import 'package:billetudo/features/home/presentation/widgets/home_hero_card.dart';
import 'package:billetudo/features/home/presentation/widgets/month_selector_chip.dart';
import 'package:billetudo/features/home/presentation/widgets/risk_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    HomeHeroState heroState = HomeHeroState.noBudgetEverCreated,
    VoidCallback? onCreateBudget,
    VoidCallback? onOpenBudget,
    VoidCallback? onPreviousPeriod,
    VoidCallback? onNextPeriod,
    VoidCallback? onOpenMonthPicker,
    BudgetWithProgress? budgetProgress,
  }) =>
      HomeHeroCard(
        heroState: heroState,
        spending: spending,
        monthLabel: 'Julio',
        onCreateBudget: onCreateBudget ?? () {},
        onOpenBudget: onOpenBudget,
        onPreviousPeriod: onPreviousPeriod,
        onNextPeriod: onNextPeriod,
        onOpenMonthPicker: onOpenMonthPicker,
        budgetProgress: budgetProgress,
      );

  group('sin presupuesto destacado (7 estados, xRSdl)', () {
    testWidgets(
        'nunca creó uno: muestra "Gastado en <mes>", el monto y la nota '
        '"Sin presupuesto activo este mes"', (tester) async {
      await tester.pumpHomeWidget(
        hero(
          spendingWith(126900),
          onOpenMonthPicker: () {},
        ),
      );

      expect(find.text('Gastado en Julio'), findsOneWidget);
      // 126900 cents => 1.269 COP (COP shows no decimals), from an int.
      expect(find.textContaining('1.269'), findsOneWidget);
      expect(find.text('Sin presupuesto activo este mes'), findsOneWidget);
      // Criterion 5: no period pill without a featured budget — the
      // calendar-month chip takes its spot instead.
      expect(find.byType(PeriodPill), findsNothing);
      expect(find.byType(MonthSelectorChip), findsOneWidget);
    });

    testWidgets(
        'con presupuestos pero ninguno destacado: misma capa, nota distinta',
        (tester) async {
      await tester.pumpHomeWidget(
        hero(
          spendingWith(126900),
          heroState: HomeHeroState.noBudgetFeatured,
        ),
      );

      expect(
          find.text('Ningún presupuesto destacado este mes'), findsOneWidget);
      expect(find.text('Sin presupuesto activo este mes'), findsNothing);
    });

    testWidgets('tocar el MonthSelectorChip dispara onOpenMonthPicker',
        (tester) async {
      var tapped = 0;
      await tester.pumpHomeWidget(
        hero(spendingWith(126900), onOpenMonthPicker: () => tapped++),
      );

      await tester.tap(find.byType(MonthSelectorChip));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('sin onOpenMonthPicker: no renderiza el chip (nada que tocar)',
        (tester) async {
      await tester.pumpHomeWidget(hero(spendingWith(126900)));

      expect(find.byType(MonthSelectorChip), findsNothing);
    });

    testWidgets('tocar la nota dispara onCreateBudget', (tester) async {
      var tapped = 0;
      await tester.pumpHomeWidget(
        hero(spendingWith(50000), onCreateBudget: () => tapped++),
      );

      await tester.tap(find.text('Sin presupuesto activo este mes'));
      await tester.pump();

      expect(tapped, 1);
    });
  });

  group('con presupuesto destacado (HU-03/HU-05)', () {
    testWidgets('sano: kicker fijo "Te quedan" y barra de un tramo',
        (tester) async {
      final budgetProgress = buildHomeBudgetProgress(
        amountMinor: 600000,
        spentMinor: 300000,
        daysLeft: 12,
      );
      await tester.pumpHomeWidget(
        hero(
          spendingWith(300000),
          heroState: HomeHeroState.healthy,
          budgetProgress: budgetProgress,
        ),
      );

      expect(find.byType(HomeHeroBudgetProgress), findsOneWidget);
      expect(find.text('Te quedan'), findsOneWidget);
      // remainingMinor = 300000 => $3.000.
      expect(find.textContaining('3.000'), findsOneWidget);
      // Criterio 7: 30px/800 fuera de sobregasto real, monto corto.
      final amount = tester.widget<Text>(find.textContaining('3.000'));
      expect(amount.style?.fontSize, 30);
      expect(amount.style?.fontWeight, FontWeight.w800);
    });

    testWidgets('sobregasto real: kicker "Excedido por", nunca "Te quedan"',
        (tester) async {
      final budgetProgress = buildHomeBudgetProgress(
        amountMinor: 600000,
        spentMinor: 700000,
      );
      await tester.pumpHomeWidget(
        hero(
          spendingWith(700000),
          heroState: HomeHeroState.overspent,
          budgetProgress: budgetProgress,
        ),
      );

      expect(find.text('Excedido por'), findsOneWidget);
      expect(find.text('Te quedan'), findsNothing);
      // remainingMinor = -100000, overage displayed = $1.000.
      expect(find.textContaining('1.000'), findsOneWidget);
      // Criterio 7: 32px/800 solo en sobregasto real, con circle-minus.
      final amount = tester.widget<Text>(find.textContaining('1.000'));
      expect(amount.style?.fontSize, 32);
      expect(amount.style?.fontWeight, FontWeight.w800);
      expect(find.byIcon(LucideIcons.circleMinus), findsOneWidget);
    });

    testWidgets(
        'criterio 7: un monto de más de ~10 glifos reduce a 26px/800 en vez '
        'de desbordar el track', (tester) async {
      final budgetProgress = buildHomeBudgetProgress(
        amountMinor: 6000000000,
        spentMinor: 3000000000,
        daysLeft: 12,
      );
      await tester.pumpHomeWidget(
        hero(
          spendingWith(3000000000),
          heroState: HomeHeroState.healthy,
          budgetProgress: budgetProgress,
        ),
      );

      // remainingMinor = 3000000000 => $30.000.000 (11 glyphs with the peso
      // sign: "$30.000.000").
      final amount = tester.widget<Text>(find.textContaining('30.000.000'));
      expect(amount.style?.fontSize, 26);
    });

    testWidgets(
        'riesgo de sobregiro proyectado: mantiene "Te quedan" y agrega '
        'RiskNote sin reemplazar el kicker/monto', (tester) async {
      final budgetProgress = BudgetWithProgress(
        budget: buildHomeBudgetProgress().budget,
        scope: buildHomeBudgetProgress().scope,
        window: buildHomeBudgetProgress().window,
        progress: const BudgetProgressFixture(
          amountMinor: 600000,
          spentMinor: 300000,
          scheduledMinor: 400000,
        ),
      );
      await tester.pumpHomeWidget(
        hero(
          spendingWith(300000),
          heroState: HomeHeroState.scheduledOverspendRisk,
          budgetProgress: budgetProgress,
        ),
      );

      expect(find.text('Te quedan'), findsOneWidget);
      expect(find.byType(RiskNote), findsOneWidget);
    });

    testWidgets(
        'nunca renderiza el MonthSelectorChip, aunque se le pase '
        'onOpenMonthPicker — el Period Pill toma su lugar', (tester) async {
      final budgetProgress = buildHomeBudgetProgress();
      await tester.pumpHomeWidget(
        hero(
          spendingWith(300000),
          heroState: HomeHeroState.healthy,
          budgetProgress: budgetProgress,
          onOpenMonthPicker: () {},
        ),
      );

      expect(find.byType(MonthSelectorChip), findsNothing);
      expect(find.byType(PeriodPill), findsOneWidget);
    });

    testWidgets(
        'criterio 9: el Period Pill muestra la ventana real del presupuesto, '
        'nunca un nombre de mes calendario', (tester) async {
      final budgetProgress = buildHomeBudgetProgress();
      await tester.pumpHomeWidget(
        hero(
          spendingWith(300000),
          heroState: HomeHeroState.healthy,
          budgetProgress: budgetProgress,
        ),
      );

      // The fixture's window is `[2026-07-01, 2026-08-01)`, so its real
      // range is "1–31 jul" — never "Julio" (the calendar-month label).
      expect(find.text('1–31 jul'), findsOneWidget);
      expect(find.text('Gastado en Julio'), findsNothing);
      expect(find.byType(PeriodPill), findsOneWidget);
    });

    testWidgets(
        'discoverability: muestra el nombre del presupuesto destacado en la '
        'fila superior', (tester) async {
      final budgetProgress = buildHomeBudgetProgress(name: 'Mercado del mes');
      await tester.pumpHomeWidget(
        hero(
          spendingWith(300000),
          heroState: HomeHeroState.healthy,
          budgetProgress: budgetProgress,
        ),
      );

      expect(find.text('Mercado del mes'), findsOneWidget);
    });

    testWidgets(
        'criterio 9: los chevrons respetan hasPrevious/hasNext y navegan '
        'cuando están habilitados', (tester) async {
      var previousTapped = 0;
      var nextTapped = 0;
      // hasPrevious: false, hasNext: true (default fixture window).
      final budgetProgress = buildHomeBudgetProgress();
      await tester.pumpHomeWidget(
        hero(
          spendingWith(300000),
          heroState: HomeHeroState.healthy,
          budgetProgress: budgetProgress,
          onPreviousPeriod: () => previousTapped++,
          onNextPeriod: () => nextTapped++,
        ),
      );

      final chevrons = tester.widgetList<PillChevron>(find.byType(PillChevron));
      expect(chevrons.length, 2);
      expect(chevrons.first.onPressed, isNull,
          reason: 'hasPrevious is false at the fixture window bounds');
      expect(chevrons.last.onPressed, isNotNull);

      await tester.tap(find.byType(PillChevron).last);
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
          heroState: HomeHeroState.healthy,
          budgetProgress: budgetProgress,
          onOpenBudget: () => openBudgetTapped++,
          onPreviousPeriod: () => previousTapped++,
        ),
      );

      await tester.tap(find.byType(PillChevron).first);
      await tester.pump();

      expect(previousTapped, 0);
      expect(openBudgetTapped, 0,
          reason: 'a disabled chevron must swallow the tap, not let it '
              "fall through to the card's own onOpenBudget");
    });

    testWidgets(
        'criterio 9: tocar el rango de fechas del Period Pill no dispara '
        'onOpenBudget (absorbe el gesto)', (tester) async {
      var openBudgetTapped = 0;
      final budgetProgress = buildHomeBudgetProgress();
      await tester.pumpHomeWidget(
        hero(
          spendingWith(300000),
          heroState: HomeHeroState.healthy,
          budgetProgress: budgetProgress,
          onOpenBudget: () => openBudgetTapped++,
        ),
      );

      await tester.tap(find.text('1–31 jul'));
      await tester.pump();

      expect(openBudgetTapped, 0);
    });

    testWidgets('criterio 6: tocar el hero dispara onOpenBudget',
        (tester) async {
      var tapped = 0;
      final budgetProgress = buildHomeBudgetProgress();
      await tester.pumpHomeWidget(
        hero(
          spendingWith(300000),
          heroState: HomeHeroState.healthy,
          budgetProgress: budgetProgress,
          onOpenBudget: () => tapped++,
        ),
      );

      await tester.tap(find.byType(HomeHeroCard));
      await tester.pump();

      expect(tapped, 1);
    });
  });
}

/// A [BudgetProgress] fixture with an explicit `scheduledMinor`, since
/// `buildHomeBudgetProgress` (the shared fixture) does not expose one.
class BudgetProgressFixture extends BudgetProgress {
  const BudgetProgressFixture({
    required super.amountMinor,
    required super.spentMinor,
    super.scheduledMinor,
    super.daysLeft = 12,
  });
}
