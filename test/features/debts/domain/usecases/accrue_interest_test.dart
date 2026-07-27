import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_accrual_context.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry_draft.dart';
import 'package:billetudo/features/debts/domain/services/debt_interest_calculator.dart';
import 'package:billetudo/features/debts/domain/usecases/accrue_interest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debt_repository_mock.dart';

void main() {
  late MockDebtRepository repository;
  late AccrueInterest usecase;

  setUpAll(registerDebtFallbacks);

  setUp(() {
    repository = MockDebtRepository();
    usecase = AccrueInterest(repository, const DebtInterestCalculator());
  });

  Debt autoDebt({int? rateBps = 3650, DateTime? closedAt}) => Debt(
        id: 'd1',
        name: 'Crédito',
        direction: DebtDirection.iOwe,
        principalMinor: 1000000,
        currency: 'COP',
        accrualMode: DebtAccrualMode.auto,
        interestRateBps: rateBps,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: 0,
        closedAt: closedAt,
      );

  DebtEntry anyEntry() => DebtEntry(
        id: 'e1',
        debtId: 'd1',
        kind: DebtEntryKind.interestAccrual,
        amountMinor: 1,
        entryDate: DateTime(2026),
        createdAt: DateTime(2026),
        updatedAt: 0,
      );

  test('posts a positive interest entry with the rate snapshot', () async {
    when(() => repository.getAccrualContext('d1')).thenAnswer(
      (_) async => Right(
        DebtAccrualContext(
          debt: autoDebt(),
          rawOutstandingMinor: 1000000,
          lastAccrualDate: DateTime(2026, 1, 1),
        ),
      ),
    );
    when(() => repository.addDebtEntry(any()))
        .thenAnswer((_) async => Right(anyEntry()));

    await usecase(debtId: 'd1', upTo: DateTime(2026, 1, 2)); // 1 day

    final captured =
        verify(() => repository.addDebtEntry(captureAny())).captured.single
            as DebtEntryDraft;
    expect(captured.kind, DebtEntryKind.interestAccrual);
    expect(captured.amountMinor, 1000); // 0.1% of 1,000,000 for one day
    expect(captured.rateBpsSnapshot, 3650);
  });

  test('is a no-op when no days elapsed', () async {
    when(() => repository.getAccrualContext('d1')).thenAnswer(
      (_) async => Right(
        DebtAccrualContext(
          debt: autoDebt(),
          rawOutstandingMinor: 1000000,
          lastAccrualDate: DateTime(2026, 1, 2),
        ),
      ),
    );

    final result = await usecase(debtId: 'd1', upTo: DateTime(2026, 1, 2));

    expect(result.getRight().toNullable(), isNull);
    verifyNever(() => repository.addDebtEntry(any()));
  });

  test('rejects a manual-mode debt', () async {
    when(() => repository.getAccrualContext('d1')).thenAnswer(
      (_) async => Right(
        DebtAccrualContext(
          debt: Debt(
            id: 'd1',
            name: 'Crédito',
            direction: DebtDirection.iOwe,
            principalMinor: 1000000,
            currency: 'COP',
            accrualMode: DebtAccrualMode.manual,
            interestRateBps: 3650,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: 0,
          ),
          rawOutstandingMinor: 1000000,
        ),
      ),
    );

    final result = await usecase(debtId: 'd1', upTo: DateTime(2026, 2, 1));

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.addDebtEntry(any()));
  });

  test('rejects auto mode without a rate', () async {
    when(() => repository.getAccrualContext('d1')).thenAnswer(
      (_) async => Right(
        DebtAccrualContext(
          debt: autoDebt(rateBps: null),
          rawOutstandingMinor: 1000000,
        ),
      ),
    );

    final result = await usecase(debtId: 'd1', upTo: DateTime(2026, 2, 1));

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('rejects accrual on a closed debt', () async {
    when(() => repository.getAccrualContext('d1')).thenAnswer(
      (_) async => Right(
        DebtAccrualContext(
          debt: autoDebt(closedAt: DateTime(2026, 1, 15)),
          rawOutstandingMinor: 1000000,
          lastAccrualDate: DateTime(2026, 1, 1),
        ),
      ),
    );

    final result = await usecase(debtId: 'd1', upTo: DateTime(2026, 1, 20));

    final failure = result.getLeft().toNullable();
    expect(failure, isA<ValidationFailure>());
    expect((failure! as ValidationFailure).field, 'closedAt');
    verifyNever(() => repository.addDebtEntry(any()));
  });
}
