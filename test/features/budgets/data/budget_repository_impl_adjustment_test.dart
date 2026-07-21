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

/// "Ajustar monto" (Wallet-style per-period override) against a real (in-memory)
/// Drift schema. The adjustment writes a single `BudgetPeriodOverride` for the
/// window the stepper is showing (the one containing `periodStart`); the budget
/// itself always stays a single row (no fork), and every other period returns to
/// the base amount automatically. A `past` visible window is rejected.
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
  // repository reads internally, not injectable) lands inside the budget's
  // *current* monthly window (`currentWindow.index == 0`).
  final anchorThisMonth = DateTime(now.year, now.month, 1);
  // Anchored two months back so `currentWindow.index` is always >= 1.
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

  BudgetPeriodCalculator calculatorOf(Budget row) => BudgetPeriodCalculator(
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
      );

  // The stepper's visible window is the current one by default; the override
  // targets it (the window containing `periodStart`).
  BudgetPeriodWindow visibleWindowOf(Budget row) =>
      calculatorOf(row).currentWindow(now);
  BudgetPeriodWindow resumeWindowOf(Budget row) =>
      calculatorOf(row).windowAt(visibleWindowOf(row).index + 1, now);
  BudgetPeriodWindow windowAtOf(Budget row, int index) =>
      calculatorOf(row).windowAt(index, now);

  test('getPendingAdjustment is null before scheduling anything', () async {
    final id = await createRecurringBudget();

    final result = await repository.getPendingAdjustment(id, periodStart: now);

    expect(result.getRight().toNullable(), isNull);
  });

  test('getPendingAdjustment on a non-existent budget fails not found',
      () async {
    final result =
        await repository.getPendingAdjustment('missing', periodStart: now);

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

    final result = await repository.scheduleBudgetAdjustment(
      id,
      newAmountMinor: 50000,
      periodStart: anchorThisMonth,
    );

    final failure = result.getLeft().toNullable();
    expect(failure, isA<ValidationFailure>());
    expect((failure! as ValidationFailure).field, BudgetDraft.fieldEndDate);
  });

  test('scheduleBudgetAdjustment rejects a non-positive amount', () async {
    final id = await createRecurringBudget();

    final result = await repository.scheduleBudgetAdjustment(
      id,
      newAmountMinor: 0,
      periodStart: now,
    );

    final failure = result.getLeft().toNullable();
    expect(failure, isA<ValidationFailure>());
    expect((failure! as ValidationFailure).field, BudgetDraft.fieldAmount);
  });

  test('scheduleBudgetAdjustment on a non-existent budget fails not found',
      () async {
    final result = await repository.scheduleBudgetAdjustment(
      'missing',
      newAmountMinor: 50000,
      periodStart: now,
    );

    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });

  test('scheduleBudgetAdjustment rejects a past visible window', () async {
    final id = await createRecurringBudget(startDate: anchorTwoMonthsAgo);
    final row = await datasource.getBudget(id);
    // Window index 0 is two months back — a past cycle.
    final past = windowAtOf(row!, 0);
    expect(past.status, BudgetWindowStatus.past);

    final result = await repository.scheduleBudgetAdjustment(
      id,
      newAmountMinor: 50000,
      periodStart: past.start,
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    // Nothing was written.
    expect(await datasource.getPeriodOverride(id, past.start), isNull);
  });

  // The override targets the visible window regardless of its index, so the two
  // anchors (current index 0 vs >0) must behave identically.
  for (final scenario in <({String label, DateTime? anchor})>[
    (label: 'currentWindow.index == 0', anchor: null),
    (label: 'currentWindow.index > 0', anchor: anchorTwoMonthsAgo),
  ]) {
    group(scenario.label, () {
      test(
          'schedules an override for the visible window without forking: the '
          'budget stays one row, unchanged', () async {
        final account = await createAccount('Efectivo');
        final id = await createRecurringBudget(
          accountIds: {account.id},
          startDate: scenario.anchor,
        );

        final originalBefore = await datasource.getBudget(id);
        expect(originalBefore!.endDate, isNull);
        final visible = visibleWindowOf(originalBefore);

        final scheduled = await repository.scheduleBudgetAdjustment(
          id,
          newAmountMinor: 50000,
          periodStart: visible.start,
        );
        expect(scheduled.getRight().toNullable(), unit);

        // The budget row is completely untouched (no endDate, same amount).
        final after = await datasource.getBudget(id);
        expect(after!.id, id);
        expect(after.startDate, originalBefore.startDate);
        expect(after.amountMinor, originalBefore.amountMinor);
        expect(after.endDate, isNull);

        // Still exactly one budget row — no adjusted/resume fork.
        final all = await database.select(database.budgets).get();
        expect(all, hasLength(1));

        // Exactly one override row, on the visible window's start.
        final override = await datasource.getPeriodOverride(id, visible.start);
        expect(override, isNotNull);
        expect(override!.amountMinor, 50000);
        expect(override.periodStart, visible.start);

        // The read model reflects the visible-period adjustment.
        final adjustment = (await repository.getPendingAdjustment(
          id,
          periodStart: visible.start,
        ))
            .getRight()
            .toNullable();
        expect(adjustment, isNotNull);
        expect(adjustment!.newAmountMinor, 50000);
        expect(adjustment.effectiveFrom, visible.start);
        expect(adjustment.resumeAmountMinor, 100000);
        expect(adjustment.resumeFrom, resumeWindowOf(originalBefore).start);
      });

      test('updateBudgetAdjustment rewrites only the override amount',
          () async {
        final id = await createRecurringBudget(startDate: scenario.anchor);
        final row = await datasource.getBudget(id);
        final visible = visibleWindowOf(row!);
        await repository.scheduleBudgetAdjustment(
          id,
          newAmountMinor: 50000,
          periodStart: visible.start,
        );

        final updated = await repository.updateBudgetAdjustment(
          id,
          newAmountMinor: 75000,
          periodStart: visible.start,
        );
        expect(updated.getRight().toNullable(), unit);

        final adjustment = (await repository.getPendingAdjustment(
          id,
          periodStart: visible.start,
        ))
            .getRight()
            .toNullable();
        expect(adjustment!.newAmountMinor, 75000);
        expect(adjustment.resumeAmountMinor, 100000);

        // The budget row itself is never touched by the edit.
        final reread = await datasource.getBudget(id);
        expect(reread!.amountMinor, 100000);
        expect(reread.endDate, isNull);
      });

      test('updateBudgetAdjustment rejects a non-positive amount', () async {
        final id = await createRecurringBudget(startDate: scenario.anchor);
        final row = await datasource.getBudget(id);
        final visible = visibleWindowOf(row!);
        await repository.scheduleBudgetAdjustment(
          id,
          newAmountMinor: 50000,
          periodStart: visible.start,
        );

        final result = await repository.updateBudgetAdjustment(
          id,
          newAmountMinor: -1,
          periodStart: visible.start,
        );

        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      });

      test('updateBudgetAdjustment without a pending override fails not found',
          () async {
        final id = await createRecurringBudget(startDate: scenario.anchor);
        final row = await datasource.getBudget(id);
        final visible = visibleWindowOf(row!);

        final result = await repository.updateBudgetAdjustment(
          id,
          newAmountMinor: 75000,
          periodStart: visible.start,
        );

        expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
      });

      test(
          'cancelBudgetAdjustment hard-deletes the override, leaving the '
          'budget as a single untouched row', () async {
        final id = await createRecurringBudget(startDate: scenario.anchor);
        final originalBefore = await datasource.getBudget(id);
        final visible = visibleWindowOf(originalBefore!);
        await repository.scheduleBudgetAdjustment(
          id,
          newAmountMinor: 50000,
          periodStart: visible.start,
        );

        final cancelled = await repository.cancelBudgetAdjustment(
          id,
          periodStart: visible.start,
        );
        expect(cancelled.getRight().toNullable(), unit);

        final reopened = await datasource.getBudget(id);
        expect(reopened!.id, id);
        expect(reopened.endDate, isNull);
        expect(reopened.amountMinor, originalBefore.amountMinor);

        expect(
          (await repository.getPendingAdjustment(id, periodStart: visible.start))
              .getRight()
              .toNullable(),
          isNull,
        );
        // The override is physically gone, and the budget is still one row.
        expect(await datasource.getPeriodOverride(id, visible.start), isNull);
        final all = await database.select(database.budgets).get();
        expect(all, hasLength(1));
        final overrideRows =
            await database.select(database.budgetPeriodOverrides).get();
        expect(overrideRows, isEmpty);
      });

      test('cancelBudgetAdjustment without a pending override fails not found',
          () async {
        final id = await createRecurringBudget(startDate: scenario.anchor);
        final row = await datasource.getBudget(id);
        final visible = visibleWindowOf(row!);

        final result = await repository.cancelBudgetAdjustment(
          id,
          periodStart: visible.start,
        );

        expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
      });
    });
  }

  test('scheduling a second time on the same visible window fails', () async {
    final id = await createRecurringBudget();
    final row = await datasource.getBudget(id);
    final visible = visibleWindowOf(row!);
    await repository.scheduleBudgetAdjustment(
      id,
      newAmountMinor: 50000,
      periodStart: visible.start,
    );

    final result = await repository.scheduleBudgetAdjustment(
      id,
      newAmountMinor: 60000,
      periodStart: visible.start,
    );

    final failure = result.getLeft().toNullable();
    expect(failure, isA<ValidationFailure>());
    expect((failure! as ValidationFailure).field, BudgetDraft.fieldAmount);
  });
}
