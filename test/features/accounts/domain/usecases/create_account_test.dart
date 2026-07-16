import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/utils/money_formatter.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_draft.dart';
import 'package:billetudo/features/accounts/domain/entities/account_number_edit.dart';
import 'package:billetudo/features/accounts/domain/usecases/create_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../account_fixtures.dart';
import 'account_repository_mock.dart';

void main() {
  late MockAccountRepository repository;
  late CreateAccount createAccount;

  setUpAll(registerAccountFallbacks);

  setUp(() {
    repository = MockAccountRepository();
    createAccount = CreateAccount(repository);
    when(() => repository.createAccount(any())).thenAnswer(
      (invocation) async => Right(
        buildAccount(
          name: (invocation.positionalArguments.first as AccountDraft).name,
        ),
      ),
    );
  });

  /// The draft the repository actually received, i.e. after validation
  /// normalized it.
  AccountDraft capturedDraft() =>
      verify(() => repository.createAccount(captureAny())).captured.single
          as AccountDraft;

  ValidationFailure failureOf(Result<Account> result) =>
      result.getLeft().toNullable()! as ValidationFailure;

  group('HU-01 — validación de nombre', () {
    test('rechaza un nombre vacío señalando el campo', () async {
      final result = await createAccount(buildDraft(name: '   '));

      expect(result.isLeft(), isTrue);
      expect(failureOf(result).field, AccountDraft.fieldName);
      verifyNever(() => repository.createAccount(any()));
    });

    test('rechaza un nombre de más de 100 caracteres', () async {
      final result = await createAccount(buildDraft(name: 'a' * 101));

      expect(failureOf(result).field, AccountDraft.fieldName);
    });

    test('acepta nombres de 1 y de 100 caracteres (los bordes válidos)',
        () async {
      expect((await createAccount(buildDraft(name: 'a'))).isRight(), isTrue);
      expect(
        (await createAccount(buildDraft(name: 'a' * 100))).isRight(),
        isTrue,
      );
    });

    test('normaliza el nombre recortando espacios', () async {
      await createAccount(buildDraft(name: '  Ahorros  '));

      expect(capturedDraft().name, 'Ahorros');
    });
  });

  group('HU-01 — validación de moneda', () {
    test('rechaza una moneda que no tiene 3 caracteres', () async {
      for (final currency in ['', 'CO', 'COPS']) {
        final result = await createAccount(buildDraft(currency: currency));

        expect(failureOf(result).field, AccountDraft.fieldCurrency);
      }
    });

    test('rechaza una moneda que no es alfabética (ISO-4217)', () async {
      final result = await createAccount(buildDraft(currency: '123'));

      expect(failureOf(result).field, AccountDraft.fieldCurrency);
    });

    test('normaliza la moneda a mayúsculas', () async {
      await createAccount(buildDraft(currency: 'usd'));

      expect(capturedDraft().currency, 'USD');
    });
  });

  group('HU-02 — validación de tarjeta', () {
    test('rechaza una tarjeta sin cupo', () async {
      final result = await createAccount(
        buildCardDraft(creditLimitMinor: null),
      );

      expect(failureOf(result).field, AccountDraft.fieldCreditLimitMinor);
    });

    test('rechaza días de corte/pago nulos', () async {
      expect(
        failureOf(await createAccount(buildCardDraft(statementDay: null)))
            .field,
        AccountDraft.fieldStatementDay,
      );
      expect(
        failureOf(await createAccount(buildCardDraft(paymentDueDay: null)))
            .field,
        AccountDraft.fieldPaymentDueDay,
      );
    });

    test('rechaza días de corte/pago fuera de 1..31', () async {
      for (final day in [0, 32, -1]) {
        expect(
          failureOf(await createAccount(buildCardDraft(statementDay: day)))
              .field,
          AccountDraft.fieldStatementDay,
        );
        expect(
          failureOf(await createAccount(buildCardDraft(paymentDueDay: day)))
              .field,
          AccountDraft.fieldPaymentDueDay,
        );
      }
    });

    test('acepta los días borde 1 y 31', () async {
      final result = await createAccount(
        buildCardDraft(statementDay: 1, paymentDueDay: 31),
      );

      expect(result.isRight(), isTrue);
    });

    test('una tarjeta válida resalta la deuda por defecto', () async {
      await createAccount(buildCardDraft());

      expect(capturedDraft().cardBalancePrimary, CardBalanceView.debt);
    });

    test('en un tipo que no es tarjeta los campos de tarjeta quedan nulos',
        () async {
      await createAccount(
        buildDraft(
          creditLimitMinor: 500000,
          statementDay: 15,
          paymentDueDay: 5,
          cardBalancePrimary: CardBalanceView.available,
        ),
      );

      final draft = capturedDraft();
      expect(draft.creditLimitMinor, isNull);
      expect(draft.statementDay, isNull);
      expect(draft.paymentDueDay, isNull);
      expect(draft.cardBalancePrimary, isNull);
    });
  });

  group('HU-03 — número de cuenta y last4', () {
    test('deriva last4 de los últimos 4 dígitos del número completo', () async {
      await createAccount(
        buildDraft(numberEdit: const SetAccountNumber('1234567890 4321')),
      );

      expect(capturedDraft().last4, '4321');
    });

    test('la derivación ignora separadores no numéricos', () async {
      await createAccount(
        buildDraft(numberEdit: const SetAccountNumber('123-456-78-90')),
      );

      expect(capturedDraft().last4, '7890');
    });

    test('el número completo pisa un last4 manual contradictorio', () async {
      await createAccount(
        buildDraft(
          numberEdit: const SetAccountNumber('99994321'),
          last4: '1111',
        ),
      );

      expect(capturedDraft().last4, '4321');
    });

    test('acepta last4 manual cuando no se ingresa el número', () async {
      await createAccount(buildDraft(last4: '4321'));

      final draft = capturedDraft();
      expect(draft.last4, '4321');
      expect(draft.numberEdit, isNot(isA<SetAccountNumber>()));
    });

    // El default del draft es KeepAccountNumber: omitir el número nunca puede
    // ser la razón de que se borre (HU-03, no hay copia en la nube).
    test('un draft que no menciona el número no pide borrarlo', () async {
      await createAccount(buildDraft(last4: '4321'));

      expect(capturedDraft().numberEdit, const KeepAccountNumber());
    });

    test('un número en blanco es un borrado deliberado, no un Keep', () async {
      await createAccount(buildDraft(numberEdit: const SetAccountNumber('  ')));

      expect(capturedDraft().numberEdit, const ClearAccountNumber());
    });

    test('rechaza un last4 no numérico', () async {
      final result = await createAccount(buildDraft(last4: '43a1'));

      expect(failureOf(result).field, AccountDraft.fieldLast4);
    });

    test('rechaza un last4 de más de 4 dígitos', () async {
      final result = await createAccount(buildDraft(last4: '12345'));

      expect(failureOf(result).field, AccountDraft.fieldLast4);
    });

    test('rechaza un número completo sin dígitos', () async {
      final result = await createAccount(
        buildDraft(numberEdit: const SetAccountNumber('abc')),
      );

      expect(failureOf(result).field, AccountDraft.fieldFullAccountNumber);
    });

    test('PAN prohibido: una tarjeta no puede guardar el número completo',
        () async {
      final result = await createAccount(
        buildCardDraft(numberEdit: const SetAccountNumber('4111111111111111')),
      );

      expect(result.isLeft(), isTrue);
      expect(failureOf(result).field, AccountDraft.fieldFullAccountNumber);
      verifyNever(() => repository.createAccount(any()));
    });

    test('una tarjeta sí puede identificarse con last4', () async {
      final result = await createAccount(buildCardDraft(last4: '4321'));

      expect(result.isRight(), isTrue);
      expect(capturedDraft().last4, '4321');
    });

    test('efectivo no lleva número de cuenta', () async {
      final result = await createAccount(
        buildDraft(
          type: AccountType.cash,
          numberEdit: const SetAccountNumber('12344321'),
        ),
      );

      expect(failureOf(result).field, AccountDraft.fieldFullAccountNumber);
    });
  });

  group('HU-01 — dinero y tasas enteros', () {
    test('el saldo inicial viaja como entero de centavos', () async {
      await createAccount(buildDraft(initialBalanceMinor: 1234));

      final draft = capturedDraft();
      expect(draft.initialBalanceMinor, 1234);
      expect(draft.initialBalanceMinor, isA<int>());
    });

    test('acepta saldo inicial negativo (deuda ya existente)', () async {
      final result = await createAccount(buildCardDraft());

      expect(result.isRight(), isTrue);
    });

    test('la tasa se guarda en puntos básicos enteros: 24,5% -> 2450',
        () async {
      final bps = MoneyFormatter.parseRateBps('24,5');
      await createAccount(buildDraft(interestRateBps: bps));

      expect(capturedDraft().interestRateBps, 2450);
    });

    test('rechaza una tasa negativa', () async {
      final result = await createAccount(buildDraft(interestRateBps: -1));

      expect(failureOf(result).field, AccountDraft.fieldInterestRateBps);
    });
  });

  test('propaga el fallo del repositorio sin envolverlo', () async {
    when(() => repository.createAccount(any())).thenAnswer(
      (_) async => const Left(DatabaseFailure('disco lleno')),
    );

    final result = await createAccount(buildDraft());

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
