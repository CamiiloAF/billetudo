import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance_adjustment.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../account_fixtures.dart';

void main() {
  group('cuenta no-tarjeta (saldo con signo directo)', () {
    test('subir el saldo produce una diferencia positiva (ingreso)', () {
      final adjustment = AccountBalanceAdjustment.from(
        account: buildAccount(initialBalanceMinor: 500000),
        currentBalanceMinor: 218000000,
        newDisplayedBalanceMinor: 250000000,
      );

      expect(adjustment.diffMinor, 32000000);
      expect(adjustment.isIncome, isTrue);
      expect(adjustment.hasChange, isTrue);
      // El saldo inicial se corre exactamente por la diferencia.
      expect(adjustment.newInitialBalanceMinor, 500000 + 32000000);
    });

    test('bajar el saldo produce una diferencia negativa (gasto)', () {
      final adjustment = AccountBalanceAdjustment.from(
        account: buildAccount(initialBalanceMinor: 500000),
        currentBalanceMinor: 218000000,
        newDisplayedBalanceMinor: 200000000,
      );

      expect(adjustment.diffMinor, -18000000);
      expect(adjustment.isIncome, isFalse);
      expect(adjustment.newInitialBalanceMinor, 500000 - 18000000);
    });

    test('igual al saldo actual no es cambio', () {
      final adjustment = AccountBalanceAdjustment.from(
        account: buildAccount(),
        currentBalanceMinor: 218000000,
        newDisplayedBalanceMinor: 218000000,
      );

      expect(adjustment.hasChange, isFalse);
      expect(adjustment.diffMinor, 0);
    });

    test('acepta un saldo objetivo negativo (sobregiro)', () {
      final adjustment = AccountBalanceAdjustment.from(
        account: buildAccount(initialBalanceMinor: 0),
        currentBalanceMinor: 100000,
        newDisplayedBalanceMinor: -50000,
      );

      expect(adjustment.newBalanceMinor, -50000);
      expect(adjustment.diffMinor, -150000);
      expect(adjustment.isIncome, isFalse);
    });
  });

  group('tarjeta (la cifra visible es la deuda, saldo real negativo)', () {
    // Deuda actual $1.000 -> saldo real -100000.
    Account card() => buildCard(
          creditLimitMinor: 300000000,
          initialBalanceMinor: -100000,
        );

    test('subir la deuda es un gasto (saldo real más negativo)', () {
      final adjustment = AccountBalanceAdjustment.from(
        account: card(),
        currentBalanceMinor: -100000,
        newDisplayedBalanceMinor: 150000,
      );

      // Deuda $1.500 -> saldo real -150000.
      expect(adjustment.newBalanceMinor, -150000);
      expect(adjustment.diffMinor, -50000);
      expect(adjustment.isIncome, isFalse);
      expect(adjustment.newInitialBalanceMinor, -100000 - 50000);
    });

    test('bajar la deuda es un ingreso (se paga: saldo real sube)', () {
      final adjustment = AccountBalanceAdjustment.from(
        account: card(),
        currentBalanceMinor: -100000,
        newDisplayedBalanceMinor: 50000,
      );

      expect(adjustment.newBalanceMinor, -50000);
      expect(adjustment.diffMinor, 50000);
      expect(adjustment.isIncome, isTrue);
      expect(adjustment.newInitialBalanceMinor, -100000 + 50000);
    });

    test('una deuda tecleada negativa se normaliza a deuda positiva', () {
      final adjustment = AccountBalanceAdjustment.from(
        account: card(),
        currentBalanceMinor: -100000,
        newDisplayedBalanceMinor: -150000,
      );

      // El signo del campo no confunde: deuda 150000 -> saldo real -150000.
      expect(adjustment.newBalanceMinor, -150000);
    });
  });
}
