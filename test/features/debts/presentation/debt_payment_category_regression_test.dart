import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/preferences/debt_payment_toggle_preference_datasource.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/debts/data/datasources/debts_local_datasource.dart';
import 'package:billetudo/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_draft.dart';
import 'package:billetudo/features/debts/domain/services/debt_balance_calculator.dart';
import 'package:billetudo/features/debts/domain/usecases/register_debt_cash_event.dart';
import 'package:billetudo/features/debts/domain/usecases/register_debt_ledger_event.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_payment_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_payment_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../accounts/account_fixtures.dart';

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockTogglePreference extends Mock
    implements DebtPaymentTogglePreferenceDatasource {}

/// Bug 5: reproduces the EXACT user flow (open the sheet, `addToAccount =
/// true`, pick an account, pick a category via `categorySelected`, submit)
/// against a real in-memory Drift DB end to end — `DebtPaymentCubit` ->
/// `RegisterDebtCashEvent` -> `DebtRepositoryImpl.registerCashEvent` -> the
/// `transactions` table — to prove (or disprove) that the abono's category
/// survives all the way to the persisted `Transaction`.
void main() {
  late db.AppDatabase database;
  late DebtRepositoryImpl repository;
  late MockWatchAccounts watchAccounts;
  late MockTogglePreference togglePreference;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    repository = DebtRepositoryImpl(
      DebtsLocalDatasource(database),
      const DebtBalanceCalculator(),
    );
    watchAccounts = MockWatchAccounts();
    togglePreference = MockTogglePreference();
  });

  tearDown(() => database.close());

  Future<db.Account> createAccount() =>
      database.into(database.accounts).insertReturning(
            db.AccountsCompanion.insert(
              name: 'Bancolombia',
              type: db.AccountType.bank,
              currency: 'COP',
            ),
          );

  Future<db.Category> createCategory() =>
      database.into(database.categories).insertReturning(
            db.CategoriesCompanion.insert(
              name: 'Pago de préstamos',
              kind: db.CategoryKind.expense,
            ),
          );

  test(
    'submit con addToAccount=true y categoría elegida persiste la '
    'Transaction con categoryId no nulo',
    () async {
      final account = await createAccount();
      final category = await createCategory();

      final debtResult = await repository.createDebt(
        const DebtDraft(
          name: 'Crédito carro',
          direction: DebtDirection.iOwe,
          principalMinor: 4200000,
          currency: 'COP',
        ),
      );
      final debt = debtResult.getRight().toNullable()!;

      final accounts = [
        buildAccountWithBalance(
          account: buildAccount(id: account.id, name: account.name),
          balanceMinor: 3450000,
        ),
      ];
      when(watchAccounts.call).thenAnswer((_) => Stream.value(Right(accounts)));
      when(() => togglePreference.readAddToAccount(any()))
          .thenAnswer((_) async => true);
      when(() => togglePreference.writeAddToAccount(
            debtId: any(named: 'debtId'),
            addToAccount: any(named: 'addToAccount'),
          )).thenAnswer((_) async {});

      final cubit = DebtPaymentCubit(
        RegisterDebtCashEvent(repository),
        RegisterDebtLedgerEvent(repository),
        watchAccounts,
        togglePreference,
      );
      addTearDown(cubit.close);

      await cubit.start(debt);
      expect(cubit.state.addToAccount, isTrue);

      cubit.amountChanged(150000);
      cubit.accountSelected(account.id);
      cubit.categorySelected(id: category.id, name: category.name);
      expect(cubit.state.categoryId, category.id);

      await cubit.submit();
      expect(cubit.state.status, DebtPaymentStatus.saved);

      final rows = await (database.select(database.transactions)
            ..where((t) => t.debtId.equals(debt.id)))
          .get();

      expect(rows, hasLength(1));
      expect(
        rows.single.categoryId,
        category.id,
        reason: 'the category picked in the abono sheet must survive to the '
            'persisted Transaction',
      );
    },
  );
}
