import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_detail.dart';
import 'package:billetudo/features/debts/domain/entities/debt_draft.dart';
import 'package:billetudo/features/debts/domain/usecases/create_debt.dart';
import 'package:billetudo/features/debts/domain/usecases/delete_debt.dart';
import 'package:billetudo/features/debts/domain/usecases/update_debt.dart';
import 'package:billetudo/features/debts/domain/usecases/watch_debt_detail.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_form_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_form_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debts_presentation_fixtures.dart';

class MockCreateDebt extends Mock implements CreateDebt {}

class MockUpdateDebt extends Mock implements UpdateDebt {}

class MockDeleteDebt extends Mock implements DeleteDebt {}

class MockWatchDebtDetail extends Mock implements WatchDebtDetail {}

void main() {
  late MockCreateDebt createDebt;
  late MockUpdateDebt updateDebt;
  late MockDeleteDebt deleteDebt;
  late MockWatchDebtDetail watchDebtDetail;

  setUpAll(() {
    registerFallbackValue(
      const DebtDraft(
        name: 'x',
        direction: DebtDirection.iOwe,
        principalMinor: 0,
        currency: 'COP',
      ),
    );
  });

  setUp(() {
    createDebt = MockCreateDebt();
    updateDebt = MockUpdateDebt();
    deleteDebt = MockDeleteDebt();
    watchDebtDetail = MockWatchDebtDetail();
  });

  DebtFormCubit build() =>
      DebtFormCubit(createDebt, updateDebt, deleteDebt, watchDebtDetail);

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
    skip: 1,
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
    'submit crea la deuda y llega a saved',
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
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'submit con nombre inválido marca el campo y vuelve a ready',
    setUp: () => when(() => createDebt.call(any())).thenAnswer(
      (_) async => const Left(
        ValidationFailure('a name is required', field: DebtDraft.fieldName),
      ),
    ),
    build: build,
    seed: () => const DebtFormState(status: DebtFormStatus.ready),
    act: (cubit) => cubit.submit(),
    expect: () => [
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.saving),
      isA<DebtFormState>()
          .having((s) => s.status, 'status', DebtFormStatus.ready)
          .having((s) => s.failedField, 'failedField', DebtDraft.fieldName),
    ],
  );

  blocTest<DebtFormCubit, DebtFormState>(
    'delete borra lógicamente y llega a deleted',
    setUp: () =>
        when(() => deleteDebt.call('d1')).thenAnswer((_) async => const Right(unit)),
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
