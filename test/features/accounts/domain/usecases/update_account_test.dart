import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_draft.dart';
import 'package:billetudo/features/accounts/domain/usecases/update_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../account_fixtures.dart';
import 'account_repository_mock.dart';

void main() {
  late MockAccountRepository repository;
  late UpdateAccount updateAccount;

  setUpAll(registerAccountFallbacks);

  setUp(() {
    repository = MockAccountRepository();
    updateAccount = UpdateAccount(repository);
    when(() => repository.updateAccount(any())).thenAnswer(
      (_) async => Right(buildAccount()),
    );
    when(() => repository.hasTransactions(any()))
        .thenAnswer((_) async => const Right(false));
  });

  void givenExisting(Account account) {
    when(() => repository.getAccount(any()))
        .thenAnswer((_) async => Right(account));
  }

  AccountDraft capturedDraft() =>
      verify(() => repository.updateAccount(captureAny())).captured.single
          as AccountDraft;

  ValidationFailure failureOf(Result<Account> result) =>
      result.getLeft().toNullable()! as ValidationFailure;

  test('exige un id: no se puede editar un borrador sin cuenta', () async {
    final result = await updateAccount(buildDraft());

    expect(failureOf(result).field, AccountDraft.fieldId);
    verifyNever(() => repository.updateAccount(any()));
  });

  test('propaga NotFound si la cuenta no existe', () async {
    when(() => repository.getAccount(any()))
        .thenAnswer((_) async => const Left(NotFoundFailure('no existe')));

    final result = await updateAccount(buildDraft(id: 'acc-1'));

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    verifyNever(() => repository.updateAccount(any()));
  });

  test('aplica las mismas validaciones que crear (HU-01)', () async {
    givenExisting(buildAccount());

    final result = await updateAccount(buildDraft(id: 'acc-1', name: ''));

    expect(failureOf(result).field, AccountDraft.fieldName);
    verifyNever(() => repository.updateAccount(any()));
  });

  group('HU-06 — cambio de tipo o moneda', () {
    test('sin transacciones no pide confirmación', () async {
      givenExisting(buildAccount(type: AccountType.savings));
      when(() => repository.hasTransactions(any()))
          .thenAnswer((_) async => const Right(false));

      final result = await updateAccount(
        buildDraft(id: 'acc-1', type: AccountType.investment),
      );

      expect(result.isRight(), isTrue);
    });

    test('con transacciones y sin confirmar, rechaza el cambio de tipo',
        () async {
      givenExisting(buildAccount(type: AccountType.savings));
      when(() => repository.hasTransactions(any()))
          .thenAnswer((_) async => const Right(true));

      final result = await updateAccount(
        buildDraft(id: 'acc-1', type: AccountType.investment),
      );

      expect(failureOf(result).field, UpdateAccount.confirmationField);
      verifyNever(() => repository.updateAccount(any()));
    });

    test('con transacciones y sin confirmar, rechaza el cambio de moneda',
        () async {
      givenExisting(buildAccount(currency: 'USD'));
      when(() => repository.hasTransactions(any()))
          .thenAnswer((_) async => const Right(true));

      final result = await updateAccount(
        buildDraft(id: 'acc-1', currency: 'MXN'),
      );

      expect(failureOf(result).field, UpdateAccount.confirmationField);
    });

    test('con el flag de confirmación el cambio se aplica', () async {
      givenExisting(buildAccount(currency: 'USD'));
      when(() => repository.hasTransactions(any()))
          .thenAnswer((_) async => const Right(true));

      final result = await updateAccount(
        buildDraft(id: 'acc-1', currency: 'MXN'),
        confirmed: true,
      );

      expect(result.isRight(), isTrue);
      expect(capturedDraft().currency, 'MXN');
    });

    test('confirmado, ni siquiera consulta si hay transacciones', () async {
      givenExisting(buildAccount(currency: 'USD'));

      await updateAccount(
        buildDraft(id: 'acc-1', currency: 'MXN'),
        confirmed: true,
      );

      verifyNever(() => repository.hasTransactions(any()));
    });

    test('editar otros campos no exige confirmación aunque haya transacciones',
        () async {
      givenExisting(buildAccount(name: 'Viejo', type: AccountType.savings));
      when(() => repository.hasTransactions(any()))
          .thenAnswer((_) async => const Right(true));

      final result = await updateAccount(
        buildDraft(id: 'acc-1', name: 'Nuevo', type: AccountType.savings),
      );

      expect(result.isRight(), isTrue);
      expect(capturedDraft().name, 'Nuevo');
    });
  });

  group('HU-06 — campos de tarjeta al cambiar de tipo', () {
    test('al salir DESDE tarjeta los campos de tarjeta quedan nulos', () async {
      givenExisting(
        buildCard(id: 'acc-1', creditLimitMinor: 500000),
      );

      final result = await updateAccount(
        buildDraft(
          id: 'acc-1',
          type: AccountType.savings,
          // El formulario podría arrastrar los valores viejos: deben limpiarse.
          creditLimitMinor: 500000,
          statementDay: 15,
          paymentDueDay: 5,
          cardBalancePrimary: CardBalanceView.debt,
        ),
        confirmed: true,
      );

      expect(result.isRight(), isTrue);
      final draft = capturedDraft();
      expect(draft.creditLimitMinor, isNull);
      expect(draft.statementDay, isNull);
      expect(draft.paymentDueDay, isNull);
      expect(draft.cardBalancePrimary, isNull);
    });

    test('al cambiar HACIA tarjeta exige los campos de HU-02', () async {
      givenExisting(buildAccount(type: AccountType.savings));

      final result = await updateAccount(
        buildDraft(id: 'acc-1', type: AccountType.card),
        confirmed: true,
      );

      expect(failureOf(result).field, AccountDraft.fieldCreditLimitMinor);
      verifyNever(() => repository.updateAccount(any()));
    });

    test('al cambiar HACIA tarjeta con los campos completos, pasa', () async {
      givenExisting(buildAccount(type: AccountType.savings));

      final result = await updateAccount(
        buildCardDraft(id: 'acc-1'),
        confirmed: true,
      );

      expect(result.isRight(), isTrue);
      expect(capturedDraft().creditLimitMinor, 500000);
    });
  });
}
