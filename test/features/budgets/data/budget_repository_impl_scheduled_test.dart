import 'package:billetudo/core/database/app_database.dart' hide BudgetPeriod;
import 'package:billetudo/features/budgets/data/datasources/budgets_local_datasource.dart';
import 'package:billetudo/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart'
    show BudgetPeriod;
import 'package:billetudo/features/budgets/domain/entities/budget_draft.dart';
import 'package:billetudo/features/budgets/domain/services/budget_progress_calculator.dart';
import 'package:billetudo/features/budgets/domain/services/zero_based_summary_calculator.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/project_upcoming_occurrences.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// HU-12: `BudgetRepositoryImpl.watchBudgetDetail` must fold the new
/// scheduled-payment streams into `BudgetDetailData`, mapping Drift rows into
/// the domain entities (never leaking `db.*` types).
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
    );
  });

  tearDown(() async => database.close());

  Future<Account> createAccount(String name) =>
      database.into(database.accounts).insertReturning(
            AccountsCompanion.insert(
              name: name,
              type: AccountType.bank,
              currency: 'COP',
            ),
          );

  Future<Category> createCategory(String name, {required CategoryKind kind}) =>
      database.into(database.categories).insertReturning(
            CategoriesCompanion.insert(name: name, kind: kind),
          );

  test(
      'watchBudgetDetail carries the scheduled templates and pending '
      'occurrences, enriched and mapped to domain entities', () async {
    final account = await createAccount('Efectivo');
    final category = await createCategory('Renta', kind: CategoryKind.expense);

    final created = await repository.createBudget(
      BudgetDraft(
        name: 'Test',
        amountMinor: 100000,
        currency: 'COP',
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 7, 1),
        recurring: true,
      ),
    );
    final budget = created.getRight().toNullable()!;

    final template =
        await database.into(database.scheduledPayments).insertReturning(
              ScheduledPaymentsCompanion.insert(
                accountId: account.id,
                categoryId: Value(category.id),
                amountMinor: 20000,
                currency: 'COP',
                type: EntryType.expense,
                frequency: ScheduleFrequency.monthly,
                firstPaymentDate: DateTime(2026, 7, 15),
                nextDate: DateTime(2026, 7, 15),
                updatedAt: const Value(0),
              ),
            );

    final pendingTemplate =
        await database.into(database.scheduledPayments).insertReturning(
              ScheduledPaymentsCompanion.insert(
                accountId: account.id,
                categoryId: Value(category.id),
                amountMinor: 15000,
                currency: 'COP',
                type: EntryType.expense,
                frequency: ScheduleFrequency.monthly,
                requiresConfirmation: const Value(true),
                firstPaymentDate: DateTime(2026, 8, 1),
                nextDate: DateTime(2026, 8, 1),
                updatedAt: const Value(0),
              ),
            );
    await database.into(database.scheduledPaymentOccurrences).insertReturning(
          ScheduledPaymentOccurrencesCompanion.insert(
            scheduledPaymentId: pendingTemplate.id,
            occurrenceDate: DateTime(2026, 7, 1),
            status: const Value(ScheduledOccurrenceStatus.pending),
            updatedAt: const Value(0),
          ),
        );

    final result = await repository.watchBudgetDetail(budget.id).first;
    final data = result.getRight().toNullable()!;

    // Both templates are active expense templates (the pending occurrence
    // ledger is a separate stream); a pending occurrence does not remove its
    // template from the eligible-templates list.
    expect(data.scheduledTemplates, hasLength(2));
    expect(
      data.scheduledTemplates.map((d) => d.template.id),
      containsAll([template.id, pendingTemplate.id]),
    );
    final templateDetail =
        data.scheduledTemplates.firstWhere((d) => d.template.id == template.id);
    expect(templateDetail.title, 'Renta');
    expect(templateDetail.accountName, 'Efectivo');

    expect(data.pendingScheduledOccurrences, hasLength(1));
    final pending = data.pendingScheduledOccurrences.single;
    expect(pending.scheduledPayment.id, pendingTemplate.id);
    expect(pending.occurrence.isPending, isTrue);
    expect(pending.accountName, 'Efectivo');
    expect(pending.categoryName, 'Renta');
  });

  test(
      'watchActiveBudgets sums a matching template into scheduledMinor '
      'without double-counting a materialized transaction', () async {
    final now = DateTime.now();
    final anchor = DateTime(now.year, now.month, 1);
    final account = await createAccount('Efectivo');
    final category = await createCategory('Renta', kind: CategoryKind.expense);

    final created = await repository.createBudget(
      BudgetDraft(
        name: 'Arriendo',
        amountMinor: 100000,
        currency: 'COP',
        period: BudgetPeriod.monthly,
        startDate: anchor,
        recurring: true,
        accountIds: {account.id},
      ),
    );
    final budget = created.getRight().toNullable()!;

    // Still-pending template inside the current window: counts toward
    // scheduledMinor.
    await database.into(database.scheduledPayments).insertReturning(
          ScheduledPaymentsCompanion.insert(
            accountId: account.id,
            categoryId: Value(category.id),
            amountMinor: 20000,
            currency: 'COP',
            type: EntryType.expense,
            frequency: ScheduleFrequency.monthly,
            firstPaymentDate: DateTime(now.year, now.month, now.day),
            nextDate: DateTime(now.year, now.month, now.day),
            updatedAt: const Value(0),
          ),
        );

    // A materialized expense already counted in spentMinor; scheduledMinor
    // must not also count it.
    await database.into(database.transactions).insertReturning(
          TransactionsCompanion.insert(
            accountId: account.id,
            categoryId: Value(category.id),
            amountMinor: 10000,
            currency: 'COP',
            type: EntryType.expense,
            date: DateTime(now.year, now.month, now.day),
            updatedAt: const Value(0),
          ),
        );

    final result = await repository.watchActiveBudgets().first;
    final withProgress = result
        .getRight()
        .toNullable()!
        .firstWhere((b) => b.budget.id == budget.id);

    expect(withProgress.progress.spentMinor, 10000);
    expect(withProgress.progress.scheduledMinor, 20000);
  });

  test('watchArchivedBudgets never projects scheduledMinor', () async {
    final now = DateTime.now();
    final anchor = DateTime(now.year, now.month, 1);
    final account = await createAccount('Efectivo');
    final category = await createCategory('Renta', kind: CategoryKind.expense);

    final created = await repository.createBudget(
      BudgetDraft(
        name: 'Arriendo',
        amountMinor: 100000,
        currency: 'COP',
        period: BudgetPeriod.monthly,
        startDate: anchor,
        recurring: true,
        accountIds: {account.id},
      ),
    );
    final budget = created.getRight().toNullable()!;

    await database.into(database.scheduledPayments).insertReturning(
          ScheduledPaymentsCompanion.insert(
            accountId: account.id,
            categoryId: Value(category.id),
            amountMinor: 20000,
            currency: 'COP',
            type: EntryType.expense,
            frequency: ScheduleFrequency.monthly,
            firstPaymentDate: DateTime(now.year, now.month, now.day),
            nextDate: DateTime(now.year, now.month, now.day),
            updatedAt: const Value(0),
          ),
        );

    await repository.closeBudget(budget.id);

    final result = await repository.watchArchivedBudgets().first;
    final withProgress = result
        .getRight()
        .toNullable()!
        .firstWhere((b) => b.budget.id == budget.id);

    expect(withProgress.progress.scheduledMinor, 0);
  });
}
