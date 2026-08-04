import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_cash_event.dart';
import 'package:billetudo/features/debts/domain/entities/debt_cash_event_draft.dart';
import 'package:billetudo/features/debts/domain/usecases/register_debt_cash_event.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debt_repository_mock.dart';

void main() {
  late MockDebtRepository repository;
  late RegisterDebtCashEvent usecase;

  setUpAll(registerDebtFallbacks);

  setUp(() {
    repository = MockDebtRepository();
    usecase = RegisterDebtCashEvent(repository);
  });

  Debt debt(DebtDirection direction, {DateTime? closedAt}) => Debt(
        id: 'd1',
        name: 'Deuda',
        direction: direction,
        principalMinor: 0,
        currency: 'COP',
        accrualMode: DebtAccrualMode.manual,
        createdAt: DateTime(2026),
        updatedAt: 0,
        closedAt: closedAt,
      );

  void stubRegisterCashEvent() => when(
        () => repository.registerCashEvent(
          debtId: any(named: 'debtId'),
          accountId: any(named: 'accountId'),
          amountMinor: any(named: 'amountMinor'),
          type: any(named: 'type'),
          currency: any(named: 'currency'),
          date: any(named: 'date'),
          note: any(named: 'note'),
          categoryId: any(named: 'categoryId'),
          countsInBudget: any(named: 'countsInBudget'),
        ),
      ).thenAnswer((_) async => const Right(unit));

  test('an iOwe abono resolves to an expense in the debts currency', () async {
    when(() => repository.getDebt('d1'))
        .thenAnswer((_) async => Right(debt(DebtDirection.iOwe)));
    stubRegisterCashEvent();

    await usecase(
      DebtCashEventDraft(
        debtId: 'd1',
        accountId: 'a1',
        amountMinor: 20000,
        kind: DebtCashEventKind.payment,
        date: DateTime(2026, 5, 1),
      ),
    );

    verify(
      () => repository.registerCashEvent(
        debtId: 'd1',
        accountId: 'a1',
        amountMinor: 20000,
        type: TransactionType.expense,
        currency: 'COP',
        date: DateTime(2026, 5, 1),
        note: null,
        categoryId: null,
        countsInBudget: false,
      ),
    ).called(1);
  });

  test('an owedToMe disbursement resolves to an expense (I lent)', () async {
    when(() => repository.getDebt('d1'))
        .thenAnswer((_) async => Right(debt(DebtDirection.owedToMe)));
    stubRegisterCashEvent();

    await usecase(
      DebtCashEventDraft(
        debtId: 'd1',
        accountId: 'a1',
        amountMinor: 50000,
        kind: DebtCashEventKind.disbursement,
        date: DateTime(2026, 5, 1),
      ),
    );

    verify(
      () => repository.registerCashEvent(
        debtId: 'd1',
        accountId: 'a1',
        amountMinor: 50000,
        type: TransactionType.expense,
        currency: 'COP',
        date: DateTime(2026, 5, 1),
        note: null,
        categoryId: null,
        countsInBudget: false,
      ),
    ).called(1);
  });

  test('an iOwe disbursement resolves to income, not presupuestable',
      () async {
    when(() => repository.getDebt('d1'))
        .thenAnswer((_) async => Right(debt(DebtDirection.iOwe)));
    stubRegisterCashEvent();

    await usecase(
      DebtCashEventDraft(
        debtId: 'd1',
        accountId: 'a1',
        amountMinor: 50000,
        kind: DebtCashEventKind.disbursement,
        date: DateTime(2026, 5, 1),
      ),
    );

    verify(
      () => repository.registerCashEvent(
        debtId: 'd1',
        accountId: 'a1',
        amountMinor: 50000,
        type: TransactionType.income,
        currency: 'COP',
        date: DateTime(2026, 5, 1),
        note: null,
        categoryId: null,
        countsInBudget: false,
      ),
    ).called(1);
  });

  test(
      'criterion 1: an owedToMe payment (repago recibido) resolves to income '
      'with countsInBudget = true automatically', () async {
    when(() => repository.getDebt('d1'))
        .thenAnswer((_) async => Right(debt(DebtDirection.owedToMe)));
    stubRegisterCashEvent();

    await usecase(
      DebtCashEventDraft(
        debtId: 'd1',
        accountId: 'a1',
        amountMinor: 10000,
        kind: DebtCashEventKind.payment,
        date: DateTime(2026, 5, 1),
      ),
    );

    verify(
      () => repository.registerCashEvent(
        debtId: 'd1',
        accountId: 'a1',
        amountMinor: 10000,
        type: TransactionType.income,
        currency: 'COP',
        date: DateTime(2026, 5, 1),
        note: null,
        categoryId: null,
        countsInBudget: true,
      ),
    ).called(1);
  });

  test('rejects a non-positive amount before reading the debt', () async {
    final result = await usecase(
      DebtCashEventDraft(
        debtId: 'd1',
        accountId: 'a1',
        amountMinor: 0,
        kind: DebtCashEventKind.payment,
        date: DateTime(2026, 5, 1),
      ),
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.getDebt(any()));
  });

  test('rejects a cash event on a closed debt', () async {
    when(() => repository.getDebt('d1')).thenAnswer(
      (_) async => Right(
        debt(DebtDirection.iOwe, closedAt: DateTime(2026, 6, 1)),
      ),
    );

    final result = await usecase(
      DebtCashEventDraft(
        debtId: 'd1',
        accountId: 'a1',
        amountMinor: 20000,
        kind: DebtCashEventKind.payment,
        date: DateTime(2026, 5, 1),
      ),
    );

    final failure = result.getLeft().toNullable();
    expect(failure, isA<ValidationFailure>());
    expect((failure! as ValidationFailure).field, 'closedAt');
    verifyNever(
      () => repository.registerCashEvent(
        debtId: any(named: 'debtId'),
        accountId: any(named: 'accountId'),
        amountMinor: any(named: 'amountMinor'),
        type: any(named: 'type'),
        currency: any(named: 'currency'),
        date: any(named: 'date'),
        note: any(named: 'note'),
        categoryId: any(named: 'categoryId'),
        countsInBudget: any(named: 'countsInBudget'),
      ),
    );
  });
}
