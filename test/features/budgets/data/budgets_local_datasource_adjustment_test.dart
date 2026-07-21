import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/budgets/data/datasources/budgets_local_datasource.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Ajustar monto — solo el próximo período" (fork de 3 partes): the link
/// between the three budgets a fork creates has no column of its own —
/// [BudgetsLocalDatasource.findAdjustedFork]/
/// [BudgetsLocalDatasource.findResumeFork] infer it purely
/// from shape (adjacent `startDate`/`endDate`, matching cadence). These tests
/// exercise that inference directly against a real (in-memory) schema.
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
    DateTime? deletedAt,
    DateTime? tombstonedAt,
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
              deletedAt: Value(deletedAt),
              tombstonedAt: Value(tombstonedAt),
              updatedAt: const Value(0),
            ),
          );

  group('findAdjustedFork', () {
    test('returns null when the original has no endDate (not yet forked)',
        () async {
      final original = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
      );

      final found = await datasource.findAdjustedFork(original);

      expect(found, isNull);
    });

    test(
        'returns null when nothing starts the day right after the original '
        'closes', () async {
      final original = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      // Starts two days later, not one: not a match.
      await insertBudget(
        amountMinor: 50000,
        startDate: DateTime(2026, 8, 2),
      );

      final found = await datasource.findAdjustedFork(original);

      expect(found, isNull);
    });

    test(
        'finds the budget starting the day after endDate with the same '
        'name/icon/currency/period/rollover/threshold', () async {
      final original = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      final adjusted = await insertBudget(
        amountMinor: 50000,
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
      );

      final found = await datasource.findAdjustedFork(original);

      expect(found?.id, adjusted.id);
      expect(found?.amountMinor, 50000);
    });

    test('ignores a same-start budget with a different cadence (name)',
        () async {
      final original = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      // Same start date, but a coincidentally unrelated budget.
      await insertBudget(
        name: 'Otro presupuesto',
        amountMinor: 50000,
        startDate: DateTime(2026, 8, 1),
      );

      final found = await datasource.findAdjustedFork(original);

      expect(found, isNull);
    });

    test('ignores a matching-shape budget that was trashed', () async {
      final original = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      await insertBudget(
        amountMinor: 50000,
        startDate: DateTime(2026, 8, 1),
        deletedAt: DateTime(2026, 7, 15),
      );

      final found = await datasource.findAdjustedFork(original);

      expect(found, isNull);
    });

    test(
        'returns the original itself (currentWindow.index == 0, in-place) '
        'when the row right after it is open-ended — that makes the forward '
        'row the resume fork, not a separate adjusted fork', () async {
      // `original` here already plays the "adjusted" role: patched in place
      // to the new amount, `endDate` at the end of the cycle it is still
      // active in, `startDate` untouched.
      final patchedInPlace = await insertBudget(
        amountMinor: 50000,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 8, 1),
      );

      final found = await datasource.findAdjustedFork(patchedInPlace);

      expect(found?.id, patchedInPlace.id);
    });
  });

  group('findResumeFork', () {
    test(
        'finds the budget that resumes the original amount the day after '
        'the adjusted fork closes', () async {
      final original = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      final adjusted = await insertBudget(
        amountMinor: 50000,
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
      );
      final resume = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 9, 1),
      );

      final found = await datasource.findResumeFork(original, adjusted);

      expect(found?.id, resume.id);
    });

    test(
        'matches by shape alone, not amount — the resume fork of an in-place '
        'adjustment (currentWindow.index == 0) carries the pre-adjustment '
        'amount, which is not visible on `original` once it has been '
        'patched to the new amount', () async {
      final original = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      final adjusted = await insertBudget(
        amountMinor: 50000,
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
      );
      // Does not match `original.amountMinor` (100000): still found, because
      // the search is purely shape-based (startDate/endDate/cadence).
      final resume = await insertBudget(
        amountMinor: 75000,
        startDate: DateTime(2026, 9, 1),
      );

      final found = await datasource.findResumeFork(original, adjusted);

      expect(found?.id, resume.id);
    });

    test('returns null when the candidate is not open-ended', () async {
      final original = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      final adjusted = await insertBudget(
        amountMinor: 50000,
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
      );
      // Same amount and start, but itself has an endDate: not the indefinite
      // resume fork (ambiguous with another adjusted fork's shape).
      await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
      );

      final found = await datasource.findResumeFork(original, adjusted);

      expect(found, isNull);
    });

    test('returns null when the adjusted fork itself has no endDate',
        () async {
      final original = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      final openEndedAdjusted = await insertBudget(
        amountMinor: 50000,
        startDate: DateTime(2026, 8, 1),
      );

      final found =
          await datasource.findResumeFork(original, openEndedAdjusted);

      expect(found, isNull);
    });
  });

  group('applyAmountAdjustment / cancelAmountAdjustment', () {
    test('applies the fork atomically and cancel reverses it completely',
        () async {
      final original = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
      );

      await datasource.applyAmountAdjustment(
        originalId: original.id,
        closeCompanion: BudgetsCompanion(
          endDate: Value(DateTime(2026, 7, 31)),
          updatedAt: const Value(1),
        ),
        adjustedCompanion: BudgetsCompanion.insert(
          name: original.name,
          icon: Value(original.icon),
          amountMinor: 50000,
          currency: original.currency,
          period: original.period,
          startDate: DateTime(2026, 8, 1),
          endDate: Value(DateTime(2026, 8, 31)),
          updatedAt: const Value(1),
        ),
        resumeCompanion: BudgetsCompanion.insert(
          name: original.name,
          icon: Value(original.icon),
          amountMinor: 100000,
          currency: original.currency,
          period: original.period,
          startDate: DateTime(2026, 9, 1),
          updatedAt: const Value(1),
        ),
        accountIds: const {},
        categoryIds: const {},
        now: DateTime(2026, 7, 15),
      );

      final closedOriginal = await datasource.getBudget(original.id);
      expect(closedOriginal?.endDate, DateTime(2026, 7, 31));

      final adjusted = await datasource.findAdjustedFork(closedOriginal!);
      expect(adjusted, isNotNull);
      expect(adjusted?.amountMinor, 50000);

      final resume = await datasource.findResumeFork(closedOriginal, adjusted!);
      expect(resume, isNotNull);
      expect(resume?.amountMinor, 100000);

      await datasource.cancelAmountAdjustment(
        originalId: original.id,
        adjustedId: adjusted.id,
        resumeId: resume?.id,
        reopenCompanion: const BudgetsCompanion(
          endDate: Value(null),
          updatedAt: Value(2),
        ),
        now: DateTime(2026, 7, 16),
      );

      final reopened = await datasource.getBudget(original.id);
      expect(reopened?.endDate, isNull);
      expect(await datasource.getBudget(adjusted.id), isNull);
      expect(await datasource.getBudget(resume!.id), isNull);
    });
  });

  group(
      'applyAmountAdjustmentInPlace / cancelAmountAdjustment '
      '(currentWindow.index == 0)', () {
    test(
        'patches the original in place and cancel restores it without '
        'touching its id', () async {
      final original = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
      );

      await datasource.applyAmountAdjustmentInPlace(
        originalId: original.id,
        adjustedCompanion: BudgetsCompanion(
          amountMinor: const Value(50000),
          endDate: Value(DateTime(2026, 7, 31)),
          updatedAt: const Value(1),
        ),
        resumeCompanion: BudgetsCompanion.insert(
          name: original.name,
          icon: Value(original.icon),
          amountMinor: 100000,
          currency: original.currency,
          period: original.period,
          startDate: DateTime(2026, 8, 1),
          updatedAt: const Value(1),
        ),
        accountIds: const {},
        categoryIds: const {},
        now: DateTime(2026, 7, 15),
      );

      final patched = await datasource.getBudget(original.id);
      expect(patched?.id, original.id);
      expect(patched?.amountMinor, 50000);
      expect(patched?.endDate, DateTime(2026, 7, 31));

      final resume = await datasource.findResumeFork(patched!, patched);
      expect(resume, isNotNull);
      expect(resume?.amountMinor, 100000);

      // Cancelling the in-place shape: `adjustedId == originalId`, so the
      // original row is restored (not hard-deleted) and only the resume fork
      // is removed.
      await datasource.cancelAmountAdjustment(
        originalId: original.id,
        adjustedId: original.id,
        resumeId: resume?.id,
        reopenCompanion: const BudgetsCompanion(
          amountMinor: Value(100000),
          endDate: Value(null),
          updatedAt: Value(2),
        ),
        now: DateTime(2026, 7, 16),
      );

      final reopened = await datasource.getBudget(original.id);
      expect(reopened, isNotNull);
      expect(reopened?.id, original.id);
      expect(reopened?.amountMinor, 100000);
      expect(reopened?.endDate, isNull);
      expect(await datasource.getBudget(resume!.id), isNull);
    });

    test(
        'cancelling a scoped fork tombstones the adjusted/resume rows '
        'instead of hard-deleting them, so their BudgetAccounts scope rows '
        'keep a live referent', () async {
      final account = await database.into(database.accounts).insertReturning(
            AccountsCompanion.insert(
              name: 'Nu',
              type: AccountType.bank,
              currency: 'COP',
              updatedAt: const Value(0),
            ),
          );
      final original = await insertBudget(
        amountMinor: 100000,
        startDate: DateTime(2026, 7, 1),
      );

      await datasource.applyAmountAdjustment(
        originalId: original.id,
        closeCompanion: BudgetsCompanion(
          endDate: Value(DateTime(2026, 7, 31)),
          updatedAt: const Value(1),
        ),
        adjustedCompanion: BudgetsCompanion.insert(
          name: original.name,
          icon: Value(original.icon),
          amountMinor: 50000,
          currency: original.currency,
          period: original.period,
          startDate: DateTime(2026, 8, 1),
          endDate: Value(DateTime(2026, 8, 31)),
          updatedAt: const Value(1),
        ),
        resumeCompanion: BudgetsCompanion.insert(
          name: original.name,
          icon: Value(original.icon),
          amountMinor: 100000,
          currency: original.currency,
          period: original.period,
          startDate: DateTime(2026, 9, 1),
          updatedAt: const Value(1),
        ),
        accountIds: {account.id},
        categoryIds: const {},
        now: DateTime(2026, 7, 15),
      );

      final closedOriginal = await datasource.getBudget(original.id);
      final adjusted = await datasource.findAdjustedFork(closedOriginal!);
      final resume = await datasource.findResumeFork(closedOriginal, adjusted!);

      await datasource.cancelAmountAdjustment(
        originalId: original.id,
        adjustedId: adjusted.id,
        resumeId: resume?.id,
        reopenCompanion: const BudgetsCompanion(
          endDate: Value(null),
          updatedAt: Value(2),
        ),
        now: DateTime(2026, 7, 16),
      );

      // Excluded from every alive-only read path, exactly like a hard
      // delete would behave from the caller's point of view.
      expect(await datasource.getBudget(adjusted.id), isNull);
      expect(await datasource.getBudget(resume!.id), isNull);

      // But the row itself still physically exists (tombstoned, not gone),
      // so the BudgetAccounts row `reconcileScope` wrote for it during
      // `applyAmountAdjustment` still points at a real budget.
      final adjustedRaw = await (database.select(database.budgets)
            ..where((b) => b.id.equals(adjusted.id)))
          .getSingle();
      expect(adjustedRaw.tombstonedAt, isNotNull);

      final resumeRaw = await (database.select(database.budgets)
            ..where((b) => b.id.equals(resume.id)))
          .getSingle();
      expect(resumeRaw.tombstonedAt, isNotNull);

      final adjustedScopeRow = await (database.select(database.budgetAccounts)
            ..where((r) => r.budgetId.equals(adjusted.id)))
          .getSingle();
      expect(adjustedScopeRow.accountId, account.id);
    });
  });
}
