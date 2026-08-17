import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry.dart';
import 'package:billetudo/features/debts/domain/usecases/delete_debt_entry.dart';
import 'package:billetudo/features/debts/domain/usecases/update_debt_entry.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_entry_edit_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_entry_edit_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUpdateDebtEntry extends Mock implements UpdateDebtEntry {}

class MockDeleteDebtEntry extends Mock implements DeleteDebtEntry {}

void main() {
  late MockUpdateDebtEntry updateDebtEntry;
  late MockDeleteDebtEntry deleteDebtEntry;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    updateDebtEntry = MockUpdateDebtEntry();
    deleteDebtEntry = MockDeleteDebtEntry();
  });

  DebtEntry entryOf({
    DebtEntryKind kind = DebtEntryKind.payment,
    int amountMinor = -15000,
    String? note,
  }) =>
      DebtEntry(
        id: 'e1',
        debtId: 'd1',
        kind: kind,
        amountMinor: amountMinor,
        entryDate: DateTime(2026, 3, 1),
        note: note,
        createdAt: DateTime(2026, 3, 1),
        updatedAt: 0,
      );

  DebtEntryEditCubit build() =>
      DebtEntryEditCubit(updateDebtEntry, deleteDebtEntry);

  blocTest<DebtEntryEditCubit, DebtEntryEditState>(
    'start seeds a positive amount magnitude from a signed entry, and the '
    'running balance',
    build: build,
    act: (cubit) => cubit.start(
      entryOf(amountMinor: -15000, note: 'Cuota'),
      runningMinor: 250000,
    ),
    expect: () => [
      isA<DebtEntryEditState>()
          .having((s) => s.amountMinor, 'amountMinor', 15000)
          .having((s) => s.note, 'note', 'Cuota')
          .having((s) => s.runningMinor, 'runningMinor', 250000),
    ],
  );

  blocTest<DebtEntryEditCubit, DebtEntryEditState>(
    'an interest accrual is not editable',
    build: build,
    act: (cubit) => cubit.start(
      entryOf(kind: DebtEntryKind.interestAccrual, amountMinor: 3600),
      runningMinor: 250000,
    ),
    expect: () => [
      isA<DebtEntryEditState>().having((s) => s.editable, 'editable', false),
    ],
  );

  blocTest<DebtEntryEditCubit, DebtEntryEditState>(
    'a payment/desembolso/ajuste is editable',
    build: build,
    act: (cubit) => cubit.start(entryOf(), runningMinor: 250000),
    expect: () => [
      isA<DebtEntryEditState>().having((s) => s.editable, 'editable', true),
    ],
  );

  blocTest<DebtEntryEditCubit, DebtEntryEditState>(
    'a successful submit fires saved',
    setUp: () => when(
      () => updateDebtEntry.call(
        id: any(named: 'id'),
        magnitudeMinor: any(named: 'magnitudeMinor'),
        entryDate: any(named: 'entryDate'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Right(entryOf(amountMinor: -20000))),
    build: build,
    act: (cubit) async {
      cubit.start(entryOf(), runningMinor: 250000);
      cubit.amountChanged(20000);
      await cubit.submit();
    },
    skip: 2,
    expect: () => [
      isA<DebtEntryEditState>()
          .having((s) => s.status, 'status', DebtEntryEditStatus.saving),
      isA<DebtEntryEditState>()
          .having((s) => s.status, 'status', DebtEntryEditStatus.saved),
    ],
    verify: (_) => verify(
      () => updateDebtEntry.call(
        id: 'e1',
        magnitudeMinor: 20000,
        entryDate: DateTime(2026, 3, 1),
        note: null,
      ),
    ).called(1),
  );

  blocTest<DebtEntryEditCubit, DebtEntryEditState>(
    'a failed submit returns to ready with the failure set',
    setUp: () => when(
      () => updateDebtEntry.call(
        id: any(named: 'id'),
        magnitudeMinor: any(named: 'magnitudeMinor'),
        entryDate: any(named: 'entryDate'),
        note: any(named: 'note'),
      ),
    ).thenAnswer(
      (_) async =>
          const Left(ValidationFailure('an interest accrual cannot be edited')),
    ),
    build: build,
    act: (cubit) async {
      cubit.start(entryOf(), runningMinor: 250000);
      await cubit.submit();
    },
    skip: 1,
    expect: () => [
      isA<DebtEntryEditState>()
          .having((s) => s.status, 'status', DebtEntryEditStatus.saving),
      isA<DebtEntryEditState>()
          .having((s) => s.status, 'status', DebtEntryEditStatus.ready)
          .having((s) => s.failure, 'failure', isA<ValidationFailure>()),
    ],
  );

  blocTest<DebtEntryEditCubit, DebtEntryEditState>(
    'submit is a no-op with a zero amount',
    build: build,
    act: (cubit) async {
      cubit.start(entryOf(), runningMinor: 250000);
      cubit.amountChanged(0);
      await cubit.submit();
    },
    skip: 2,
    expect: () => <DebtEntryEditState>[],
    verify: (_) => verifyNever(
      () => updateDebtEntry.call(
        id: any(named: 'id'),
        magnitudeMinor: any(named: 'magnitudeMinor'),
        entryDate: any(named: 'entryDate'),
        note: any(named: 'note'),
      ),
    ),
  );

  blocTest<DebtEntryEditCubit, DebtEntryEditState>(
    'a successful delete fires saved, for any kind including an interest '
    'accrual',
    setUp: () => when(() => deleteDebtEntry.call(any()))
        .thenAnswer((_) async => const Right(unit)),
    build: build,
    act: (cubit) async {
      cubit.start(
        entryOf(kind: DebtEntryKind.interestAccrual, amountMinor: 3600),
        runningMinor: 250000,
      );
      await cubit.delete();
    },
    skip: 1,
    expect: () => [
      isA<DebtEntryEditState>()
          .having((s) => s.status, 'status', DebtEntryEditStatus.deleting),
      isA<DebtEntryEditState>()
          .having((s) => s.status, 'status', DebtEntryEditStatus.saved),
    ],
    verify: (_) => verify(() => deleteDebtEntry.call('e1')).called(1),
  );

  blocTest<DebtEntryEditCubit, DebtEntryEditState>(
    'a failed delete returns to ready with the failure set',
    setUp: () => when(() => deleteDebtEntry.call(any())).thenAnswer(
      (_) async => const Left(ValidationFailure('boom')),
    ),
    build: build,
    act: (cubit) async {
      cubit.start(entryOf(), runningMinor: 250000);
      await cubit.delete();
    },
    skip: 1,
    expect: () => [
      isA<DebtEntryEditState>()
          .having((s) => s.status, 'status', DebtEntryEditStatus.deleting),
      isA<DebtEntryEditState>()
          .having((s) => s.status, 'status', DebtEntryEditStatus.ready)
          .having((s) => s.failure, 'failure', isA<ValidationFailure>()),
    ],
  );
}
