import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_with_progress.dart';
import 'package:billetudo/features/goals/domain/services/goal_coherence_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Goal _buildGoal({required String id, String? accountId, bool archived = false}) => Goal(
      id: id,
      name: 'Meta $id',
      targetMinor: 500000,
      currency: 'COP',
      lastMilestonePct: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1).millisecondsSinceEpoch,
      accountId: accountId,
      archivedAt: archived ? DateTime(2026, 2, 1) : null,
    );

GoalWithProgress _withProgress({
  required String id,
  String? accountId,
  required int savedMinor,
}) =>
    GoalWithProgress(
      goal: _buildGoal(id: id, accountId: accountId),
      savedMinor: savedMinor,
      displayedPercent: 0,
      remainingMinor: 0,
    );

void main() {
  const calculator = GoalCoherenceCalculator();

  test('sin sobre-asignación no produce ninguna señal', () {
    final signals = calculator.calculate([
      GoalAccountFact(
        goal: _withProgress(id: 'g1', accountId: 'acc-1', savedMinor: 50000),
        accountBalanceMinor: 100000,
        accountCurrency: 'COP',
        accountName: 'Cuenta',
      ),
    ]);

    expect(signals, isEmpty);
  });

  test(
    'suma de savedMinor de varias metas de la misma cuenta que supera el '
    'saldo real produce una señal informativa',
    () {
      final signals = calculator.calculate([
        GoalAccountFact(
          goal: _withProgress(id: 'g1', accountId: 'acc-1', savedMinor: 70000),
          accountBalanceMinor: 100000,
          accountCurrency: 'COP',
          accountName: 'Cuenta',
        ),
        GoalAccountFact(
          goal: _withProgress(id: 'g2', accountId: 'acc-1', savedMinor: 50000),
          accountBalanceMinor: 100000,
          accountCurrency: 'COP',
          accountName: 'Cuenta',
        ),
      ]);

      final signal = signals['acc-1'];
      expect(signal, isNotNull);
      expect(signal!.totalSavedMinor, 120000);
      expect(signal.accountBalanceMinor, 100000);
      expect(signal.overshootMinor, 20000);
    },
  );

  test('cuentas distintas no se mezclan entre sí', () {
    final signals = calculator.calculate([
      GoalAccountFact(
        goal: _withProgress(id: 'g1', accountId: 'acc-1', savedMinor: 200000),
        accountBalanceMinor: 100000,
        accountCurrency: 'COP',
        accountName: 'Cuenta',
      ),
      GoalAccountFact(
        goal: _withProgress(id: 'g2', accountId: 'acc-2', savedMinor: 10000),
        accountBalanceMinor: 100000,
        accountCurrency: 'COP',
        accountName: 'Cuenta',
      ),
    ]);

    expect(signals.keys, ['acc-1']);
  });
}
