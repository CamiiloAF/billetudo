import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BudgetDraft draft({
    String name = 'Mercado',
    int amountMinor = 100,
    String currency = 'COP',
    BudgetPeriod period = BudgetPeriod.monthly,
    bool recurring = true,
    DateTime? startDate,
    DateTime? endDate,
    int? alertThresholdPct = 80,
  }) =>
      BudgetDraft(
        name: name,
        amountMinor: amountMinor,
        currency: currency,
        period: period,
        startDate: startDate ?? DateTime(2024, 1, 15),
        recurring: recurring,
        endDate: endDate,
        alertThresholdPct: alertThresholdPct,
      );

  Failure? failureOf(BudgetDraft d) => d.validated().fold((f) => f, (_) => null);

  group('BudgetDraft.validated (HU-01/HU-03)', () {
    test('rejects a blank name', () {
      expect(failureOf(draft(name: '   ')), isA<ValidationFailure>());
    });

    test('rejects a non-positive amount', () {
      expect(failureOf(draft(amountMinor: 0)), isA<ValidationFailure>());
    });

    test('rejects a threshold out of 1..100', () {
      expect(failureOf(draft(alertThresholdPct: 0)), isA<ValidationFailure>());
      expect(failureOf(draft(alertThresholdPct: 101)), isA<ValidationFailure>());
    });

    test('a one-off requires an end date after the start', () {
      expect(
        failureOf(draft(recurring: false, period: BudgetPeriod.custom)),
        isA<ValidationFailure>(),
      );
      expect(
        failureOf(
          draft(
            recurring: false,
            period: BudgetPeriod.custom,
            startDate: DateTime(2024, 1, 15),
            endDate: DateTime(2024, 1, 10),
          ),
        ),
        isA<ValidationFailure>(),
      );
    });

    test('normalizes a one-off to custom/non-recurring and trims the name', () {
      final result = draft(
        name: '  Viaje  ',
        recurring: false,
        period: BudgetPeriod.custom,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      ).validated();

      final normalized = result.getRight().toNullable()!;
      expect(normalized.name, 'Viaje');
      expect(normalized.recurring, isFalse);
      expect(normalized.period, BudgetPeriod.custom);
    });

    test('a periodic budget may run forever (null end date)', () {
      final result = draft().validated();
      expect(result.isRight(), isTrue);
    });
  });
}
