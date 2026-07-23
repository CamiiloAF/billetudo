import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:flutter_test/flutter_test.dart';

/// [Debt.effectiveStartDate] is the floor every backdated event (abono,
/// reconciliation, linked movement) is clamped to, so its fallback matters.
void main() {
  Debt debt({DateTime? startDate, DateTime? createdAt}) => Debt(
        id: 'd1',
        name: 'Crédito',
        direction: DebtDirection.iOwe,
        principalMinor: 0,
        currency: 'COP',
        accrualMode: DebtAccrualMode.manual,
        startDate: startDate,
        createdAt: createdAt ?? DateTime(2026, 1, 1),
        updatedAt: 0,
      );

  test('effectiveStartDate uses startDate when set', () {
    final start = DateTime(2025, 6, 15);
    expect(debt(startDate: start).effectiveStartDate, start);
  });

  test('effectiveStartDate falls back to createdAt when startDate is null', () {
    final created = DateTime(2026, 3, 20);
    expect(
      debt(startDate: null, createdAt: created).effectiveStartDate,
      created,
    );
  });
}
