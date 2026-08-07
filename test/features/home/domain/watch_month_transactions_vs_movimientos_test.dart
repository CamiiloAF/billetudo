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
import 'package:billetudo/features/home/domain/usecases/watch_recent_transactions.dart';
import 'package:billetudo/features/transactions/data/datasources/tags_local_datasource.dart';
import 'package:billetudo/features/transactions/data/datasources/transactions_local_datasource.dart';
import 'package:billetudo/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart'
    as domain;
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

/// Was bugfix item 7 ("Home y Movimientos ven el mismo gasto del mes"),
/// covered by comparing `WatchMonthTransactions` against `WatchTransactions`.
/// That coupling is retired on purpose: "Movimientos recientes" is no longer
/// scoped to a month at all — it is a literal, unbound activity feed
/// (`WatchRecentTransactions`). This test now documents the replacement
/// invariant end to end with the real repositories wired together (no mocked
/// transaction/account data): a movement from a month **other than** the one
/// the hero happens to be showing must still reach `HomeSnapshot.recentActivity`.
void main() {
  late AppDatabase db;
  late AccountRepositoryImpl accountRepository;
  late TransactionRepositoryImpl transactionRepository;
  late WatchRecentTransactions watchRecentTransactions;

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
    watchRecentTransactions = WatchRecentTransactions(transactionRepository);
  });

  tearDown(() => db.close());

  test(
    '"Movimientos recientes" incluye un gasto de un mes distinto al que '
    'muestra el hero — el feed no está acotado por mes',
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

      // The hero is viewing agosto, but the movement itself happened in
      // julio — a month the hero is not currently showing.
      final heroMonth = DateTime(2026, 8);
      final txDate = DateTime(2026, 7, 1);

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

      final recent = await watchRecentTransactions()
          .first
          .then((r) => r.getRight().toNullable()!);
      expect(
        recent,
        hasLength(1),
        reason: 'watchRecentTransactions applies no date/period bound at all',
      );

      final snapshot = HomeSnapshot.from(
        month: heroMonth,
        // The hero's own spending total stays scoped to `heroMonth` — this
        // list is intentionally empty, agosto has no movements of its own.
        transactions: const [],
        accounts: accounts,
        recentTransactions: recent,
      );

      expect(
        snapshot.recentActivity.map((e) => e.transaction.id),
        recent.map((e) => e.transaction.id),
        reason: "julio's movement must reach the feed even while the hero "
            'shows agosto',
      );
      expect(
        snapshot.isEmpty,
        isFalse,
        reason: 'the movement must reach the recent-activity feed',
      );
      // The hero's spending stays $0 for agosto — unaffected by julio's
      // movement, which only fed the unbound recent-activity list.
      expect(snapshot.spending.displayTotalMinor, 0);
    },
  );
}
