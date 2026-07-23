import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/entities/debt_cash_event.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry_draft.dart';
import 'package:billetudo/features/debts/domain/usecases/register_debt_ledger_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debt_repository_mock.dart';

void main() {
  late MockDebtRepository repository;
  late RegisterDebtLedgerEvent usecase;

  setUpAll(registerDebtFallbacks);

  setUp(() {
    repository = MockDebtRepository();
    usecase = RegisterDebtLedgerEvent(repository);
  });

  DebtEntry anyEntry() => DebtEntry(
        id: 'e1',
        debtId: 'd1',
        kind: DebtEntryKind.payment,
        amountMinor: -1,
        entryDate: DateTime(2026),
        createdAt: DateTime(2026),
        updatedAt: 0,
      );

  test('a cash-less abono is stored as a negative payment entry', () async {
    when(() => repository.addDebtEntry(any()))
        .thenAnswer((_) async => Right(anyEntry()));

    await usecase(
      debtId: 'd1',
      kind: DebtCashEventKind.payment,
      amountMinor: 15000,
      date: DateTime(2026, 4, 1),
    );

    final captured =
        verify(() => repository.addDebtEntry(captureAny())).captured.single
            as DebtEntryDraft;
    expect(captured.kind, DebtEntryKind.payment);
    expect(captured.amountMinor, -15000);
  });

  test('a cash-less desembolso is stored as a positive disbursement entry',
      () async {
    when(() => repository.addDebtEntry(any()))
        .thenAnswer((_) async => Right(anyEntry()));

    await usecase(
      debtId: 'd1',
      kind: DebtCashEventKind.disbursement,
      amountMinor: 40000,
      date: DateTime(2026, 4, 1),
    );

    final captured =
        verify(() => repository.addDebtEntry(captureAny())).captured.single
            as DebtEntryDraft;
    expect(captured.kind, DebtEntryKind.disbursement);
    expect(captured.amountMinor, 40000);
  });

  test('rejects a non-positive magnitude', () async {
    final result = await usecase(
      debtId: 'd1',
      kind: DebtCashEventKind.payment,
      amountMinor: 0,
      date: DateTime(2026, 4, 1),
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.addDebtEntry(any()));
  });
}
