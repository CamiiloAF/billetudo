import 'package:billetudo/core/database/app_database.dart' hide BudgetPeriod;
import 'package:billetudo/features/budgets/data/datasources/budgets_local_datasource.dart';
import 'package:billetudo/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart'
    show BudgetPeriod;
import 'package:billetudo/features/budgets/domain/entities/budget_draft.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/domain/services/budget_category_scope_resolver.dart';
import 'package:billetudo/features/budgets/domain/services/budget_progress_calculator.dart';
import 'package:billetudo/features/budgets/domain/services/zero_based_summary_calculator.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/project_upcoming_occurrences.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// B-3 — transferencia presupuestable
/// (`docs/plan-cuentas-tipos-y-transferencias-presupuestables.md` §3):
/// `BudgetsLocalDatasource.watchExpenses()` folds in a `type = transfer`
/// transaction marked `countsInBudget = true` as an **origin-side** expense
/// row, so it flows through `BudgetProgressCalculator`'s existing
/// account-scope matching exactly like a plain expense — no new scope
/// mechanism. Exercised at the repository level (real in-memory Drift, same
/// pattern as `budget_repository_impl_scheduled_test.dart`) because the
/// scope match itself lives one layer above the datasource.
void main() {
  late AppDatabase database;
  late BudgetRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = BudgetRepositoryImpl(
      BudgetsLocalDatasource(database),
      const BudgetProgressCalculator(),
      const ZeroBasedSummaryCalculator(),
      const ProjectUpcomingOccurrences(),
      const BudgetCategoryScopeResolver(),
    );
  });

  tearDown(() async => database.close());

  final now = DateTime.now();
  final anchor = DateTime(now.year, now.month, 1);

  Future<Account> createAccount(String name) =>
      database.into(database.accounts).insertReturning(
            AccountsCompanion.insert(
              name: name,
              type: AccountType.bank,
              currency: 'COP',
            ),
          );

  Future<Category> createExpenseCategory(String name) =>
      database.into(database.categories).insertReturning(
            CategoriesCompanion.insert(name: name, kind: CategoryKind.expense),
          );

  Future<String> createBudgetScopedTo(Set<String> accountIds) async {
    final created = await repository.createBudget(
      BudgetDraft(
        name: 'Presupuesto',
        amountMinor: 100000,
        currency: 'COP',
        period: BudgetPeriod.monthly,
        startDate: anchor,
        recurring: true,
        accountIds: accountIds,
      ),
    );
    return created.getRight().toNullable()!.id;
  }

  Future<void> insertTransfer({
    required String originAccountId,
    required String destinationAccountId,
    required int amountMinor,
    required bool countsInBudget,
    String? categoryId,
  }) =>
      database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              accountId: originAccountId,
              transferAccountId: Value(destinationAccountId),
              categoryId: Value(categoryId),
              amountMinor: amountMinor,
              currency: 'COP',
              type: EntryType.transfer,
              date: DateTime(now.year, now.month, now.day),
              countsInBudget: Value(countsInBudget),
              updatedAt: const Value(0),
            ),
          );

  int spentMinorOf(
    List<BudgetWithProgress> budgets,
    String budgetId,
  ) {
    final match = budgets.firstWhere((b) => b.budget.id == budgetId);
    return match.progress.spentMinor;
  }

  test(
      'countsInBudget=true con la cuenta origen en el alcance del '
      'presupuesto cuenta como gasto', () async {
    final origin = await createAccount('Nequi');
    final destination = await createAccount('Ahorros');
    final category = await createExpenseCategory('Transferencias');
    final budgetId = await createBudgetScopedTo({origin.id});

    await insertTransfer(
      originAccountId: origin.id,
      destinationAccountId: destination.id,
      amountMinor: 50000,
      countsInBudget: true,
      categoryId: category.id,
    );

    final result = await repository.watchActiveBudgets().first;
    final budgets = result.getRight().toNullable()!;

    expect(spentMinorOf(budgets, budgetId), 50000);
  });

  test('countsInBudget=false no cuenta como gasto aunque esté en el alcance',
      () async {
    final origin = await createAccount('Nequi');
    final destination = await createAccount('Ahorros');
    final category = await createExpenseCategory('Transferencias');
    final budgetId = await createBudgetScopedTo({origin.id});

    await insertTransfer(
      originAccountId: origin.id,
      destinationAccountId: destination.id,
      amountMinor: 50000,
      countsInBudget: false,
      categoryId: category.id,
    );

    final result = await repository.watchActiveBudgets().first;
    final budgets = result.getRight().toNullable()!;

    expect(spentMinorOf(budgets, budgetId), 0);
  });

  test(
      'una transferencia normal (sin el flag, sin categoría) sigue excluida '
      'como siempre', () async {
    final origin = await createAccount('Nequi');
    final destination = await createAccount('Ahorros');
    final budgetId = await createBudgetScopedTo({origin.id});

    await insertTransfer(
      originAccountId: origin.id,
      destinationAccountId: destination.id,
      amountMinor: 50000,
      countsInBudget: false,
    );

    final result = await repository.watchActiveBudgets().first;
    final budgets = result.getRight().toNullable()!;

    expect(spentMinorOf(budgets, budgetId), 0);
  });

  test(
      'countsInBudget=true cuya cuenta origen NO está en el alcance del '
      'presupuesto no cuenta', () async {
    final origin = await createAccount('Nequi');
    final destination = await createAccount('Ahorros');
    final outOfScope = await createAccount('Efectivo');
    final category = await createExpenseCategory('Transferencias');
    // Budget scoped to an unrelated account, not the transfer's origin.
    final budgetId = await createBudgetScopedTo({outOfScope.id});

    await insertTransfer(
      originAccountId: origin.id,
      destinationAccountId: destination.id,
      amountMinor: 50000,
      countsInBudget: true,
      categoryId: category.id,
    );

    final result = await repository.watchActiveBudgets().first;
    final budgets = result.getRight().toNullable()!;

    expect(spentMinorOf(budgets, budgetId), 0);
  });

  test(
      'un presupuesto global (sin alcance de cuenta) sí cuenta una '
      'transferencia presupuestable de cualquier cuenta', () async {
    final origin = await createAccount('Nequi');
    final destination = await createAccount('Ahorros');
    final category = await createExpenseCategory('Transferencias');
    final budgetId = await createBudgetScopedTo(const {});

    await insertTransfer(
      originAccountId: origin.id,
      destinationAccountId: destination.id,
      amountMinor: 50000,
      countsInBudget: true,
      categoryId: category.id,
    );

    final result = await repository.watchActiveBudgets().first;
    final budgets = result.getRight().toNullable()!;

    expect(spentMinorOf(budgets, budgetId), 50000);
  });
}
