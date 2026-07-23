import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/entities/debt_balance.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry_draft.dart';
import 'package:billetudo/features/debts/domain/usecases/update_debt_balance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debt_repository_mock.dart';

void main() {
  late MockDebtRepository repository;
  late UpdateDebtBalance usecase;

  setUpAll(registerDebtFallbacks);

  setUp(() {
    repository = MockDebtRepository();
    usecase = UpdateDebtBalance(repository);
  });

  DebtEntry anyEntry() => DebtEntry(
        id: 'e1',
        debtId: 'd1',
        kind: DebtEntryKind.manualAdjustment,
        amountMinor: 0,
        entryDate: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 6, 1),
        updatedAt: 0,
      );

  test('posts an adjustment that absorbs the diff vs the raw balance',
      () async {
    // Raw outstanding = 100000; the bank says 112000 -> +12000 adjustment.
    when(() => repository.getBalance('d1')).thenAnswer(
      (_) async => const Right(
        DebtBalance(
          principalMinor: 100000,
          totalIncreasesMinor: 100000,
          totalDecreasesMinor: 0,
          interestAccruedMinor: 0,
        ),
      ),
    );
    when(() => repository.addDebtEntry(any()))
        .thenAnswer((_) async => Right(anyEntry()));

    await usecase(
      debtId: 'd1',
      targetOutstandingMinor: 112000,
      date: DateTime(2026, 6, 1),
    );

    final captured =
        verify(() => repository.addDebtEntry(captureAny())).captured.single
            as DebtEntryDraft;
    expect(captured.kind, DebtEntryKind.manualAdjustment);
    expect(captured.amountMinor, 12000);
  });

  test('a downward reconciliation records a negative adjustment', () async {
    when(() => repository.getBalance('d1')).thenAnswer(
      (_) async => const Right(
        DebtBalance(
          principalMinor: 100000,
          totalIncreasesMinor: 100000,
          totalDecreasesMinor: 0,
          interestAccruedMinor: 0,
        ),
      ),
    );
    when(() => repository.addDebtEntry(any()))
        .thenAnswer((_) async => Right(anyEntry()));

    await usecase(
      debtId: 'd1',
      targetOutstandingMinor: 90000,
      date: DateTime(2026, 6, 1),
    );

    final captured =
        verify(() => repository.addDebtEntry(captureAny())).captured.single
            as DebtEntryDraft;
    expect(captured.amountMinor, -10000);
  });

  test('writes nothing when the figure already matches', () async {
    when(() => repository.getBalance('d1')).thenAnswer(
      (_) async => const Right(
        DebtBalance(
          principalMinor: 100000,
          totalIncreasesMinor: 100000,
          totalDecreasesMinor: 0,
          interestAccruedMinor: 0,
        ),
      ),
    );

    final result = await usecase(
      debtId: 'd1',
      targetOutstandingMinor: 100000,
      date: DateTime(2026, 6, 1),
    );

    expect(result.getRight().toNullable(), isNull);
    verifyNever(() => repository.addDebtEntry(any()));
  });

  test('rejects a negative target', () async {
    final result = await usecase(
      debtId: 'd1',
      targetOutstandingMinor: -1,
      date: DateTime(2026, 6, 1),
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.getBalance(any()));
  });
}
