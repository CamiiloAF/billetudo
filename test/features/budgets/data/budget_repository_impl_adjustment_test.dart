import 'package:billetudo/core/database/app_database.dart' hide BudgetPeriod;
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/data/datasources/budgets_local_datasource.dart';
import 'package:billetudo/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart'
    show BudgetPeriod;
import 'package:billetudo/features/budgets/domain/entities/budget.dart'
    as domain show Budget;
import 'package:billetudo/features/budgets/domain/entities/budget_draft.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/services/budget_period_calculator.dart';
import 'package:billetudo/features/budgets/domain/services/budget_progress_calculator.dart';
import 'package:billetudo/features/budgets/domain/services/zero_based_summary_calculator.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/project_upcoming_occurrences.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Ajustar monto — este período" (fork de 2 o 3 partes): the business flow
/// end-to-end against a real (in-memory) Drift schema.
///
/// Two shapes exist, both anchored on `currentWindow`:
///  - `currentWindow.index > 0`: closes the original at the end of the
///    *previous* cycle, forks a this-cycle-only "adjusted" budget and an
///    indefinite "resume" one.
///  - `currentWindow.index == 0` (no previous cycle to close): patches the
///    original row in place (new amount, `endDate` at the end of the current
///    cycle) and only inserts the "resume" fork.
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

  final now = DateTime.now();
  // Anchored to the 1st of the current month so `DateTime.now()` (which the
  // repository reads internally, not injectable) always lands inside the
  // budget's *current* monthly window (`currentWindow.index == 0`),
  // regardless of what day the suite runs.
  final anchorThisMonth = DateTime(now.year, now.month, 1);
  // Anchored two months back so `currentWindow.index` is always >= 1 (there
  // is a previous cycle to close), exercising the other shape.
  final anchorTwoMonthsAgo = DateTime(now.year, now.month - 2, 1);

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
    DateTime? startDate,
  }) async {
    final created = await repository.createBudget(
      BudgetDraft(
        name: 'Mercado',
        icon: 'utensils',
        amountMinor: amountMinor,
        currency: 'COP',
        period: BudgetPeriod.monthly,
        startDate: startDate ?? anchorThisMonth,
        recurring: true,
        alertThresholdPct: 80,
        accountIds: accountIds,
      ),
    );
    return created.getRight().toNullable()!.id;
  }

  BudgetPeriodWindow currentWindowOf(Budget row) => BudgetPeriodCalculator(
        domain.Budget(
          id: row.id,
          name: row.name,
          amountMinor: row.amountMinor,
          currency: row.currency,
          period: BudgetPeriod.monthly,
          startDate: row.startDate,
          recurring: true,
          rollover: row.rollover,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        ),
      ).currentWindow(now);

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
        startDate: anchorThisMonth,
        recurring: false,
        endDate: anchorThisMonth.add(const Duration(days: 10)),
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

  group('currentWindow.index == 0 (in-place, no previous cycle to close)',
      () {
    test(
        'schedules the fork of 2 parts: patches the original in place and '
        'only inserts the resume fork', () async {
      final account = await createAccount('Efectivo');
      final id = await createRecurringBudget(accountIds: {account.id});

      final originalBefore = await datasource.getBudget(id);
      expect(originalBefore!.endDate, isNull);
      final window = currentWindowOf(originalBefore);
      expect(window.index, 0);

      final scheduled = await repository.scheduleBudgetAdjustment(
        id,
        newAmountMinor: 50000,
      );
      expect(scheduled.getRight().toNullable(), unit);

      // The original row is patched in place: same id, same `startDate`, new
      // amount, `endDate` at the end of the current cycle. Its `updatedAt`
      // moved forward (every write stamps it).
      final patched = await datasource.getBudget(id);
      expect(patched, isNotNull);
      expect(patched!.id, id);
      expect(patched.startDate, originalBefore.startDate);
      expect(patched.amountMinor, 50000);
      expect(patched.endDate, window.lastDay);
      expect(patched.updatedAt, greaterThanOrEqualTo(originalBefore.updatedAt));

      final adjustment = (await repository.getPendingAdjustment(id))
          .getRight()
          .toNullable();
      expect(adjustment, isNotNull);
      // Money stays in integer cents throughout the fork.
      expect(adjustment!.newAmountMinor, 50000);
      expect(adjustment.effectiveFrom, window.start);
      expect(adjustment.resumeAmountMinor, 100000);
      expect(adjustment.resumeFrom, window.lastDay.add(const Duration(days: 1)));

      // No separate "adjusted" fork row exists — only one extra (resume) row.
      final all = await database.select(database.budgets).get();
      expect(all.length, 2);

      // Scope is carried over to the resume fork.
      final resumeRow =
          all.firstWhere((row) => row.id != id && row.endDate == null);
      final resumeScope = await datasource.accountScopeOf(resumeRow.id);
      expect(resumeScope, [account.id]);
    });

    test('updateBudgetAdjustment rewrites only the patched-in-place amount',
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
      // Still resumes at the untouched original amount, which only the
      // resume fork remembers once the original row is patched.
      expect(adjustment.resumeAmountMinor, 100000);

      final row = await datasource.getBudget(id);
      expect(row!.amountMinor, 75000);
    });

    test(
        'cancelBudgetAdjustment restores the original row and removes only '
        'the resume fork', () async {
      final id = await createRecurringBudget();
      final originalBefore = await datasource.getBudget(id);
      await repository.scheduleBudgetAdjustment(id, newAmountMinor: 50000);

      final beforeCancel = await datasource.getBudget(id);
      final resumeBefore =
          await datasource.findResumeFork(beforeCancel!, beforeCancel);

      final cancelled = await repository.cancelBudgetAdjustment(id);
      expect(cancelled.getRight().toNullable(), unit);

      final reopened = await datasource.getBudget(id);
      expect(reopened!.id, id);
      expect(reopened.endDate, isNull);
      expect(reopened.amountMinor, originalBefore!.amountMinor);

      final adjustment =
          (await repository.getPendingAdjustment(id)).getRight().toNullable();
      expect(adjustment, isNull);

      // Only the never-applied resume fork is tombstoned (not hard-deleted:
      // `reconcileScope` may already have written BudgetAccounts/
      // BudgetCategories rows whose FK points at it); the original row
      // (which played the adjusted role) survives under the same id.
      expect(await datasource.getBudget(resumeBefore!.id), isNull);
      final all = await database.select(database.budgets).get();
      expect(all.length, 2);
      final resumeRaw = all.singleWhere((b) => b.id == resumeBefore.id);
      expect(resumeRaw.tombstonedAt, isNotNull);
    });
  });

  group('currentWindow.index > 0 (closes a previous cycle, forks 3 parts)',
      () {
    test(
        'schedules the fork of 3 parts: closes the original at the end of '
        'the previous cycle and forks the adjusted + resume budgets',
        () async {
      final account = await createAccount('Efectivo');
      final id = await createRecurringBudget(
        accountIds: {account.id},
        startDate: anchorTwoMonthsAgo,
      );

      final originalBefore = await datasource.getBudget(id);
      expect(originalBefore!.endDate, isNull);
      final window = currentWindowOf(originalBefore);
      expect(window.index, greaterThan(0));

      final scheduled = await repository.scheduleBudgetAdjustment(
        id,
        newAmountMinor: 50000,
      );
      expect(scheduled.getRight().toNullable(), unit);

      // The original closes at the end of the *previous* cycle — its own
      // `startDate` and amount are untouched.
      final closed = await datasource.getBudget(id);
      expect(closed, isNotNull);
      expect(closed!.startDate, originalBefore.startDate);
      expect(closed.amountMinor, originalBefore.amountMinor);
      expect(closed.endDate, window.start.subtract(const Duration(days: 1)));
      expect(closed.updatedAt, greaterThanOrEqualTo(originalBefore.updatedAt));

      final adjustment = (await repository.getPendingAdjustment(id))
          .getRight()
          .toNullable();
      expect(adjustment, isNotNull);
      expect(adjustment!.newAmountMinor, 50000);
      expect(adjustment.effectiveFrom, window.start);
      expect(adjustment.resumeAmountMinor, 100000);
      expect(adjustment.resumeFrom, window.lastDay.add(const Duration(days: 1)));

      // The adjusted fork is a separate row covering exactly the current
      // cycle, and scope is carried over to it.
      final adjustedRow = await datasource.findAdjustedFork(closed);
      expect(adjustedRow, isNotNull);
      expect(adjustedRow!.id, isNot(id));
      expect(adjustedRow.startDate, window.start);
      expect(adjustedRow.endDate, window.lastDay);
      expect(adjustedRow.amountMinor, 50000);
      final adjustedScope = await datasource.accountScopeOf(adjustedRow.id);
      expect(adjustedScope, [account.id]);

      final all = await database.select(database.budgets).get();
      expect(all.length, 3);
    });

    test('updateBudgetAdjustment rewrites only the adjusted fork amount',
        () async {
      final id = await createRecurringBudget(startDate: anchorTwoMonthsAgo);
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
      expect(adjustment.resumeAmountMinor, 100000);

      // The closed original is untouched by the edit.
      final closed = await datasource.getBudget(id);
      expect(closed!.amountMinor, 100000);
    });

    test('updateBudgetAdjustment rejects a non-positive amount', () async {
      final id = await createRecurringBudget(startDate: anchorTwoMonthsAgo);
      await repository.scheduleBudgetAdjustment(id, newAmountMinor: 50000);

      final result =
          await repository.updateBudgetAdjustment(id, newAmountMinor: -1);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('updateBudgetAdjustment without a pending fork fails not found',
        () async {
      final id = await createRecurringBudget(startDate: anchorTwoMonthsAgo);

      final result =
          await repository.updateBudgetAdjustment(id, newAmountMinor: 75000);

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });

    test(
        'cancelBudgetAdjustment removes both forks and reopens the original '
        'indefinitely', () async {
      final id = await createRecurringBudget(startDate: anchorTwoMonthsAgo);
      await repository.scheduleBudgetAdjustment(id, newAmountMinor: 50000);
      final adjustedBefore =
          await datasource.findAdjustedFork((await datasource.getBudget(id))!);

      final cancelled = await repository.cancelBudgetAdjustment(id);
      expect(cancelled.getRight().toNullable(), unit);

      final reopened = await datasource.getBudget(id);
      expect(reopened!.endDate, isNull);
      expect(reopened.amountMinor, 100000);

      final adjustment =
          (await repository.getPendingAdjustment(id)).getRight().toNullable();
      expect(adjustment, isNull);

      // The forks never applied, so they are tombstoned (excluded from every
      // alive-only read), not hard-deleted: their BudgetAccounts/
      // BudgetCategories scope rows may already reference them.
      expect(await datasource.getBudget(adjustedBefore!.id), isNull);
      final all = await database.select(database.budgets).get();
      expect(all.length, 3);
      final adjustedRaw = all.singleWhere((b) => b.id == adjustedBefore.id);
      expect(adjustedRaw.tombstonedAt, isNotNull);
    });

    test('cancelBudgetAdjustment without a pending fork fails not found',
        () async {
      final id = await createRecurringBudget(startDate: anchorTwoMonthsAgo);

      final result = await repository.cancelBudgetAdjustment(id);

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
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
}
