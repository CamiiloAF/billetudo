import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/features/accounts/data/models/account_mapper.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 7, 1, 8);
  final updatedAt = DateTime(2026, 7, 15, 10, 30);

  db.Account buildRow({
    String id = 'acc-1',
    String name = 'Bancolombia',
    db.AccountType type = db.AccountType.bank,
    String currency = 'COP',
    int initialBalanceMinor = 100000,
    bool archived = false,
    int sortOrder = 0,
    String? institution,
    String? accountNumberEnc,
    String? last4,
    int? interestRateBps,
    int? creditLimitMinor,
    int? statementDay,
    int? paymentDueDay,
    db.CardBalanceView? cardBalancePrimary,
  }) =>
      db.Account(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        name: name,
        type: type,
        currency: currency,
        initialBalanceMinor: initialBalanceMinor,
        archived: archived,
        sortOrder: sortOrder,
        institution: institution,
        accountNumberEnc: accountNumberEnc,
        last4: last4,
        interestRateBps: interestRateBps,
        creditLimitMinor: creditLimitMinor,
        statementDay: statementDay,
        paymentDueDay: paymentDueDay,
        cardBalancePrimary: cardBalancePrimary,
      );

  // `accountId` and `type` are required: every test here is *about* them, so a
  // default would hide the subject under test.
  db.Transaction buildTransactionRow({
    required String accountId,
    required db.EntryType type,
    String id = 'tx-1',
    int amountMinor = 1000,
    String? transferAccountId,
    DateTime? deletedAt,
  }) =>
      db.Transaction(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
        accountId: accountId,
        amountMinor: amountMinor,
        currency: 'COP',
        type: type,
        date: createdAt,
        source: db.TxSource.manual,
        transferAccountId: transferAccountId,
      );

  group('toEntity', () {
    test('mapea todos los campos de la fila a la entidad', () {
      final account = AccountMapper.toEntity(
        buildRow(
          institution: 'Bancolombia',
          last4: '4321',
          interestRateBps: 2450,
        ),
      );

      expect(account.id, 'acc-1');
      expect(account.name, 'Bancolombia');
      expect(account.type, AccountType.bank);
      expect(account.currency, 'COP');
      expect(account.initialBalanceMinor, 100000);
      expect(account.archived, isFalse);
      expect(account.sortOrder, 0);
      expect(account.createdAt, createdAt);
      expect(account.updatedAt, updatedAt);
      expect(account.institution, 'Bancolombia');
      expect(account.last4, '4321');
      expect(account.interestRateBps, 2450);
    });

    test('mapea los enums textuales de tipo en ambos sentidos', () {
      const pairs = <db.AccountType, AccountType>{
        db.AccountType.cash: AccountType.cash,
        db.AccountType.bank: AccountType.bank,
        db.AccountType.card: AccountType.card,
        db.AccountType.savings: AccountType.savings,
        db.AccountType.investment: AccountType.investment,
        db.AccountType.other: AccountType.other,
      };

      for (final entry in pairs.entries) {
        expect(
          AccountMapper.toEntity(buildRow(type: entry.key)).type,
          entry.value,
        );
      }
      // Paridad de nombres: es lo que se guarda como texto en SQLite/Postgres.
      for (final entry in pairs.entries) {
        expect(entry.key.name, entry.value.name);
      }
    });

    test('mapea el enum de preferencia de tarjeta', () {
      expect(
        AccountMapper.toEntity(
          buildRow(cardBalancePrimary: db.CardBalanceView.debt),
        ).cardBalancePrimary,
        CardBalanceView.debt,
      );
      expect(
        AccountMapper.toEntity(
          buildRow(cardBalancePrimary: db.CardBalanceView.available),
        ).cardBalancePrimary,
        CardBalanceView.available,
      );
      expect(AccountMapper.toEntity(buildRow()).cardBalancePrimary, isNull);
    });

    test('el número cifrado de la fila NUNCA llega a la entidad', () {
      // Defensa en profundidad: aunque una fila vieja o un sync trajera algo en
      // accountNumberEnc, la entidad no tiene dónde ponerlo.
      final account = AccountMapper.toEntity(
        buildRow(accountNumberEnc: 'lo-que-sea', last4: '4321'),
      );

      expect(account.last4, '4321');
      expect(account.props, isNot(contains('lo-que-sea')));
    });

    test('mapea los campos de tarjeta', () {
      final card = AccountMapper.toEntity(
        buildRow(
          type: db.AccountType.card,
          creditLimitMinor: 500000,
          statementDay: 15,
          paymentDueDay: 5,
        ),
      );

      expect(card.isCard, isTrue);
      expect(card.creditLimitMinor, 500000);
      expect(card.statementDay, 15);
      expect(card.paymentDueDay, 5);
    });
  });

  group('toMovement', () {
    test('un ingreso es un movimiento positivo', () {
      final movement = AccountMapper.toMovement(
        buildTransactionRow(
          accountId: 'acc-1',
          type: db.EntryType.income,
          amountMinor: 5000,
        ),
        'acc-1',
      );

      expect(movement.kind, MovementKind.income);
      expect(movement.signedMinor, 5000);
    });

    test('un gasto es un movimiento negativo', () {
      final movement = AccountMapper.toMovement(
        buildTransactionRow(
          accountId: 'acc-1',
          type: db.EntryType.expense,
          amountMinor: 5000,
        ),
        'acc-1',
      );

      expect(movement.kind, MovementKind.expense);
      expect(movement.signedMinor, -5000);
    });

    test('una transferencia sale de la cuenta origen', () {
      final movement = AccountMapper.toMovement(
        buildTransactionRow(
          type: db.EntryType.transfer,
          accountId: 'acc-1',
          transferAccountId: 'acc-2',
        ),
        'acc-1',
      );

      expect(movement.kind, MovementKind.transferOut);
      expect(movement.signedMinor, -1000);
    });

    test('la MISMA transferencia entra a la cuenta destino', () {
      final row = buildTransactionRow(
        type: db.EntryType.transfer,
        accountId: 'acc-1',
        transferAccountId: 'acc-2',
      );

      final movement = AccountMapper.toMovement(row, 'acc-2');

      expect(movement.kind, MovementKind.transferIn);
      expect(movement.signedMinor, 1000);
    });

    test('conserva deletedAt para que el dominio pueda ignorarlo', () {
      final deletedAt = DateTime(2026, 7, 12);

      final movement = AccountMapper.toMovement(
        buildTransactionRow(
          accountId: 'acc-1',
          type: db.EntryType.expense,
          deletedAt: deletedAt,
        ),
        'acc-1',
      );

      expect(movement.deletedAt, deletedAt);
      expect(movement.isActive, isFalse);
    });
  });
}
