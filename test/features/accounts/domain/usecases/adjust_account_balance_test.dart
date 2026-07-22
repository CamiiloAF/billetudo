import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance_adjustment.dart';
import 'package:billetudo/features/accounts/domain/entities/account_draft.dart';
import 'package:billetudo/features/accounts/domain/usecases/adjust_account_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/update_account.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:billetudo/features/transactions/domain/usecases/create_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../account_fixtures.dart';

class MockCreateTransaction extends Mock implements CreateTransaction {}

class MockUpdateAccount extends Mock implements UpdateAccount {}

void main() {
  late MockCreateTransaction createTransaction;
  late MockUpdateAccount updateAccount;
  late AdjustAccountBalance adjust;

  setUpAll(() {
    registerFallbackValue(
      TransactionDraft(
        accountId: 'acc-1',
        amountMinor: 1,
        currency: 'COP',
        type: TransactionType.income,
        date: DateTime(2026),
      ),
    );
    registerFallbackValue(
      const AccountDraft(name: 'x', type: AccountType.bank, currency: 'COP'),
    );
  });

  setUp(() {
    createTransaction = MockCreateTransaction();
    updateAccount = MockUpdateAccount();
    adjust = AdjustAccountBalance(createTransaction, updateAccount);

    when(() => createTransaction(any())).thenAnswer(
      (_) async => Right(
        buildAccountTransaction(),
      ),
    );
    when(() => updateAccount(any(), confirmed: any(named: 'confirmed')))
        .thenAnswer((_) async => Right(buildAccount()));
  });

  TransactionDraft capturedTx() =>
      verify(() => createTransaction(captureAny())).captured.single
          as TransactionDraft;

  AccountDraft capturedAccountDraft() => verify(
        () => updateAccount(captureAny(), confirmed: any(named: 'confirmed')),
      ).captured.single as AccountDraft;

  final now = DateTime(2026, 7, 21, 9);

  group('registrar ajuste (movimiento)', () {
    test('subir el saldo crea un ingreso en "Otros ingresos" con la nota',
        () async {
      final result = await adjust(
        account: buildAccount(initialBalanceMinor: 0),
        currentBalanceMinor: 100000,
        newDisplayedBalanceMinor: 150000,
        mode: BalanceAdjustmentMode.registerMovement,
        note: 'Ajuste de saldo',
        now: now,
      );

      expect(result.isRight(), isTrue);
      final draft = capturedTx();
      expect(draft.type, TransactionType.income);
      expect(draft.amountMinor, 50000);
      expect(draft.accountId, 'acc-1');
      expect(draft.categoryId, AdjustAccountBalance.otherIncomeCategoryId);
      expect(draft.categoryKind, CategoryKind.income);
      expect(draft.note, 'Ajuste de saldo');
      // El flag sigue presente como respaldo defensivo.
      expect(draft.isBalanceAdjustment, isTrue);
      expect(draft.source, TransactionSource.manual);
      expect(draft.date, now);
      // No toca el saldo inicial.
      verifyNever(
        () => updateAccount(any(), confirmed: any(named: 'confirmed')),
      );
    });

    test('bajar el saldo crea un gasto en "Otros gastos"', () async {
      await adjust(
        account: buildAccount(),
        currentBalanceMinor: 150000,
        newDisplayedBalanceMinor: 100000,
        mode: BalanceAdjustmentMode.registerMovement,
        note: 'Ajuste de saldo',
        now: now,
      );

      final draft = capturedTx();
      expect(draft.type, TransactionType.expense);
      expect(draft.amountMinor, 50000);
      expect(draft.categoryId, AdjustAccountBalance.otherExpenseCategoryId);
      expect(draft.categoryKind, CategoryKind.expense);
      expect(draft.note, 'Ajuste de saldo');
    });

    test('tarjeta: subir la deuda crea un gasto en "Otros gastos"', () async {
      // Deuda actual $1.000 -> saldo real -100000. Nueva deuda $1.500.
      await adjust(
        account: buildCard(creditLimitMinor: 300000000),
        currentBalanceMinor: -100000,
        newDisplayedBalanceMinor: 150000,
        mode: BalanceAdjustmentMode.registerMovement,
        note: 'Ajuste de saldo',
        now: now,
      );

      final draft = capturedTx();
      expect(draft.type, TransactionType.expense);
      expect(draft.amountMinor, 50000);
      expect(draft.categoryId, AdjustAccountBalance.otherExpenseCategoryId);
      expect(draft.categoryKind, CategoryKind.expense);
    });

    test('tarjeta: bajar la deuda crea un ingreso en "Otros ingresos"',
        () async {
      await adjust(
        account: buildCard(creditLimitMinor: 300000000),
        currentBalanceMinor: -100000,
        newDisplayedBalanceMinor: 50000,
        mode: BalanceAdjustmentMode.registerMovement,
        note: 'Ajuste de saldo',
        now: now,
      );

      final draft = capturedTx();
      expect(draft.type, TransactionType.income);
      expect(draft.amountMinor, 50000);
      expect(draft.categoryId, AdjustAccountBalance.otherIncomeCategoryId);
      expect(draft.categoryKind, CategoryKind.income);
    });
  });

  group('corregir saldo inicial', () {
    test('corre el saldo inicial por la diferencia, sin crear movimiento',
        () async {
      final result = await adjust(
        account: buildAccount(initialBalanceMinor: 500000),
        currentBalanceMinor: 218000000,
        newDisplayedBalanceMinor: 250000000,
        mode: BalanceAdjustmentMode.correctInitial,
        now: now,
      );

      expect(result.isRight(), isTrue);
      final draft = capturedAccountDraft();
      expect(draft.initialBalanceMinor, 500000 + 32000000);
      verifyNever(() => createTransaction(any()));
    });

    test('tarjeta: el nuevo saldo inicial queda negativo (deuda)', () async {
      await adjust(
        account: buildCard(
          creditLimitMinor: 300000000,
          initialBalanceMinor: -100000,
        ),
        currentBalanceMinor: -100000,
        newDisplayedBalanceMinor: 150000,
        mode: BalanceAdjustmentMode.correctInitial,
        now: now,
      );

      final draft = capturedAccountDraft();
      expect(draft.initialBalanceMinor, -150000);
    });
  });

  test('sin diferencia es un no-op exitoso: no escribe nada', () async {
    final result = await adjust(
      account: buildAccount(),
      currentBalanceMinor: 100000,
      newDisplayedBalanceMinor: 100000,
      mode: BalanceAdjustmentMode.registerMovement,
      now: now,
    );

    expect(result.isRight(), isTrue);
    verifyNever(() => createTransaction(any()));
    verifyNever(
      () => updateAccount(any(), confirmed: any(named: 'confirmed')),
    );
  });
}

Transaction buildAccountTransaction() => Transaction(
      id: 'tx-1',
      accountId: 'acc-1',
      amountMinor: 50000,
      currency: 'COP',
      type: TransactionType.income,
      date: DateTime(2026, 7, 21),
      source: TransactionSource.manual,
      createdAt: DateTime(2026, 7, 21),
      updatedAt: 0,
    );
