import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/entities/debt_balance.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry_draft.dart';
import 'package:billetudo/features/debts/domain/services/debt_balance_calculator.dart';
import 'package:billetudo/features/debts/domain/usecases/update_debt_balance.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../debt_test_fixtures.dart';
import 'debt_repository_mock.dart';

void main() {
  late MockDebtRepository repository;
  late UpdateDebtBalance usecase;

  setUpAll(registerDebtFallbacks);

  setUp(() {
    repository = MockDebtRepository();
    usecase = UpdateDebtBalance(repository);
    when(() => repository.getDebt('d1'))
        .thenAnswer((_) async => Right(buildDebt()));
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
          displayTotalMinor: 100000,
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

    final captured = verify(() => repository.addDebtEntry(captureAny()))
        .captured
        .single as DebtEntryDraft;
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
          displayTotalMinor: 100000,
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

    final captured = verify(() => repository.addDebtEntry(captureAny()))
        .captured
        .single as DebtEntryDraft;
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
          displayTotalMinor: 100000,
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

  test(
    'the diff it writes, once fed back into the calculator, never moves '
    'displayTotalMinor — a reconciliation only ever corrects what is pending',
    () async {
      // Opening 98M, a 2M abono before reconciling: raw outstanding is 96M.
      // The user reconciles to 110M -> diff = +14M.
      const debt98mOpen = 98000000;
      final debt = buildDebt(
        principalMinor: debt98mOpen,
        createdAt: DateTime(2026, 1, 1),
        startDate: DateTime(2026, 1, 1),
      );
      when(() => repository.getDebt('d1')).thenAnswer((_) async => Right(debt));

      const calc = DebtBalanceCalculator();
      final beforeReconciliation = calc.calculate(
        debt: debt,
        entries: const [],
        cashEvents: [
          buildCashEvent(
            transactionId: 't-abono',
            type: TransactionType.expense,
            amountMinor: 2000000,
            date: DateTime(2026, 2, 1),
          ),
        ],
      );
      expect(beforeReconciliation.rawOutstandingMinor, 96000000);

      when(() => repository.getBalance('d1'))
          .thenAnswer((_) async => Right(beforeReconciliation));
      when(() => repository.addDebtEntry(any()))
          .thenAnswer((_) async => Right(anyEntry()));

      await usecase(
        debtId: 'd1',
        targetOutstandingMinor: 110000000,
        date: DateTime(2026, 3, 1),
      );

      final captured = verify(() => repository.addDebtEntry(captureAny()))
          .captured
          .single as DebtEntryDraft;
      expect(captured.amountMinor, 14000000);

      final afterReconciliation = calc.calculate(
        debt: debt,
        entries: [
          buildEntry(
            id: 'reconciliation',
            kind: captured.kind,
            amountMinor: captured.amountMinor,
            entryDate: captured.entryDate,
          ),
        ],
        cashEvents: [
          buildCashEvent(
            transactionId: 't-abono',
            type: TransactionType.expense,
            amountMinor: 2000000,
            date: DateTime(2026, 2, 1),
          ),
        ],
      );

      expect(afterReconciliation.outstandingMinor, 110000000);
      // The reconciliation is an upward correction (+14M), but it is not a
      // disbursement — it only corrects what is pending. displayTotalMinor
      // stays at the original 98M principal, never grows with it (see
      // debt_balance_calculator_test.dart for the reverted "new debt
      // discovered" behavior this replaces).
      expect(afterReconciliation.displayTotalMinor, 98000000);
    },
  );

  test('rejects a reconciliation on a closed debt', () async {
    when(() => repository.getDebt('d1')).thenAnswer(
      (_) async => Right(buildDebt(closedAt: DateTime(2026, 6, 1))),
    );

    final result = await usecase(
      debtId: 'd1',
      targetOutstandingMinor: 112000,
      date: DateTime(2026, 6, 1),
    );

    final failure = result.getLeft().toNullable();
    expect(failure, isA<ValidationFailure>());
    expect((failure! as ValidationFailure).field, 'closedAt');
    verifyNever(() => repository.getBalance(any()));
    verifyNever(() => repository.addDebtEntry(any()));
  });
}
