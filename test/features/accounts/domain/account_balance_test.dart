import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:flutter_test/flutter_test.dart';

import '../account_fixtures.dart';

void main() {
  group('AccountBalance.fromMovements (HU-04)', () {
    test('suma el saldo inicial y los cuatro signos de movimiento', () {
      final account = buildAccount(initialBalanceMinor: 100000); // $1.000,00

      final balance = AccountBalance.fromMovements(
        account: account,
        movements: const [
          AccountMovement(amountMinor: 50000, kind: MovementKind.income),
          AccountMovement(amountMinor: 20000, kind: MovementKind.expense),
          AccountMovement(amountMinor: 30000, kind: MovementKind.transferIn),
          AccountMovement(amountMinor: 10000, kind: MovementKind.transferOut),
        ],
      );

      // 100000 + 50000 - 20000 + 30000 - 10000
      expect(balance.balanceMinor, 150000);
    });

    test('ignora los movimientos con deletedAt (papelera)', () {
      final account = buildAccount(initialBalanceMinor: 100000);

      final balance = AccountBalance.fromMovements(
        account: account,
        movements: [
          const AccountMovement(amountMinor: 50000, kind: MovementKind.income),
          AccountMovement(
            amountMinor: 90000,
            kind: MovementKind.expense,
            deletedAt: DateTime(2026, 7, 15),
          ),
        ],
      );

      expect(balance.balanceMinor, 150000);
    });

    test('sin movimientos el saldo es el saldo inicial', () {
      final account = buildAccount(initialBalanceMinor: 4200);

      final balance = AccountBalance.fromMovements(
        account: account,
        movements: const [],
      );

      expect(balance.balanceMinor, 4200);
    });

    test('una cuenta normal no expone cupo disponible', () {
      final account = buildAccount(initialBalanceMinor: 4200);

      final balance = AccountBalance.fromMovements(
        account: account,
        movements: const [],
      );

      expect(balance.availableCreditMinor, isNull);
      expect(balance.overLimit, isFalse);
      expect(balance.excessMinor, 0);
    });
  });

  group('Cupo disponible de tarjeta (HU-02/HU-04)', () {
    test('cupo libre: disponible = cupo + saldo (saldo negativo = deuda)', () {
      final card = buildCard(creditLimitMinor: 500000); // cupo $5.000,00

      final balance = AccountBalance.fromMovements(
        account: card,
        movements: const [
          AccountMovement(amountMinor: 120000, kind: MovementKind.expense),
        ],
      );

      expect(balance.balanceMinor, -120000);
      expect(balance.debtMinor, 120000);
      expect(balance.availableCreditMinor, 380000);
      expect(balance.overLimit, isFalse);
      expect(balance.excessMinor, 0);
    });

    test('deuda igual al cupo: disponible 0 y todavía NO es sobrecupo', () {
      final card = buildCard(creditLimitMinor: 500000);

      final balance = AccountBalance.fromMovements(
        account: card,
        movements: const [
          AccountMovement(amountMinor: 500000, kind: MovementKind.expense),
        ],
      );

      expect(balance.availableCreditMinor, 0);
      expect(balance.overLimit, isFalse);
      expect(balance.excessMinor, 0);
    });

    test('sobrecupo: disponible se piso en 0 y excedente = |saldo| - cupo', () {
      final card = buildCard(creditLimitMinor: 500000);

      final balance = AccountBalance.fromMovements(
        account: card,
        movements: const [
          AccountMovement(amountMinor: 620000, kind: MovementKind.expense),
        ],
      );

      expect(balance.balanceMinor, -620000);
      expect(balance.debtMinor, 620000);
      // Nunca negativo: el diseño muestra 0, no "-$1.200".
      expect(balance.availableCreditMinor, 0);
      expect(balance.overLimit, isTrue);
      expect(balance.excessMinor, 120000);
    });

    test('un pago (transferencia entrante) libera cupo', () {
      final card = buildCard(creditLimitMinor: 500000);

      final balance = AccountBalance.fromMovements(
        account: card,
        movements: const [
          AccountMovement(amountMinor: 300000, kind: MovementKind.expense),
          AccountMovement(amountMinor: 100000, kind: MovementKind.transferIn),
        ],
      );

      expect(balance.balanceMinor, -200000);
      expect(balance.availableCreditMinor, 300000);
    });

    test('una compra eliminada no consume cupo', () {
      final card = buildCard(creditLimitMinor: 500000);

      final balance = AccountBalance.fromMovements(
        account: card,
        movements: [
          const AccountMovement(
            amountMinor: 100000,
            kind: MovementKind.expense,
          ),
          AccountMovement(
            amountMinor: 400000,
            kind: MovementKind.expense,
            deletedAt: DateTime(2026, 7, 15),
          ),
        ],
      );

      expect(balance.availableCreditMinor, 400000);
      expect(balance.overLimit, isFalse);
    });

    test('una tarjeta sin cupo registrado no expone cupo disponible', () {
      // Solo puede ocurrir con datos previos a HU-02: la validación exige cupo.
      final card = buildAccount(type: AccountType.card);

      final balance = AccountBalance.fromMovements(
        account: card,
        movements: const [],
      );

      expect(balance.availableCreditMinor, isNull);
    });
  });
}
