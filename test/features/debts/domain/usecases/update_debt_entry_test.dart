import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry.dart';
import 'package:billetudo/features/debts/domain/usecases/update_debt_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debt_repository_mock.dart';

void main() {
  late MockDebtRepository repository;
  late UpdateDebtEntry usecase;

  setUpAll(registerDebtFallbacks);

  setUp(() {
    repository = MockDebtRepository();
    usecase = UpdateDebtEntry(repository);
  });

  DebtEntry entryOf({
    required DebtEntryKind kind,
    required int amountMinor,
  }) =>
      DebtEntry(
        id: 'e1',
        debtId: 'd1',
        kind: kind,
        amountMinor: amountMinor,
        entryDate: DateTime(2026, 3, 1),
        createdAt: DateTime(2026, 3, 1),
        updatedAt: 0,
      );

  test('rejects a zero or negative magnitude before reading the entry',
      () async {
    final result = await usecase(
      id: 'e1',
      magnitudeMinor: 0,
      entryDate: DateTime(2026, 4, 1),
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.getDebtEntry(any()));
  });

  test('rejects editing an interestAccrual entry', () async {
    when(() => repository.getDebtEntry('e1')).thenAnswer(
      (_) async => Right(
        entryOf(kind: DebtEntryKind.interestAccrual, amountMinor: 5000),
      ),
    );

    final result = await usecase(
      id: 'e1',
      magnitudeMinor: 6000,
      entryDate: DateTime(2026, 4, 1),
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.updateDebtEntry(
          id: any(named: 'id'),
          amountMinor: any(named: 'amountMinor'),
          entryDate: any(named: 'entryDate'),
          note: any(named: 'note'),
        ));
  });

  test('preserves the negative sign of a payment entry', () async {
    when(() => repository.getDebtEntry('e1')).thenAnswer(
      (_) async => Right(entryOf(kind: DebtEntryKind.payment, amountMinor: -15000)),
    );
    when(
      () => repository.updateDebtEntry(
        id: any(named: 'id'),
        amountMinor: any(named: 'amountMinor'),
        entryDate: any(named: 'entryDate'),
        note: any(named: 'note'),
      ),
    ).thenAnswer(
      (_) async =>
          Right(entryOf(kind: DebtEntryKind.payment, amountMinor: -20000)),
    );

    await usecase(id: 'e1', magnitudeMinor: 20000, entryDate: DateTime(2026, 4, 1));

    verify(
      () => repository.updateDebtEntry(
        id: 'e1',
        amountMinor: -20000,
        entryDate: DateTime(2026, 4, 1),
        note: null,
      ),
    ).called(1);
  });

  test('preserves the positive sign of a disbursement entry', () async {
    when(() => repository.getDebtEntry('e1')).thenAnswer(
      (_) async =>
          Right(entryOf(kind: DebtEntryKind.disbursement, amountMinor: 15000)),
    );
    when(
      () => repository.updateDebtEntry(
        id: any(named: 'id'),
        amountMinor: any(named: 'amountMinor'),
        entryDate: any(named: 'entryDate'),
        note: any(named: 'note'),
      ),
    ).thenAnswer(
      (_) async =>
          Right(entryOf(kind: DebtEntryKind.disbursement, amountMinor: 20000)),
    );

    await usecase(id: 'e1', magnitudeMinor: 20000, entryDate: DateTime(2026, 4, 1));

    verify(
      () => repository.updateDebtEntry(
        id: 'e1',
        amountMinor: 20000,
        entryDate: DateTime(2026, 4, 1),
        note: null,
      ),
    ).called(1);
  });

  test(
      'a manual adjustment keeps its own sign even when it was originally '
      'negative', () async {
    when(() => repository.getDebtEntry('e1')).thenAnswer(
      (_) async =>
          Right(entryOf(kind: DebtEntryKind.manualAdjustment, amountMinor: -18000)),
    );
    when(
      () => repository.updateDebtEntry(
        id: any(named: 'id'),
        amountMinor: any(named: 'amountMinor'),
        entryDate: any(named: 'entryDate'),
        note: any(named: 'note'),
      ),
    ).thenAnswer(
      (_) async => Right(
        entryOf(kind: DebtEntryKind.manualAdjustment, amountMinor: -12000),
      ),
    );

    await usecase(id: 'e1', magnitudeMinor: 12000, entryDate: DateTime(2026, 4, 1));

    verify(
      () => repository.updateDebtEntry(
        id: 'e1',
        amountMinor: -12000,
        entryDate: DateTime(2026, 4, 1),
        note: null,
      ),
    ).called(1);
  });

  test(
      'a manual adjustment keeps its own sign even when it was originally '
      'positive', () async {
    when(() => repository.getDebtEntry('e1')).thenAnswer(
      (_) async =>
          Right(entryOf(kind: DebtEntryKind.manualAdjustment, amountMinor: 18000)),
    );
    when(
      () => repository.updateDebtEntry(
        id: any(named: 'id'),
        amountMinor: any(named: 'amountMinor'),
        entryDate: any(named: 'entryDate'),
        note: any(named: 'note'),
      ),
    ).thenAnswer(
      (_) async => Right(
        entryOf(kind: DebtEntryKind.manualAdjustment, amountMinor: 12000),
      ),
    );

    await usecase(id: 'e1', magnitudeMinor: 12000, entryDate: DateTime(2026, 4, 1));

    verify(
      () => repository.updateDebtEntry(
        id: 'e1',
        amountMinor: 12000,
        entryDate: DateTime(2026, 4, 1),
        note: null,
      ),
    ).called(1);
  });

  test('passes the note through unmodified to the repository', () async {
    when(() => repository.getDebtEntry('e1')).thenAnswer(
      (_) async => Right(entryOf(kind: DebtEntryKind.payment, amountMinor: -15000)),
    );
    when(
      () => repository.updateDebtEntry(
        id: any(named: 'id'),
        amountMinor: any(named: 'amountMinor'),
        entryDate: any(named: 'entryDate'),
        note: any(named: 'note'),
      ),
    ).thenAnswer(
      (_) async =>
          Right(entryOf(kind: DebtEntryKind.payment, amountMinor: -15000)),
    );

    await usecase(
      id: 'e1',
      magnitudeMinor: 15000,
      entryDate: DateTime(2026, 4, 1),
      note: 'Cuota de marzo',
    );

    verify(
      () => repository.updateDebtEntry(
        id: 'e1',
        amountMinor: -15000,
        entryDate: DateTime(2026, 4, 1),
        note: 'Cuota de marzo',
      ),
    ).called(1);
  });

  test('propagates a getDebtEntry NotFoundFailure', () async {
    when(() => repository.getDebtEntry('missing')).thenAnswer(
      (_) async => const Left(NotFoundFailure('debt entry not found')),
    );

    final result = await usecase(
      id: 'missing',
      magnitudeMinor: 5000,
      entryDate: DateTime(2026, 4, 1),
    );

    expect(result.isLeft(), isTrue);
  });
}
