import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/budgets/data/datasources/budgets_local_datasource.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Ajustar monto — solo el próximo período" (Wallet-style per-period
/// override): the amount for a single window lives in `BudgetPeriodOverrides`,
/// one row per (budgetId, periodStart), and the budget itself stays a single
/// row. These tests exercise the datasource's override CRUD directly against a
/// real (in-memory) schema.
void main() {
  late AppDatabase database;
  late BudgetsLocalDatasource datasource;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    datasource = BudgetsLocalDatasource(database);
  });

  tearDown(() async => database.close());

  Future<Budget> insertBudget({
    String name = 'Mercado',
    String? icon = 'utensils',
    required int amountMinor,
    String currency = 'COP',
    BudgetPeriod period = BudgetPeriod.monthly,
    required DateTime startDate,
    DateTime? endDate,
    bool rollover = false,
    int? alertThresholdPct = 80,
  }) =>
      database.into(database.budgets).insertReturning(
            BudgetsCompanion.insert(
              name: name,
              icon: Value(icon),
              amountMinor: amountMinor,
              currency: currency,
              period: period,
              startDate: startDate,
              endDate: Value(endDate),
              rollover: Value(rollover),
              alertThresholdPct: Value(alertThresholdPct),
              updatedAt: const Value(0),
            ),
          );

  group('upsertPeriodOverride / getPeriodOverride', () {
    test('inserts a single override and reads it back, budget stays one row',
        () async {
      final budget = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
      );
      final periodStart = DateTime(2026, 8, 1);

      await datasource.upsertPeriodOverride(
        budgetId: budget.id,
        periodStart: periodStart,
        amountMinor: 50000,
        now: DateTime(2026, 7, 15),
      );

      final found = await datasource.getPeriodOverride(budget.id, periodStart);
      expect(found, isNotNull);
      expect(found?.budgetId, budget.id);
      expect(found?.periodStart, periodStart);
      expect(found?.amountMinor, 50000);

      // The budget is still a single row — no fork was created.
      final budgetRows = await database.select(database.budgets).get();
      expect(budgetRows, hasLength(1));

      final overrideRows =
          await database.select(database.budgetPeriodOverrides).get();
      expect(overrideRows, hasLength(1));
      expect(overrideRows.single.updatedAt, isNot(0));
    });

    test('matches periodStart date-only (ignores any time component)',
        () async {
      final budget = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
      );

      await datasource.upsertPeriodOverride(
        budgetId: budget.id,
        periodStart: DateTime(2026, 8, 1, 13, 45),
        amountMinor: 50000,
        now: DateTime(2026, 7, 15),
      );

      final found =
          await datasource.getPeriodOverride(budget.id, DateTime(2026, 8, 1));
      expect(found?.amountMinor, 50000);
      expect(found?.periodStart, DateTime(2026, 8, 1));
    });

    test('returns null when there is no override for that window', () async {
      final budget = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
      );

      final found =
          await datasource.getPeriodOverride(budget.id, DateTime(2026, 8, 1));
      expect(found, isNull);
    });
  });

  group('updatePeriodOverrideAmount', () {
    test('rewrites only the amount of the existing override', () async {
      final budget = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
      );
      final periodStart = DateTime(2026, 8, 1);
      await datasource.upsertPeriodOverride(
        budgetId: budget.id,
        periodStart: periodStart,
        amountMinor: 50000,
        now: DateTime(2026, 7, 15),
      );

      await datasource.updatePeriodOverrideAmount(
        budgetId: budget.id,
        periodStart: periodStart,
        amountMinor: 75000,
        now: DateTime(2026, 7, 16),
      );

      final found = await datasource.getPeriodOverride(budget.id, periodStart);
      expect(found?.amountMinor, 75000);
      // Still exactly one override row.
      final overrideRows =
          await database.select(database.budgetPeriodOverrides).get();
      expect(overrideRows, hasLength(1));
    });
  });

  group('deletePeriodOverride', () {
    test('hard-deletes the override, leaving the budget untouched', () async {
      final budget = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
      );
      final periodStart = DateTime(2026, 8, 1);
      await datasource.upsertPeriodOverride(
        budgetId: budget.id,
        periodStart: periodStart,
        amountMinor: 50000,
        now: DateTime(2026, 7, 15),
      );

      await datasource.deletePeriodOverride(budget.id, periodStart);

      expect(
        await datasource.getPeriodOverride(budget.id, periodStart),
        isNull,
      );
      // Hard delete: the row is physically gone, not soft-deleted.
      final overrideRows =
          await database.select(database.budgetPeriodOverrides).get();
      expect(overrideRows, isEmpty);
      // Budget survives unchanged.
      final reread = await datasource.getBudget(budget.id);
      expect(reread?.amountMinor, 100000);
      expect(reread?.endDate, isNull);
    });
  });

  group('watchBudgetPeriodOverrides', () {
    test('emits every override across budgets', () async {
      final a = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
      );
      final b = await insertBudget(
        name: 'Transporte',
        amountMinor: 30000,
        startDate: DateTime(2026, 7, 1),
      );
      await datasource.upsertPeriodOverride(
        budgetId: a.id,
        periodStart: DateTime(2026, 8, 1),
        amountMinor: 50000,
        now: DateTime(2026, 7, 15),
      );
      await datasource.upsertPeriodOverride(
        budgetId: b.id,
        periodStart: DateTime(2026, 8, 1),
        amountMinor: 20000,
        now: DateTime(2026, 7, 15),
      );

      final emitted = await datasource.watchBudgetPeriodOverrides().first;
      expect(emitted, hasLength(2));
      expect(
        emitted.map((o) => o.budgetId).toSet(),
        {a.id, b.id},
      );
    });
  });
}
