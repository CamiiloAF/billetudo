import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_deletion_impact.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_detail_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_detail_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../account_fixtures.dart';
import 'usecase_mocks.dart';

void main() {
  late MockWatchAccountDetail watchDetail;
  late MockGetAccountNumber getAccountNumber;
  late MockSetCardBalancePrimary setCardBalancePrimary;
  late MockGetAccountDeletionImpact getImpact;
  late MockArchiveAccount archiveAccount;
  late MockDeleteAccount deleteAccount;
  late MockSecureClipboard clipboard;
  late StreamController<Result<AccountWithBalance>> detailStream;

  const accountId = 'acc-9';
  const number = '1234567890';

  final account = buildAccount(id: accountId, last4: '7890');
  final entry = buildAccountWithBalance(account: account, balanceMinor: 250000);

  setUpAll(registerPresentationFallbacks);

  setUp(() {
    watchDetail = MockWatchAccountDetail();
    getAccountNumber = MockGetAccountNumber();
    setCardBalancePrimary = MockSetCardBalancePrimary();
    getImpact = MockGetAccountDeletionImpact();
    archiveAccount = MockArchiveAccount();
    deleteAccount = MockDeleteAccount();
    clipboard = MockSecureClipboard();

    when(() => watchDetail(any()))
        .thenAnswer((_) => Stream.value(Right(entry)));
  });

  AccountDetailCubit build() => AccountDetailCubit(
        watchDetail,
        getAccountNumber,
        setCardBalancePrimary,
        getImpact,
        archiveAccount,
        deleteAccount,
        clipboard,
      );

  group('número de cuenta (HU-03)', () {
    test('un cubit recién creado arranca enmascarado', () {
      expect(build().state.isNumberRevealed, isFalse);
      expect(build().state.revealedNumber, isNull);
    });

    blocTest<AccountDetailCubit, AccountDetailState>(
      'oculto -> revelado -> oculto, leyendo del almacén seguro cada vez',
      setUp: () => when(() => getAccountNumber(accountId))
          .thenAnswer((_) async => const Right(number)),
      build: build,
      act: (cubit) async {
        await cubit.start(accountId);
        await cubit.revealNumber();
        cubit.hideNumber();
      },
      verify: (cubit) {
        expect(cubit.state.isNumberRevealed, isFalse);
        verify(() => getAccountNumber(accountId)).called(1);
      },
    );

    blocTest<AccountDetailCubit, AccountDetailState>(
      'revelar expone el número solo en el estado, sin persistirlo',
      setUp: () => when(() => getAccountNumber(accountId))
          .thenAnswer((_) async => const Right(number)),
      build: build,
      act: (cubit) async {
        await cubit.start(accountId);
        await cubit.revealNumber();
      },
      verify: (cubit) {
        expect(cubit.state.revealedNumber, number);
        // Revelar es solo mirar: no toca la cuenta ni ningún almacén.
        verifyNever(() => setCardBalancePrimary(any(), any()));
      },
    );

    blocTest<AccountDetailCubit, AccountDetailState>(
      'una nueva emisión de saldo no vuelve a enmascarar el número revelado',
      setUp: () {
        when(() => getAccountNumber(accountId))
            .thenAnswer((_) async => const Right(number));
        when(() => watchDetail(any())).thenAnswer(
          (_) => Stream.fromIterable([Right(entry), Right(entry)]),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start(accountId);
        await cubit.revealNumber();
        await Future<void>.delayed(Duration.zero);
      },
      verify: (cubit) => expect(cubit.state.revealedNumber, number),
    );

    blocTest<AccountDetailCubit, AccountDetailState>(
      'copiar usa SecureClipboard (que limpia a los 60s)',
      setUp: () {
        when(() => getAccountNumber(accountId))
            .thenAnswer((_) async => const Right(number));
        when(() => clipboard.copySensitive(any())).thenAnswer((_) async {});
      },
      build: build,
      act: (cubit) async {
        await cubit.start(accountId);
        expect(await cubit.copyNumber(), isTrue);
      },
      verify: (_) => verify(() => clipboard.copySensitive(number)).called(1),
    );

    blocTest<AccountDetailCubit, AccountDetailState>(
      'sin número guardado no se copia nada',
      setUp: () => when(() => getAccountNumber(accountId))
          .thenAnswer((_) async => const Right(null)),
      build: build,
      act: (cubit) async {
        await cubit.start(accountId);
        expect(await cubit.copyNumber(), isFalse);
      },
      verify: (_) => verifyNever(() => clipboard.copySensitive(any())),
    );

    blocTest<AccountDetailCubit, AccountDetailState>(
      'un fallo del almacén seguro se reporta y deja el número enmascarado',
      setUp: () => when(() => getAccountNumber(accountId))
          .thenAnswer((_) async => const Left(SecureStorageFailure('nope'))),
      build: build,
      act: (cubit) async {
        await cubit.start(accountId);
        await cubit.revealNumber();
      },
      verify: (cubit) {
        expect(cubit.state.failure, isA<SecureStorageFailure>());
        expect(cubit.state.isNumberRevealed, isFalse);
      },
    );
  });

  group('carrusel de la tarjeta (HU-04)', () {
    blocTest<AccountDetailCubit, AccountDetailState>(
      'cambiar de página guarda la preferencia',
      setUp: () => when(() => setCardBalancePrimary(any(), any()))
          .thenAnswer((_) async => const Right(unit)),
      build: build,
      act: (cubit) async {
        await cubit.start(accountId);
        await cubit.cardViewChanged(CardBalanceView.available);
      },
      verify: (_) => verify(
        () => setCardBalancePrimary(accountId, CardBalanceView.available),
      ).called(1),
    );

    blocTest<AccountDetailCubit, AccountDetailState>(
      'volver a la página ya activa no vuelve a escribir',
      build: build,
      act: (cubit) async {
        await cubit.start(accountId);
        // La cuenta de prueba no es tarjeta: su vista por defecto es `debt`.
        await cubit.cardViewChanged(CardBalanceView.debt);
      },
      verify: (_) => verifyNever(() => setCardBalancePrimary(any(), any())),
    );
  });

  group('archivar y eliminar', () {
    blocTest<AccountDetailCubit, AccountDetailState>(
      'archivar pide confirmación y al confirmar cierra la pantalla',
      setUp: () => when(() => archiveAccount(any()))
          .thenAnswer((_) async => const Right(unit)),
      build: build,
      act: (cubit) async {
        await cubit.start(accountId);
        await cubit.promptArchive();
        expect(cubit.state.prompt, AccountDetailPrompt.archive);
        await cubit.confirmArchive();
      },
      verify: (cubit) {
        expect(cubit.state.status, AccountDetailStatus.closed);
        verify(() => archiveAccount(accountId)).called(1);
      },
    );

    blocTest<AccountDetailCubit, AccountDetailState>(
      'eliminar carga el impacto y pide confirmación',
      setUp: () {
        when(() => getImpact(any())).thenAnswer(
          (_) async => const Right(
            AccountDeletionImpact(
              transactionCount: 12,
              goalCount: 1,
              debtCount: 0,
              isLastAccount: false,
            ),
          ),
        );
        when(() => deleteAccount(any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.start(accountId);
        await cubit.promptDelete();
        expect(cubit.state.prompt, AccountDetailPrompt.delete);
        expect(cubit.state.impact?.transactionCount, 12);
        await cubit.confirmDelete();
      },
      verify: (cubit) {
        expect(cubit.state.status, AccountDetailStatus.closed);
        verify(() => deleteAccount(accountId)).called(1);
      },
    );

    blocTest<AccountDetailCubit, AccountDetailState>(
      'la última cuenta activa muestra la hoja de bloqueo, no la de confirmar '
      '(HU-08)',
      setUp: () => when(() => getImpact(any())).thenAnswer(
        (_) async => const Right(
          AccountDeletionImpact(
            transactionCount: 0,
            goalCount: 0,
            debtCount: 0,
            isLastAccount: true,
          ),
        ),
      ),
      build: build,
      act: (cubit) async {
        await cubit.start(accountId);
        await cubit.promptDelete();
      },
      verify: (cubit) {
        expect(cubit.state.prompt, AccountDetailPrompt.cannotDelete);
        // Nunca se llega a pedir el borrado: se bloquea antes.
        verifyNever(() => deleteAccount(any()));
      },
    );

    blocTest<AccountDetailCubit, AccountDetailState>(
      'descartar la confirmación no elimina nada',
      setUp: () => when(() => getImpact(any())).thenAnswer(
        (_) async => const Right(
          AccountDeletionImpact(
            transactionCount: 0,
            goalCount: 0,
            debtCount: 0,
            isLastAccount: false,
          ),
        ),
      ),
      build: build,
      act: (cubit) async {
        await cubit.start(accountId);
        await cubit.promptDelete();
        cubit.dismissPrompt();
      },
      verify: (cubit) {
        expect(cubit.state.prompt, AccountDetailPrompt.none);
        verifyNever(() => deleteAccount(any()));
      },
    );

    test(
      'a stream emission that lands while the delete write is still pending '
      'never reaches the state (regression: see _runClosing docs — this used '
      'to reopen the confirmation sheet and strand the page on a spinner, '
      'confirmed against a live repro)',
      () async {
        when(() => getImpact(any())).thenAnswer(
          (_) async => const Right(
            AccountDeletionImpact(
              transactionCount: 0,
              goalCount: 0,
              debtCount: 0,
              isLastAccount: false,
            ),
          ),
        );
        when(() => deleteAccount(any())).thenAnswer((_) async {
          // Mirrors the real race: Drift's reactive watch fires a stale
          // NotFoundFailure the instant the tombstone write commits, before
          // this use case's own future resolves back up the call stack.
          detailStream.add(
            const Left(NotFoundFailure('account "acc-9" does not exist')),
          );
          await Future<void>.delayed(Duration.zero);
          return const Right(unit);
        });
        detailStream = StreamController<Result<AccountWithBalance>>();
        addTearDown(detailStream.close);
        when(() => watchDetail(any())).thenAnswer((_) => detailStream.stream);
        final cubit = build();
        addTearDown(cubit.close);
        final emitted = <AccountDetailState>[];
        final subscription = cubit.stream.listen(emitted.add);
        addTearDown(subscription.cancel);

        detailStream.add(Right(entry));
        await cubit.start(accountId);
        await cubit.promptDelete();
        await cubit.confirmDelete();

        // The spurious emission must never surface: no emitted state — not
        // even a transient one — carries `status: failure`, and the final
        // state is `closed` with the prompt cleared and no stray failure.
        expect(
          emitted.map((s) => s.status),
          isNot(contains(AccountDetailStatus.failure)),
        );
        expect(cubit.state.status, AccountDetailStatus.closed);
        expect(cubit.state.prompt, AccountDetailPrompt.none);
        expect(cubit.state.failure, isNull);
      },
    );
  });
}
