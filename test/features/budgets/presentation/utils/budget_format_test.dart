import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/presentation/utils/budget_format.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../domain/budget_fixtures.dart';
import '../golden/budget_golden_fixtures.dart';

/// The detail's two texts that read differently for a one-off budget
/// (`QLn6w`): the period stepper's label and the hero's right caption.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
    await initializeDateFormatting('en');
    l10n = await AppLocalizations.delegate.load(const Locale('es'));
  });

  group('longDate is locale-aware (no fixed es_CO)', () {
    final date = DateTime(2026, 7, 21);

    test('English spells the month in English, not Spanish', () {
      expect(BudgetFormat.longDate(date, 'en'), 'July 21, 2026');
    });

    test('Spanish keeps its own long form', () {
      expect(BudgetFormat.longDate(date, 'es_CO'), '21 de julio de 2026');
    });
  });

  final recurring = buildBudget(
    id: 'bud-recurrente',
    name: 'Mercado',
    startDate: DateTime(2025, 7),
  );
  final oneOff = buildBudget(
    id: 'bud-unica-vez',
    name: 'Regalos de navidad',
    period: BudgetPeriod.custom,
    recurring: false,
    startDate: DateTime(2025, 12),
    endDate: DateTime(2025, 12, 24),
  );
  final window = buildWindow(
    start: DateTime(2025, 12),
    endExclusive: DateTime(2025, 12, 25),
  );

  group('stepper label', () {
    test('a recurring budget names the cycle range and its status', () {
      expect(BudgetFormat.stepperRange(l10n, recurring, window, 'es_CO'),
          '1–24 dic');
      expect(BudgetFormat.stepperState(l10n, recurring, window, 'es_CO'),
          '· vigente');
    });

    test('a one-off names its single window and when it ends', () {
      expect(BudgetFormat.stepperRange(l10n, oneOff, window, 'es_CO'),
          'Ventana única');
      expect(
        BudgetFormat.stepperState(l10n, oneOff, window, 'es_CO'),
        '· termina el 24 dic',
      );
    });
  });

  group('days left caption', () {
    const progress = BudgetProgress(
      amountMinor: 35000000,
      spentMinor: 17000000,
      daysLeft: 8,
    );

    test('a recurring budget counts down to the reset', () {
      expect(
        BudgetFormat.daysLeftCaption(l10n, recurring, window, progress),
        'Restan 8 días',
      );
    });

    test('a one-off counts down to the end of its window', () {
      expect(
        BudgetFormat.daysLeftCaption(l10n, oneOff, window, progress),
        'Termina en 8 días',
      );
    });

    test('a closed period announces no days left at all', () {
      final past = buildWindow(
        start: DateTime(2025, 11),
        endExclusive: DateTime(2025, 12),
        status: BudgetWindowStatus.past,
      );
      expect(
        BudgetFormat.daysLeftCaption(l10n, recurring, past, progress),
        isNull,
      );
      expect(
        BudgetFormat.daysLeftCaption(l10n, oneOff, past, progress),
        isNull,
      );
    });
  });

  // `MoneyFormatter` always divides `amountMinor` by 100 regardless of
  // currency (COP just shows 0 decimals) — these mirror the exact pesos
  // `H4HDen`/`EZeos` show ($600.000 budget, $492.000/$420.000 spent,
  // $60.000/$270.000 programado, $90.000 overage), so `amountMinor` here is
  // that peso figure ×100, not the peso figure itself.
  group('scheduledCaption (HU-12)', () {
    test('is null when nothing is scheduled in the window', () {
      const progress = BudgetProgress(
        amountMinor: 60000000,
        spentMinor: 49200000,
        daysLeft: 18,
      );
      expect(BudgetFormat.scheduledCaption(l10n, progress, 'COP'), isNull);
    });

    test('sano: names the amount and the projected percentage', () {
      const progress = BudgetProgress(
        amountMinor: 60000000,
        spentMinor: 49200000,
        scheduledMinor: 6000000,
        daysLeft: 18,
      );
      expect(
        BudgetFormat.scheduledCaption(l10n, progress, 'COP'),
        '+ \$60.000 programado (llega a 92% si se ejecuta)',
      );
    });

    test(
        'riesgo: names the amount and the projected overage, always in '
        'the conditional tense', () {
      const progress = BudgetProgress(
        amountMinor: 60000000,
        spentMinor: 42000000,
        scheduledMinor: 27000000,
        daysLeft: 18,
      );
      expect(
        BudgetFormat.scheduledCaption(l10n, progress, 'COP'),
        '+ \$270.000 programado — excedería el presupuesto por \$90.000',
      );
    });
  });

  group('freeAfterScheduledCaption (item 10)', () {
    test('is null when nothing is scheduled', () {
      const progress = BudgetProgress(
        amountMinor: 60000000,
        spentMinor: 49200000,
        daysLeft: 18,
      );
      expect(
        BudgetFormat.freeAfterScheduledCaption(l10n, progress, 'COP'),
        isNull,
      );
    });

    test('positivo: names what would stay free (restante − programado)', () {
      const progress = BudgetProgress(
        amountMinor: 60000000,
        spentMinor: 49200000,
        scheduledMinor: 6000000,
        daysLeft: 18,
      );
      // remaining = 10.800.000; free = 10.800.000 − 6.000.000 = 4.800.000.
      expect(
        BudgetFormat.freeAfterScheduledCaption(l10n, progress, 'COP'),
        '\$48.000 quedarían libres si apruebas los programados',
      );
    });

    test('is null on overspend risk: that case owns the "excedería" line', () {
      const progress = BudgetProgress(
        amountMinor: 60000000,
        spentMinor: 42000000,
        scheduledMinor: 27000000,
        daysLeft: 18,
      );
      // spent + scheduled = 69.000.000 > 60.000.000 → free is negative, so the
      // "libre" caption never shows; scheduledCaption's risk line does instead.
      expect(progress.isScheduledOverspendRisk, isTrue);
      expect(
        BudgetFormat.freeAfterScheduledCaption(l10n, progress, 'COP'),
        isNull,
      );
    });

    test('exactly at the limit still counts as free (zero)', () {
      const progress = BudgetProgress(
        amountMinor: 60000000,
        spentMinor: 40000000,
        scheduledMinor: 20000000,
        daysLeft: 18,
      );
      expect(
        BudgetFormat.freeAfterScheduledCaption(l10n, progress, 'COP'),
        '\$0 quedarían libres si apruebas los programados',
      );
    });
  });

  group('scheduledEntrySub (HU-12)', () {
    test('sano: reports the upcoming payment count', () {
      const progress = BudgetProgress(
        amountMinor: 60000000,
        spentMinor: 49200000,
        scheduledMinor: 6000000,
        daysLeft: 18,
      );
      expect(
        BudgetFormat.scheduledEntrySub(l10n, progress, 'COP', 2),
        '2 pagos próximos',
      );
    });

    test('riesgo: the overage takes over the plain count', () {
      const progress = BudgetProgress(
        amountMinor: 60000000,
        spentMinor: 42000000,
        scheduledMinor: 27000000,
        daysLeft: 18,
      );
      expect(
        BudgetFormat.scheduledEntrySub(l10n, progress, 'COP', 2),
        'Excedería el presupuesto por \$90.000',
      );
    });
  });
}
