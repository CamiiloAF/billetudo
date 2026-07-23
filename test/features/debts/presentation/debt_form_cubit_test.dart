import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_detail.dart';
import 'package:billetudo/features/debts/domain/entities/debt_draft.dart';
import 'package:billetudo/features/debts/domain/entities/debt_ledger_entry.dart';
import 'package:billetudo/features/debts/domain/usecases/create_debt.dart';
import 'package:billetudo/features/debts/domain/usecases/create_debt_with_opening_movement.dart';
import 'package:billetudo/features/debts/domain/usecases/delete_debt.dart';
import 'package:billetudo/features/debts/domain/usecases/update_debt.dart';
import 'package:billetudo/features/debts/domain/usecases/update_initial_movement.dart';
import 'package:billetudo/features/debts/domain/usecases/watch_debt_detail.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_form_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_form_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../accounts/account_fixtures.dart';
import 'debts_presentation_fixtures.dart';

class MockCreateDebt extends Mock implements CreateDebt {}

class MockCreateDebtWithOpeningMovement extends Mock
    implements CreateDebtWithOpeningMovement {}

class MockUpdateDebt extends Mock implements UpdateDebt {}

class MockUpdateInitialMovement extends Mock implements UpdateInitialMovement {}

class MockDeleteDebt extends Mock implements DeleteDebt {}

class MockWatchDebtDetail extends Mock implements WatchDebtDetail {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

void main() {
  late MockCreateDebt createDebt;
  late MockCreateDebtWithOpeningMovement createWithOpening;
  late MockUpdateDebt updateDebt;
  late MockUpdateInitialMovement updateInitialMovement;
  late MockDeleteDebt deleteDebt;
  late MockWatchDebtDetail watchDebtDetail;
  late MockWatchAccounts watchAccounts;

  final account = buildAccountWithBalance(
    account: buildAccount(id: 'a1', name: 'Bancolombia'),
    balanceMinor: 900000000,
  );

  setUpAll(() {
    registerFallbackValue(
      const DebtDraft(
        name: 'x',
        direction: DebtDirection.iOwe,
        principalMinor: 0,
        currency: 'COP',
      ),
    );
    registerFallbackValue(DebtDirection.iOwe);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    createDebt = MockCreateDebt();
    createWithOpening = MockCreateDebtWithOpeningMovement();
    updateDebt = MockUpdateDebt();
    updateInitialMovement = MockUpdateInitialMovement();
    deleteDebt = MockDeleteDebt();
    watchDebtDetail = MockWatchDebtDetail();
    watchAccounts = MockWatchAccounts();
    // No accounts by default; the registro-inicial flow is opted into per test.
    when(watchAccounts.call).thenAnswer(
      (_) => Stream.value(const Right(<AccountWithBalance>[])),
    );
  });

  DebtFormCubit build() => DebtFormCubit(
        createDebt,
        createWithOpening,
        updateDebt,
        updateInitialMovement,
        deleteDebt,
        watchDebtDetail,
        watchAccounts,
      );

  blocTest<DebtFormCubit, DebtFormState>(
    'load(null): abre un formulario vacío listo',
    build: build,
    act: (cubit) => cubit.load(null),
    expect: () => [
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.ready)
          .having((s) => s.isEditing, 'isEditing', false),
    ],
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'load(id): prellena desde la deuda existente',
    setUp: () => when(() => watchDebtDetail.call('d1')).thenAnswer(
      (_) => Stream.value(
        Right(
          DebtDetail(
            debt: buildDebt(
              name: 'Crédito vehicular',
              principalMinor: 4200000000,
              counterparty: 'Banco',
              interestRateBps: 1850,
              accrualMode: DebtAccrualMode.auto,
            ),
            balance: buildBalance(),
            ledger: const [],
          ),
        ),
      ),
    ),
    build: build,
    act: (cubit) => cubit.load('d1'),
    expect: () => [
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.ready)
          .having((s) => s.isEditing, 'isEditing', true)
          .having((s) => s.name, 'name', 'Crédito vehicular')
          .having((s) => s.amountMinor, 'amountMinor', 4200000000)
          .having((s) => s.counterparty, 'counterparty', 'Banco')
          .having((s) => s.rateText, 'rateText', '18,5')
          .having((s) => s.accrualMode, 'accrualMode', DebtAccrualMode.auto),
    ],
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'load(id) con registro: el héroe muestra el monto del movimiento, no el '
    'principal (0)',
    setUp: () => when(() => watchDebtDetail.call('d1')).thenAnswer(
      (_) => Stream.value(
        Right(
          buildDebtDetail(
            debt: buildDebt(
              principalMinor: 0,
              initialTransactionId: 't-open',
            ),
            ledger: [
              buildLedgerEntry(
                id: 't-open',
                kind: DebtLedgerKind.cashDisbursement,
                effectMinor: 4200000000,
                transactionId: 't-open',
              ),
            ],
          ),
        ),
      ),
    ),
    build: build,
    act: (cubit) => cubit.load('d1'),
    expect: () => [
      isA<DebtFormState>()
          .having((s) => s.amountMinor, 'amountMinor', 4200000000)
          .having((s) => s.openingBaselineMinor, 'baseline', 4200000000)
          .having((s) => s.initialTransactionId, 'txId', 't-open'),
    ],
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'submit sin cuentas crea la deuda directamente y llega a saved',
    setUp: () => when(() => createDebt.call(any()))
        .thenAnswer((_) async => Right(buildDebt())),
    build: build,
    seed: () => const DebtFormState(
      status: DebtFormStatus.ready,
      name: 'Préstamo',
      amountMinor: 500000,
    ),
    act: (cubit) => cubit.submit(),
    expect: () => [
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.saving),
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.saved),
    ],
    verify: (_) => verify(() => createDebt.call(any())).called(1),
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'submit con monto y cuentas ofrece el registro inicial (item 2)',
    build: build,
    seed: () => DebtFormState(
      status: DebtFormStatus.ready,
      name: 'Préstamo',
      amountMinor: 500000,
      accounts: [account],
    ),
    act: (cubit) => cubit.submit(),
    expect: () => [
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.ready)
          .having((s) => s.prompt, 'prompt', isA<DebtChooseRegistroPrompt>()),
    ],
    verify: (_) {
      verifyNever(() => createDebt.call(any()));
      verifyNever(
        () => createWithOpening.call(
          draft: any(named: 'draft'),
          accountId: any(named: 'accountId'),
          date: any(named: 'date'),
        ),
      );
    },
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'chooseSoloDeuda crea la deuda sin movimiento',
    setUp: () => when(() => createDebt.call(any()))
        .thenAnswer((_) async => Right(buildDebt())),
    build: build,
    seed: () => DebtFormState(
      status: DebtFormStatus.ready,
      name: 'Préstamo',
      amountMinor: 500000,
      accounts: [account],
      prompt: const DebtChooseRegistroPrompt(),
    ),
    act: (cubit) => cubit.chooseSoloDeuda(),
    expect: () => [
      isA<DebtFormState>().having((s) => s.prompt, 'prompt', isNull),
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.saving),
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.saved),
    ],
    verify: (_) => verify(() => createDebt.call(any())).called(1),
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'createWithOpeningMovement crea deuda + desembolso y llega a saved',
    setUp: () => when(
      () => createWithOpening.call(
        draft: any(named: 'draft'),
        accountId: any(named: 'accountId'),
        date: any(named: 'date'),
      ),
    ).thenAnswer((_) async => Right(buildDebt())),
    build: build,
    seed: () => DebtFormState(
      status: DebtFormStatus.ready,
      name: 'Préstamo',
      amountMinor: 500000,
      accounts: [account],
      prompt: const DebtChooseRegistroPrompt(),
    ),
    act: (cubit) => cubit.createWithOpeningMovement('a1'),
    expect: () => [
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.saving)
          .having((s) => s.prompt, 'prompt', isNull),
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.saved),
    ],
    verify: (_) => verify(
      () => createWithOpening.call(
        draft: any(named: 'draft'),
        accountId: 'a1',
        date: any(named: 'date'),
      ),
    ).called(1),
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'submit con nombre inválido marca el campo (sin flash de saving)',
    build: build,
    seed: () => const DebtFormState(status: DebtFormStatus.ready),
    act: (cubit) => cubit.submit(),
    expect: () => [
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.ready)
          .having((s) => s.failedField, 'failedField', DebtDraft.fieldName),
    ],
    verify: (_) => verifyNever(() => createDebt.call(any())),
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'editar con registro y cambiar el saldo pide confirmar el registro (2b)',
    setUp: () => when(() => updateDebt.call(any()))
        .thenAnswer((_) async => Right(buildDebt())),
    build: build,
    seed: () => const DebtFormState(
      status: DebtFormStatus.ready,
      id: 'd1',
      name: 'Crédito',
      amountMinor: 200,
      openingBaselineMinor: 100,
      initialTransactionId: 't-open',
    ),
    act: (cubit) => cubit.submit(),
    expect: () => [
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.saving),
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.ready)
          .having(
            (s) => s.prompt,
            'prompt',
            isA<DebtConfirmUpdateRegistroPrompt>()
                .having((p) => p.fromMinor, 'from', 100)
                .having((p) => p.toMinor, 'to', 200),
          ),
    ],
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'confirmar el registro actualiza el movimiento y llega a saved (2b)',
    setUp: () {
      when(() => updateDebt.call(any()))
          .thenAnswer((_) async => Right(buildDebt()));
      when(
        () => updateInitialMovement.call(
          transactionId: any(named: 'transactionId'),
          amountMinor: any(named: 'amountMinor'),
          direction: any(named: 'direction'),
        ),
      ).thenAnswer((_) async => const Right(unit));
    },
    build: build,
    seed: () => const DebtFormState(
      status: DebtFormStatus.ready,
      id: 'd1',
      name: 'Crédito',
      amountMinor: 200,
      openingBaselineMinor: 100,
      initialTransactionId: 't-open',
    ),
    act: (cubit) async {
      await cubit.submit();
      await cubit.confirmUpdateRegistro();
    },
    verify: (_) {
      verify(
        () => updateInitialMovement.call(
          transactionId: 't-open',
          amountMinor: 200,
          direction: DebtDirection.iOwe,
        ),
      ).called(1);
    },
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'cancelar el registro no toca el movimiento y llega a saved (2b)',
    setUp: () => when(() => updateDebt.call(any()))
        .thenAnswer((_) async => Right(buildDebt())),
    build: build,
    seed: () => const DebtFormState(
      status: DebtFormStatus.ready,
      id: 'd1',
      name: 'Crédito',
      amountMinor: 200,
      openingBaselineMinor: 100,
      initialTransactionId: 't-open',
    ),
    act: (cubit) async {
      await cubit.submit();
      cubit.dismissUpdateRegistro();
    },
    verify: (_) {
      verifyNever(
        () => updateInitialMovement.call(
          transactionId: any(named: 'transactionId'),
          amountMinor: any(named: 'amountMinor'),
          direction: any(named: 'direction'),
        ),
      );
    },
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'editar con registro sin cambiar el saldo no pide confirmar (2b)',
    setUp: () => when(() => updateDebt.call(any()))
        .thenAnswer((_) async => Right(buildDebt())),
    build: build,
    seed: () => const DebtFormState(
      status: DebtFormStatus.ready,
      id: 'd1',
      name: 'Crédito',
      amountMinor: 100,
      openingBaselineMinor: 100,
      initialTransactionId: 't-open',
    ),
    act: (cubit) => cubit.submit(),
    expect: () => [
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.saving),
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.saved)
          .having((s) => s.prompt, 'prompt', isNull),
    ],
    verify: (_) => verifyNever(
      () => updateInitialMovement.call(
        transactionId: any(named: 'transactionId'),
        amountMinor: any(named: 'amountMinor'),
        direction: any(named: 'direction'),
      ),
    ),
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'delete borra lógicamente y llega a deleted',
    setUp: () => when(() => deleteDebt.call('d1'))
        .thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => const DebtFormState(status: DebtFormStatus.ready, id: 'd1'),
    act: (cubit) => cubit.delete(),
    expect: () => [
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.saving),
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.deleted),
    ],
    verify: (_) => verify(() => deleteDebt.call('d1')).called(1),
  );
}
