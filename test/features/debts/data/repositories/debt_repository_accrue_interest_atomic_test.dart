import 'package:billetudo/core/crash/noop_crash_reporter.dart';
import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/debts/data/datasources/debts_local_datasource.dart';
import 'package:billetudo/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:billetudo/features/debts/domain/services/debt_balance_calculator.dart';
import 'package:billetudo/features/debts/domain/services/debt_interest_calculator.dart';
import 'package:billetudo/features/debts/domain/usecases/accrue_interest.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Money-bug regression coverage (severity: alta): two concurrent calls to
/// `AccrueInterest` for the same debt — the cross-cubit race
/// (`DebtsListCubit` still iterating while `DebtDetailCubit` opens the same
/// debt) that no in-memory re-entrancy guard can prevent, because the two
/// calls do not share a flag. Only `DebtRepositoryImpl.accrueInterestAtomic`'s
/// Drift transaction (read `lastAccrualDate` + write the `interestAccrual`
/// row, atomically) can — this exercises that against a real in-memory
/// database, not a mock, since the guarantee is about actual transaction
/// serialization.
void main() {
  late AppDatabase db;
  late DebtsLocalDatasource local;
  late DebtRepositoryImpl repository;
  late AccrueInterest accrueInterest;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = DebtsLocalDatasource(db);
    repository = DebtRepositoryImpl(
      local,
      const DebtBalanceCalculator(),
      const NoopCrashReporter(),
    );
    accrueInterest = AccrueInterest(repository, const DebtInterestCalculator());
  });

  tearDown(() => db.close());

  Future<Debt> createAutoDebt() => db.into(db.debts).insertReturning(
        DebtsCompanion.insert(
          name: 'Crédito',
          direction: DebtDirection.iOwe,
          principalMinor: 1000000,
          currency: 'COP',
          accrualMode: const Value(DebtAccrualMode.auto),
          interestRateBps: const Value(3650),
          updatedAt: const Value(0),
        ),
      );

  Future<List<DebtEntry>> interestEntries(String debtId) async {
    final rows = await local.getDebtEntries(debtId);
    return rows.where((e) => e.kind == DebtEntryKind.interestAccrual).toList();
  }

  test(
    'two concurrent AccrueInterest calls for the same debt post the '
    'interest only once, not twice',
    () async {
      final debt = await createAutoDebt();
      final upTo = debt.createdAt.add(const Duration(days: 1));

      // Fired together, neither awaited before the other starts — the exact
      // shape of the cross-cubit race described in the bug report.
      final results = await Future.wait([
        accrueInterest(debtId: debt.id, upTo: upTo),
        accrueInterest(debtId: debt.id, upTo: upTo),
      ]);

      // Exactly one of the two calls posts the entry; the other's atomic
      // re-read sees the first one's write already committed and finds
      // nothing left to accrue for the same span.
      final posted = results.where((r) => r.getRight().toNullable() != null);
      expect(posted.length, 1);

      final entries = await interestEntries(debt.id);
      expect(entries, hasLength(1));
      expect(entries.single.amountMinor, 1000); // 0.1% of 1,000,000, 1 day
    },
  );

  test(
    'three concurrent calls for the same debt still post exactly one entry',
    () async {
      final debt = await createAutoDebt();
      final upTo = debt.createdAt.add(const Duration(days: 1));

      await Future.wait([
        accrueInterest(debtId: debt.id, upTo: upTo),
        accrueInterest(debtId: debt.id, upTo: upTo),
        accrueInterest(debtId: debt.id, upTo: upTo),
      ]);

      final entries = await interestEntries(debt.id);
      expect(entries, hasLength(1));
    },
  );
}
