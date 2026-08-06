import 'package:billetudo/core/crash/noop_crash_reporter.dart';
import 'package:billetudo/core/database/app_database.dart'
    hide CategoryKind, AccountType;
import 'package:billetudo/core/database/app_database.dart' as schema
    show CategoryKind;
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/security/secure_storage_service.dart';
import 'package:billetudo/features/accounts/data/datasources/account_number_local_datasource.dart';
import 'package:billetudo/features/accounts/data/datasources/accounts_local_datasource.dart';
import 'package:billetudo/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart'
    show AccountType;
import 'package:billetudo/features/accounts/domain/entities/account_draft.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/goals/data/datasources/goals_local_datasource.dart';
import 'package:billetudo/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:billetudo/features/goals/domain/services/goal_coherence_calculator.dart';
import 'package:billetudo/features/goals/domain/services/goal_milestone_tracker.dart';
import 'package:billetudo/features/goals/domain/services/goal_momentum_calculator.dart';
import 'package:billetudo/features/goals/domain/services/goal_progress_calculator.dart';
import 'package:billetudo/features/goals/domain/services/goal_projection_calculator.dart';
import 'package:billetudo/features/home/domain/entities/home_snapshot.dart';
import 'package:billetudo/features/home/domain/usecases/watch_month_transactions.dart';
import 'package:billetudo/features/transactions/data/datasources/tags_local_datasource.dart';
import 'package:billetudo/features/transactions/data/datasources/transactions_local_datasource.dart';
import 'package:billetudo/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart'
    as domain;
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/domain/usecases/watch_transactions.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

/// Reproduces bugfix item 7 end to end with the real repositories wired
/// together (no mocked transaction/account data): a real Drift account, a
/// real "Arriendo" expense on 1 de agosto, and both consumers of
/// [TransactionRepositoryImpl] — the Home unit ([WatchMonthTransactions]) and
/// Movimientos' own unit ([WatchTransactions], through its default filter —
/// "este mes") — queried the same way each screen actually queries them.
///
/// The point of this test is to prove (or disprove) a divergence at the
/// query/aggregation level, as opposed to a runtime-only UI/state timing
/// issue that a pure unit test cannot see.
void main() {
  late AppDatabase db;
  late AccountRepositoryImpl accountRepository;
  late TransactionRepositoryImpl transactionRepository;
  late WatchMonthTransactions watchMonthTransactions;
  late WatchTransactions watchTransactions;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final storage = MockSecureStorageService();
    when(() => storage.write(any(), any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => storage.read(any())).thenAnswer((_) async => const Right(null));
    when(() => storage.delete(any()))
        .thenAnswer((_) async => const Right(unit));
    accountRepository = AccountRepositoryImpl(
      AccountsLocalDatasource(db),
      AccountNumberLocalDatasource(storage),
      const NoopCrashReporter(),
    );
    transactionRepository = TransactionRepositoryImpl(
      TransactionsLocalDatasource(db),
      TagsLocalDatasource(db),
      GoalRepositoryImpl(
        GoalsLocalDatasource(db),
        const GoalProgressCalculator(),
        const GoalMilestoneTracker(),
        const GoalProjectionCalculator(),
        const GoalMomentumCalculator(),
        const GoalCoherenceCalculator(),
        const NoopCrashReporter(),
      ),
      const NoopCrashReporter(),
    );
    watchMonthTransactions = WatchMonthTransactions(transactionRepository);
    watchTransactions = WatchTransactions(transactionRepository);
  });

  tearDown(() => db.close());

  test(
    'Home (WatchMonthTransactions) y Movimientos (WatchTransactions, "este '
    'mes") ven el mismo gasto de agosto en la misma cuenta activa',
    () async {
      final account = await accountRepository
          .createAccount(
            const AccountDraft(
              name: 'Ahorros Bancolombia',
              type: AccountType.savings,
              currency: 'COP',
            ),
          )
          .then((r) => r.getRight().toNullable()!);

      final category = await db.into(db.categories).insertReturning(
            CategoriesCompanion.insert(
              name: 'Arriendo',
              kind: schema.CategoryKind.expense,
            ),
          );

      final month = DateTime(2026, 8);
      final txDate = DateTime(2026, 8, 1);

      await transactionRepository.createTransaction(
        TransactionDraft(
          accountId: account.id,
          categoryId: category.id,
          categoryKind: CategoryKind.expense,
          amountMinor: 73000000,
          currency: 'COP',
          type: domain.TransactionType.expense,
          date: txDate,
        ),
      );

      final accounts = await accountRepository
          .watchActiveAccounts()
          .first
          .then((r) => r.getRight().toNullable()!);
      expect(
        accounts.map((e) => e.account.id),
        contains(account.id),
        reason: 'the account must be active, same as the Movimientos strip',
      );

      final homeTransactions = await watchMonthTransactions(month)
          .first
          .then((r) => r.getRight().toNullable()!);
      // Same shape Movimientos' default filter builds via
      // `TransactionFilter()`/`DatePeriodFilter.thisMonth()`, anchored on
      // the same month instead of the real wall clock so the test does not
      // depend on when it happens to run.
      final movimientosTransactions = await watchTransactions(
        TransactionFilter(
          datePeriod: DatePeriodFilter.thisMonth(month),
        ),
      ).first.then((r) => r.getRight().toNullable()!);

      expect(
        homeTransactions.map((e) => e.transaction.id),
        movimientosTransactions.map((e) => e.transaction.id),
        reason: 'both screens must see the exact same set of transactions '
            'for the same month',
      );
      expect(homeTransactions, hasLength(1));

      final snapshot = HomeSnapshot.from(
        month: month,
        transactions: homeTransactions,
        accounts: accounts,
      );
      expect(
        snapshot.isEmpty,
        isFalse,
        reason: 'the movement must reach the recent-activity feed',
      );
      expect(snapshot.spending.displayTotalMinor, 73000000);
    },
  );
}
