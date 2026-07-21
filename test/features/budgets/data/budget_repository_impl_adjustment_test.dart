import 'package:billetudo/core/database/app_database.dart' hide BudgetPeriod;
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/data/datasources/budgets_local_datasource.dart';
import 'package:billetudo/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart'
    show BudgetPeriod;
import 'package:billetudo/features/budgets/domain/entities/budget.dart'
    as domain show Budget;
import 'package:billetudo/features/budgets/domain/entities/budget_draft.dart';
import 'package:billetudo/features/budgets/domain/services/budget_period_calculator.dart';
import 'package:billetudo/features/budgets/domain/services/budget_progress_calculator.dart';
import 'package:billetudo/features/budgets/domain/services/zero_based_summary_calculator.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/project_upcoming_occurrences.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Ajustar monto — solo el próximo período" (fork de 3 partes): the business
/// flow end-to-end against a real (in-memory) Drift schema — closes the
/// current budget at the end of its cycle, forks the next-cycle-only adjusted
/// amount and the indefinite resume, and supports editing/cancelling a
/// pending fork before it rolls over.
void main() {
  late AppDatabase database;
  late BudgetsLocalDatasource datasource;
  late BudgetRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    datasource = BudgetsLocalDatasource(database);
    repository = BudgetRepositoryImpl(
      datasource,
      const BudgetProgressCalculator(),
      const ZeroBasedSummaryCalculator(),
      const ProjectUpcomingOccurrences(),
    );
  });

  tearDown(() async => database.close());

  // Anchored to the 1st of the current month so `DateTime.now()` (which the
  // repository reads internally, not injectable) always lands inside the
  // budget's *current* monthly window, regardless of what day the suite runs.
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

  Future<String> createRecurringBudget({
    int amountMinor = 100000,
    Set<String> accountIds = const {},
  }) async {
    final created = await repository.createBudget(
      BudgetDraft(
        name: 'Mercado',
        icon: 'utensils',
        amountMinor: amountMinor,
        currency: 'COP',
        period: BudgetPeriod.monthly,
        startDate: anchor,
        recurring: true,
        alertThresholdPct: 80,
        accountIds: accountIds,
      ),
    );
    return created.getRight().toNullable()!.id;
  }

  test('getPendingAdjustment is null before scheduling anything', () async {
    final id = await createRecurringBudget();

    final result = await repository.getPendingAdjustment(id);

    expect(result.getRight().toNullable(), isNull);
  });

  test('getPendingAdjustment on a non-existent budget fails not found',
      () async {
    final result = await repository.getPendingAdjustment('missing');

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });

  test('scheduleBudgetAdjustment on a one-off budget fails validation',
      () async {
    final created = await repository.createBudget(
      BudgetDraft(
        name: 'Viaje',
        amountMinor: 200000,
        currency: 'COP',
        period: BudgetPeriod.custom,
        startDate: anchor,
        recurring: false,
        endDate: anchor.add(const Duration(days: 10)),
      ),
    );
    final id = created.getRight().toNullable()!.id;

    final result =
        await repository.scheduleBudgetAdjustment(id, newAmountMinor: 50000);

    final failure = result.getLeft().toNullable();
    expect(failure, isA<ValidationFailure>());
    expect((failure! as ValidationFailure).field, BudgetDraft.fieldEndDate);
  });

  test('scheduleBudgetAdjustment rejects a non-positive amount', () async {
    final id = await createRecurringBudget();

    final result =
        await repository.scheduleBudgetAdjustment(id, newAmountMinor: 0);

    final failure = result.getLeft().toNullable();
    expect(failure, isA<ValidationFailure>());
    expect((failure! as ValidationFailure).field, BudgetDraft.fieldAmount);
  });

  test('scheduleBudgetAdjustment on a non-existent budget fails not found',
      () async {
    final result = await repository.scheduleBudgetAdjustment(
      'missing',
      newAmountMinor: 50000,
    );

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });

  group('schedule -> get -> edit -> cancel (full fork lifecycle)', () {
    test(
        'schedules the fork of 3 parts: closes the original at cycle end and '
        'forks the adjusted + resume budgets', () async {
      final account = await createAccount('Efectivo');
      final id = await createRecurringBudget(accountIds: {account.id});

      final originalBefore = await datasource.getBudget(id);
      expect(originalBefore!.endDate, isNull);

      final scheduled = await repository.scheduleBudgetAdjustment(
        id,
        newAmountMinor: 50000,
      );
      expect(scheduled.getRight().toNullable(), unit);

      // The original now stops renewing after its current cycle, and its
      // `updatedAt` moved forward (every write stamps it).
      final closed = await datasource.getBudget(id);
      expect(closed, isNotNull);
      expect(closed!.endDate, isNotNull);
      expect(closed.updatedAt, greaterThanOrEqualTo(originalBefore.updatedAt));

      final window = BudgetPeriodCalculator(
        domain.Budget(
          id: closed.id,
          name: closed.name,
          amountMinor: closed.amountMinor,
          currency: closed.currency,
          period: BudgetPeriod.monthly,
          startDate: closed.startDate,
          recurring: true,
          rollover: closed.rollover,
          createdAt: closed.createdAt,
          updatedAt: closed.updatedAt,
        ),
      ).currentWindow(now);
      expect(closed.endDate, window.lastDay);

      final adjustment = (await repository.getPendingAdjustment(id))
          .getRight()
          .toNullable();
      expect(adjustment, isNotNull);
      // Money stays in integer cents throughout the fork.
      expect(adjustment!.newAmountMinor, 50000);
      expect(adjustment.resumeAmountMinor, 100000);
      expect(adjustment.effectiveFrom, window.lastDay.add(const Duration(days: 1)));

      // Scope is carried over to the adjusted fork.
      final adjustedRow = await datasource.findAdjustedFork(closed);
      expect(adjustedRow, isNotNull);
      final adjustedScope = await datasource.accountScopeOf(adjustedRow!.id);
      expect(adjustedScope, [account.id]);
    });

    test('scheduling a second time on an already-forked budget fails',
        () async {
      final id = await createRecurringBudget();
      await repository.scheduleBudgetAdjustment(id, newAmountMinor: 50000);

      final result = await repository.scheduleBudgetAdjustment(
        id,
        newAmountMinor: 60000,
      );

      final failure = result.getLeft().toNullable();
      expect(failure, isA<ValidationFailure>());
      expect((failure! as ValidationFailure).field, BudgetDraft.fieldAmount);
    });

    test('updateBudgetAdjustment rewrites only the pending fork amount',
        () async {
      final id = await createRecurringBudget();
      await repository.scheduleBudgetAdjustment(id, newAmountMinor: 50000);

      final updated = await repository.updateBudgetAdjustment(
        id,
        newAmountMinor: 75000,
      );
      expect(updated.getRight().toNullable(), unit);

      final adjustment = (await repository.getPendingAdjustment(id))
          .getRight()
          .toNullable();
      expect(adjustment!.newAmountMinor, 75000);
      // Still resumes at the untouched original amount.
      expect(adjustment.resumeAmountMinor, 100000);
    });

    test('updateBudgetAdjustment rejects a non-positive amount', () async {
      final id = await createRecurringBudget();
      await repository.scheduleBudgetAdjustment(id, newAmountMinor: 50000);

      final result =
          await repository.updateBudgetAdjustment(id, newAmountMinor: -1);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('updateBudgetAdjustment without a pending fork fails not found',
        () async {
      final id = await createRecurringBudget();

      final result =
          await repository.updateBudgetAdjustment(id, newAmountMinor: 75000);

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });

    test(
        'cancelBudgetAdjustment removes both forks and reopens the original '
        'indefinitely', () async {
      final id = await createRecurringBudget();
      await repository.scheduleBudgetAdjustment(id, newAmountMinor: 50000);
      final adjustedBefore =
          await datasource.findAdjustedFork((await datasource.getBudget(id))!);

      final cancelled = await repository.cancelBudgetAdjustment(id);
      expect(cancelled.getRight().toNullable(), unit);

      final reopened = await datasource.getBudget(id);
      expect(reopened!.endDate, isNull);

      final adjustment =
          (await repository.getPendingAdjustment(id)).getRight().toNullable();
      expect(adjustment, isNull);

      // The forks never applied, so they are hard-deleted, not trashed.
      expect(await datasource.getBudget(adjustedBefore!.id), isNull);
    });

    test('cancelBudgetAdjustment without a pending fork fails not found',
        () async {
      final id = await createRecurringBudget();

      final result = await repository.cancelBudgetAdjustment(id);

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });
}
