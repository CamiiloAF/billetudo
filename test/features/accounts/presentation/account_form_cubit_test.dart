import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/utils/money_formatter.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_draft.dart';
import 'package:billetudo/features/accounts/domain/entities/account_number_edit.dart';
import 'package:billetudo/features/accounts/domain/usecases/update_account.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_form_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_form_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../account_fixtures.dart';
import 'usecase_mocks.dart';

void main() {
  late MockCreateAccount createAccount;
  late MockUpdateAccount updateAccount;
  late MockWatchAccountDetail watchDetail;
  late MockGetAccountNumber getAccountNumber;

  const accountId = 'acc-9';

  setUpAll(registerPresentationFallbacks);

  setUp(() {
    createAccount = MockCreateAccount();
    updateAccount = MockUpdateAccount();
    watchDetail = MockWatchAccountDetail();
    getAccountNumber = MockGetAccountNumber();

    when(() => createAccount(any()))
        .thenAnswer((_) async => Right(buildAccount()));
    when(() => updateAccount(any(), confirmed: any(named: 'confirmed')))
        .thenAnswer((_) async => Right(buildAccount()));
    when(() => getAccountNumber(any()))
        .thenAnswer((_) async => const Right(null));
  });

  AccountFormCubit build() => AccountFormCubit(
        createAccount,
        updateAccount,
        watchDetail,
        getAccountNumber,
        const MoneyFormatter(),
      );

  void stubAccount(Account account) {
    when(() => watchDetail(any())).thenAnswer(
      (_) => Stream.value(
        Right(buildAccountWithBalance(account: account, balanceMinor: 0)),
      ),
    );
  }

  /// The draft the cubit handed to the use case.
  AccountDraft capturedCreate() =>
      verify(() => createAccount(captureAny())).captured.single as AccountDraft;

  group('alta', () {
    blocTest<AccountFormCubit, AccountFormState>(
      'un formulario nuevo arranca listo, sin tipo y en COP',
      build: build,
      act: (cubit) => cubit.load(null),
      verify: (cubit) {
        expect(cubit.state.status, AccountFormStatus.ready);
        expect(cubit.state.type, isNull);
        expect(cubit.state.currency, AccountFormState.defaultCurrency);
        expect(cubit.state.isEditing, isFalse);
        // Sin tipo elegido el grid se muestra abierto, no como pill.
        expect(cubit.state.showTypeGrid, isTrue);
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'guardar sin tipo falla en el campo del tipo, sin llamar al caso de uso',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.nameChanged('Mi cuenta');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.failedField, AccountFormState.fieldType);
        verifyNever(() => createAccount(any()));
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'los montos y la tasa viajan como enteros: 4.500,50 -> 450050 y '
      '24,5% -> 2450 bps',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.typeSelected(AccountType.bank);
        cubit.nameChanged('Bancolombia');
        cubit.initialBalanceChanged('4.500,50');
        cubit.interestRateChanged('24,5');
        await cubit.submit();
      },
      verify: (_) {
        final draft = capturedCreate();
        expect(draft.initialBalanceMinor, 450050);
        expect(draft.interestRateBps, 2450);
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'un saldo vacío es 0, no un error',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.typeSelected(AccountType.cash);
        cubit.nameChanged('Efectivo');
        await cubit.submit();
      },
      verify: (_) => expect(capturedCreate().initialBalanceMinor, 0),
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'un saldo que no es un número marca el error de su campo',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.typeSelected(AccountType.bank);
        cubit.nameChanged('Bancolombia');
        cubit.initialBalanceChanged('abc');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.failedField, AccountFormState.fieldInitialBalance);
        verifyNever(() => createAccount(any()));
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'el fallo de validación del dominio marca el campo que corresponde',
      setUp: () => when(() => createAccount(any())).thenAnswer(
        (_) async => const Left(
          ValidationFailure('nope', field: AccountDraft.fieldName),
        ),
      ),
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.typeSelected(AccountType.bank);
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.failedField, AccountDraft.fieldName);
        expect(cubit.state.status, AccountFormStatus.ready);
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'al guardar bien, el estado pasa a saved y la página se cierra',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.typeSelected(AccountType.bank);
        cubit.nameChanged('Bancolombia');
        await cubit.submit();
      },
      verify: (cubit) => expect(cubit.state.status, AccountFormStatus.saved),
    );
  });

  group('campos condicionales por tipo', () {
    blocTest<AccountFormCubit, AccountFormState>(
      'efectivo no pide número ni últimos 4 dígitos',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.typeSelected(AccountType.cash);
      },
      verify: (cubit) {
        expect(cubit.state.showFullNumberField, isFalse);
        expect(cubit.state.showLast4Field, isFalse);
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'una tarjeta pide últimos 4 dígitos pero nunca el número completo '
      '(HU-03)',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.typeSelected(AccountType.card);
      },
      verify: (cubit) {
        expect(cubit.state.showFullNumberField, isFalse);
        expect(cubit.state.showLast4Field, isTrue);
        expect(cubit.state.isCard, isTrue);
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'con número completo escrito, los últimos 4 se derivan y su campo '
      'desaparece',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.typeSelected(AccountType.bank);
        cubit.fullAccountNumberChanged('1234567890');
      },
      verify: (cubit) {
        expect(cubit.state.showFullNumberField, isTrue);
        expect(cubit.state.showLast4Field, isFalse);
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'pasar a tarjeta descarta el número completo escrito antes: un PAN nunca '
      'llega al dominio (HU-03)',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.typeSelected(AccountType.bank);
        cubit.fullAccountNumberChanged('1234567890');
        cubit.typeSelected(AccountType.card);
        cubit.nameChanged('Tarjeta');
        cubit.creditLimitChanged('3.000.000');
        cubit.statementDaySelected(15);
        cubit.paymentDueDaySelected(5);
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.fullAccountNumber, isNull);
        final draft = capturedCreate();
        expect(draft.numberEdit, const ClearAccountNumber());
        expect(draft.creditLimitMinor, 300000000);
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'elegir el tipo colapsa el grid',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.typeSelected(AccountType.bank);
      },
      verify: (cubit) => expect(cubit.state.typePickerExpanded, isFalse),
    );
  });

  group('edición (HU-06)', () {
    blocTest<AccountFormCubit, AccountFormState>(
      'precarga la cuenta y su número guardado',
      setUp: () {
        stubAccount(
          buildAccount(
            id: accountId,
            name: 'Bancolombia',
            institution: 'Bancolombia S.A.',
            initialBalanceMinor: 450050,
            interestRateBps: 2450,
            last4: '7890',
          ),
        );
        when(() => getAccountNumber(accountId))
            .thenAnswer((_) async => const Right('1234567890'));
      },
      build: build,
      act: (cubit) => cubit.load(accountId),
      verify: (cubit) {
        expect(cubit.state.isEditing, isTrue);
        expect(cubit.state.name, 'Bancolombia');
        expect(cubit.state.initialBalanceText, contains('4.500,50'));
        // El número vuelve al formulario: sin él, el repositorio lo borraría
        // del almacén seguro en el siguiente guardado.
        expect(cubit.state.fullAccountNumber, '1234567890');
        // Con tipo ya elegido, el grid arranca colapsado en el pill.
        expect(cubit.state.showTypeGrid, isFalse);
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'un cambio ajeno (renombrar) conserva el número: no lo borra',
      setUp: () {
        stubAccount(buildAccount(id: accountId, last4: '7890'));
        when(() => getAccountNumber(accountId))
            .thenAnswer((_) async => const Right('1234567890'));
      },
      build: build,
      act: (cubit) async {
        await cubit.load(accountId);
        cubit.nameChanged('Nuevo nombre');
        await cubit.submit();
      },
      verify: (_) {
        final draft = verify(
          () => updateAccount(captureAny(), confirmed: any(named: 'confirmed')),
        ).captured.single as AccountDraft;
        expect(draft.numberEdit, const SetAccountNumber('1234567890'));
        expect(draft.name, 'Nuevo nombre');
      },
    );

    // Regresión (HU-03): la lectura del Keystore puede fallar (descifrado roto
    // en Android). Ese Left colapsaba al mismo null que significa "esta cuenta
    // no tiene número", el campo salía vacío y mudo, y el siguiente guardado
    // borraba el número para siempre: no hay copia en la nube, por diseño.
    blocTest<AccountFormCubit, AccountFormState>(
      'si la lectura del número falla, guardar NO lo borra: lo deja intacto',
      setUp: () {
        stubAccount(buildAccount(id: accountId, last4: '7890'));
        when(() => getAccountNumber(accountId)).thenAnswer(
          (_) async => const Left(SecureStorageFailure('keystore roto')),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.load(accountId);
        cubit.nameChanged('Nuevo nombre');
        await cubit.submit();
      },
      verify: (_) {
        final draft = verify(
          () => updateAccount(captureAny(), confirmed: any(named: 'confirmed')),
        ).captured.single as AccountDraft;
        expect(draft.numberEdit, const KeepAccountNumber());
        expect(draft.name, 'Nuevo nombre');
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'si la lectura del número falla, el formulario lo dice en vez de mostrar '
      'un campo vacío y mudo',
      setUp: () {
        stubAccount(buildAccount(id: accountId, last4: '7890'));
        when(() => getAccountNumber(accountId)).thenAnswer(
          (_) async => const Left(SecureStorageFailure('keystore roto')),
        );
      },
      build: build,
      act: (cubit) => cubit.load(accountId),
      verify: (cubit) {
        expect(cubit.state.isNumberUnknown, isTrue);
        // El formulario sigue usable: el fallo es del número, no de la cuenta.
        expect(cubit.state.status, AccountFormStatus.ready);
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'tras un fallo de lectura, escribir un número nuevo sí lo guarda',
      setUp: () {
        stubAccount(buildAccount(id: accountId, last4: '7890'));
        when(() => getAccountNumber(accountId)).thenAnswer(
          (_) async => const Left(SecureStorageFailure('keystore roto')),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.load(accountId);
        cubit.fullAccountNumberChanged('99998888');
        await cubit.submit();
      },
      verify: (cubit) {
        // Ya no hay nada que proteger: el usuario dictó el número.
        expect(cubit.state.isNumberUnknown, isFalse);
        final draft = verify(
          () => updateAccount(captureAny(), confirmed: any(named: 'confirmed')),
        ).captured.single as AccountDraft;
        expect(draft.numberEdit, const SetAccountNumber('99998888'));
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'con la lectura OK, vaciar el campo sigue borrando el número a propósito',
      setUp: () {
        stubAccount(buildAccount(id: accountId, last4: '7890'));
        when(() => getAccountNumber(accountId))
            .thenAnswer((_) async => const Right('1234567890'));
      },
      build: build,
      act: (cubit) async {
        await cubit.load(accountId);
        cubit.fullAccountNumberChanged('');
        await cubit.submit();
      },
      verify: (_) {
        final draft = verify(
          () => updateAccount(captureAny(), confirmed: any(named: 'confirmed')),
        ).captured.single as AccountDraft;
        expect(draft.numberEdit, const ClearAccountNumber());
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'un cambio ajeno (renombrar) conserva la vista principal de la tarjeta '
      '(HU-04): no la reinicia a deuda',
      setUp: () => stubAccount(
        buildCard(
          id: accountId,
          creditLimitMinor: 500000,
          cardBalancePrimary: CardBalanceView.available,
        ),
      ),
      build: build,
      act: (cubit) async {
        await cubit.load(accountId);
        cubit.nameChanged('Nuevo nombre');
        await cubit.submit();
      },
      verify: (_) {
        final draft = verify(
          () => updateAccount(captureAny(), confirmed: any(named: 'confirmed')),
        ).captured.single as AccountDraft;
        // El companion de update la escribe explícitamente (HU-06): si el
        // formulario no la transporta, llega null y el draft la degrada a
        // deuda, borrando la preferencia del usuario.
        expect(draft.cardBalancePrimary, CardBalanceView.available);
        expect(draft.name, 'Nuevo nombre');
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'precarga la vista principal guardada de la tarjeta',
      setUp: () => stubAccount(
        buildCard(
          id: accountId,
          creditLimitMinor: 500000,
          cardBalancePrimary: CardBalanceView.available,
        ),
      ),
      build: build,
      act: (cubit) => cubit.load(accountId),
      verify: (cubit) => expect(
        cubit.state.cardBalancePrimary,
        CardBalanceView.available,
      ),
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'si el dominio exige confirmar el cambio de tipo/moneda, el estado la '
      'pide en vez de mostrar un error',
      setUp: () {
        stubAccount(buildAccount(id: accountId));
        when(() => updateAccount(any())).thenAnswer(
          (_) async => const Left(
            ValidationFailure(
              'needs confirmation',
              field: UpdateAccount.confirmationField,
            ),
          ),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.load(accountId);
        cubit.currencySelected('USD');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.needsConfirmation, isTrue);
        // Es una pregunta, no un fallo: nada que pintar en rojo.
        expect(cubit.state.failure, isNull);
        expect(cubit.state.status, AccountFormStatus.ready);
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'confirmado, reenvía con confirmed: true y guarda',
      setUp: () {
        stubAccount(buildAccount(id: accountId));
        when(() => updateAccount(any())).thenAnswer(
          (_) async => const Left(
            ValidationFailure(
              'needs confirmation',
              field: UpdateAccount.confirmationField,
            ),
          ),
        );
        when(() => updateAccount(any(), confirmed: true))
            .thenAnswer((_) async => Right(buildAccount()));
      },
      build: build,
      act: (cubit) async {
        await cubit.load(accountId);
        cubit.currencySelected('USD');
        await cubit.submit();
        await cubit.submit(confirmed: true);
      },
      verify: (cubit) {
        expect(cubit.state.status, AccountFormStatus.saved);
        verify(() => updateAccount(any(), confirmed: true)).called(1);
      },
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'editar lo que sea vuelve a dejar la confirmación en falso',
      setUp: () {
        stubAccount(buildAccount(id: accountId));
        when(() => updateAccount(any())).thenAnswer(
          (_) async => const Left(
            ValidationFailure(
              'needs confirmation',
              field: UpdateAccount.confirmationField,
            ),
          ),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.load(accountId);
        cubit.currencySelected('USD');
        await cubit.submit();
        cubit.nameChanged('Otro nombre');
      },
      verify: (cubit) => expect(cubit.state.needsConfirmation, isFalse),
    );

    blocTest<AccountFormCubit, AccountFormState>(
      'si la cuenta no existe, el formulario queda en error',
      setUp: () => when(() => watchDetail(any())).thenAnswer(
        (_) => Stream.value(const Left(NotFoundFailure('nope'))),
      ),
      build: build,
      act: (cubit) => cubit.load(accountId),
      verify: (cubit) {
        expect(cubit.state.status, AccountFormStatus.failure);
        expect(cubit.state.failure, isA<NotFoundFailure>());
      },
    );
  });
}
