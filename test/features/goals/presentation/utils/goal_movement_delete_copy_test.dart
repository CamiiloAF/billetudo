import 'package:billetudo/core/l10n/gen/app_localizations_es.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/entities/goal_movement_accounts.dart';
import 'package:billetudo/features/goals/presentation/utils/goal_movement_delete_copy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../goals_presentation_fixtures.dart';

/// The exact three copy variants of the "Eliminar movimiento" sheets
/// (`arr2T`/`H2ND7O`/`xCNxM`), matched against `billetudo.pen`'s content.
void main() {
  final l10n = AppLocalizationsEs();

  test('con transferencia, meta en curso (arr2T)', () {
    final copy = GoalMovementDeleteCopy.build(
      l10n,
      movement: buildGoalContribution(
        amountMinor: 30000000,
        transactionId: 'tx-1',
      ),
      currency: 'COP',
      goalName: 'Viaje a Cartagena',
      goalCompleted: false,
      accounts: const GoalMovementAccounts(
        originName: 'Nequi',
        destinationName: 'Ahorros Bancolombia',
      ),
    );

    expect(copy.title, '¿Eliminar este aporte de \$300.000?');
    expect(
      copy.message,
      'El avance de la meta se recalcula sin él. Como este movimiento '
      'tiene una transferencia detrás, esa transferencia también se '
      'elimina y los saldos de Nequi y Ahorros Bancolombia vuelven a '
      'como estaban.',
    );
  });

  test('registro manual, meta en curso (H2ND7O)', () {
    final copy = GoalMovementDeleteCopy.build(
      l10n,
      movement: buildGoalContribution(amountMinor: 11000000),
      currency: 'COP',
      goalName: 'Viaje a Cartagena',
      goalCompleted: false,
    );

    expect(copy.title, '¿Eliminar este aporte de \$110.000?');
    expect(
      copy.message,
      'El avance de la meta se recalcula sin él. Este aporte fue un '
      'registro manual, así que ninguna de tus cuentas cambia de saldo.',
    );
  });

  test('con transferencia, meta cumplida (xCNxM)', () {
    final copy = GoalMovementDeleteCopy.build(
      l10n,
      movement: buildGoalContribution(
        amountMinor: 30000000,
        transactionId: 'tx-1',
      ),
      currency: 'COP',
      goalName: 'Viaje a Cartagena',
      goalCompleted: true,
      accounts: const GoalMovementAccounts(
        originName: 'Nequi',
        destinationName: 'Ahorros Bancolombia',
      ),
    );

    expect(copy.title, '¿Eliminar este aporte de \$300.000?');
    expect(
      copy.message,
      'Este aporte hace parte de lo que completó Viaje a Cartagena: al '
      'eliminarlo, la meta vuelve a estar en curso hasta que la '
      'completes de nuevo. La transferencia detrás también se elimina '
      'y los saldos de Nequi y Ahorros Bancolombia vuelven a como '
      'estaban.',
    );
  });

  test('un retiro usa el sustantivo "retiro" en vez de "aporte"', () {
    final copy = GoalMovementDeleteCopy.build(
      l10n,
      movement: buildGoalContribution(
        amountMinor: 5000000,
        direction: GoalMovementDirection.withdrawal,
      ),
      currency: 'COP',
      goalName: 'Viaje a Cartagena',
      goalCompleted: false,
    );

    expect(copy.title, '¿Eliminar este retiro de \$50.000?');
  });

  test(
    'sin accounts resueltos aun con transactionId, cae al copy manual',
    () {
      final copy = GoalMovementDeleteCopy.build(
        l10n,
        movement: buildGoalContribution(
          amountMinor: 5000000,
          transactionId: 'tx-1',
        ),
        currency: 'COP',
        goalName: 'Viaje a Cartagena',
        goalCompleted: false,
      );

      expect(
        copy.message,
        'El avance de la meta se recalcula sin él. Este aporte fue un '
        'registro manual, así que ninguna de tus cuentas cambia de saldo.',
      );
    },
  );
}
