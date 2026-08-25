/// One foreign-key column in a `.billetudo.json` backup table: [column] is
/// the camelCase JSON key (ej. `'accountId'`), [targetTable] is the backup
/// table name (same camelCase keys as `BackupJsonDatasource.backupTableNames`)
/// the id in that column points at.
class BackupFkColumn {
  const BackupFkColumn({required this.column, required this.targetTable});

  final String column;
  final String targetTable;
}

/// Every FK column across the ~19 tables a `.billetudo.json` backup carries,
/// mirroring `core/database/app_database.dart`'s `.references(...)` columns
/// **plus** the three that are FKs in meaning but not in Drift (no
/// `.references()`, so no schema-level cycle):
///  - `goalContributions.transactionId` (a contribution can predate its
///    transaction during an undo/redo window — see `app_database.dart`).
///  - `debts.initialTransactionId` (same reason, `Transactions.debtId`
///    already points the other way).
///  - `appSettings.featuredBudgetId` (never declared `.references()` at all
///    — `AppSettings` predates that column having a real FK target).
///
/// Consumed by `ResolveBackupIdConflicts` to rewrite every column that
/// points at a remapped id — restoring a backup under a different Supabase
/// account than the one that originally synced some of its ids must never
/// leave a dangling or, worse, silently-wrong reference after the remap.
///
/// `appSettings`'s own `id` column is intentionally never a *source* of a
/// remap (see `ResolveBackupIdConflicts`): it is a fixed singleton
/// (`AppSettings.id` defaults to the literal `'app'`), so every account
/// legitimately has a row with that same id — that is not the "same id,
/// different account" collision this whole feature exists to fix. It is
/// still a valid FK *target* here for `featuredBudgetId`... except
/// `featuredBudgetId` points at `budgets`, never at `appSettings` itself, so
/// `appSettings` never appears as a `targetTable` below either.
const Map<String, List<BackupFkColumn>> backupFkColumnsByTable = {
  'accounts': [
    BackupFkColumn(column: 'importBatchId', targetTable: 'importBatches'),
  ],
  'categories': [
    BackupFkColumn(column: 'parentId', targetTable: 'categories'),
    BackupFkColumn(column: 'importBatchId', targetTable: 'importBatches'),
  ],
  'transactions': [
    BackupFkColumn(column: 'accountId', targetTable: 'accounts'),
    BackupFkColumn(column: 'categoryId', targetTable: 'categories'),
    BackupFkColumn(column: 'transferAccountId', targetTable: 'accounts'),
    BackupFkColumn(
      column: 'scheduledPaymentId',
      targetTable: 'scheduledPayments',
    ),
    BackupFkColumn(column: 'goalId', targetTable: 'goals'),
    BackupFkColumn(column: 'debtId', targetTable: 'debts'),
    BackupFkColumn(column: 'importBatchId', targetTable: 'importBatches'),
  ],
  'goals': [
    BackupFkColumn(column: 'accountId', targetTable: 'accounts'),
  ],
  'goalContributions': [
    BackupFkColumn(column: 'goalId', targetTable: 'goals'),
    // Soft FK: no `.references()` in Drift (see the class doc above).
    BackupFkColumn(column: 'transactionId', targetTable: 'transactions'),
  ],
  'goalQuickAmounts': [
    BackupFkColumn(column: 'goalId', targetTable: 'goals'),
  ],
  'debts': [
    // Soft FK: no `.references()` in Drift (see the class doc above).
    BackupFkColumn(
      column: 'initialTransactionId',
      targetTable: 'transactions',
    ),
  ],
  'debtEntries': [
    BackupFkColumn(column: 'debtId', targetTable: 'debts'),
  ],
  'scheduledPayments': [
    BackupFkColumn(column: 'accountId', targetTable: 'accounts'),
    BackupFkColumn(column: 'categoryId', targetTable: 'categories'),
    BackupFkColumn(column: 'transferAccountId', targetTable: 'accounts'),
    BackupFkColumn(column: 'debtId', targetTable: 'debts'),
    BackupFkColumn(column: 'goalId', targetTable: 'goals'),
  ],
  'scheduledPaymentOccurrences': [
    BackupFkColumn(
      column: 'scheduledPaymentId',
      targetTable: 'scheduledPayments',
    ),
    BackupFkColumn(
      column: 'generatedTransactionId',
      targetTable: 'transactions',
    ),
  ],
  'tags': [
    BackupFkColumn(column: 'importBatchId', targetTable: 'importBatches'),
  ],
  'transactionTags': [
    BackupFkColumn(column: 'transactionId', targetTable: 'transactions'),
    BackupFkColumn(column: 'tagId', targetTable: 'tags'),
  ],
  'scheduledPaymentTags': [
    BackupFkColumn(
      column: 'scheduledPaymentId',
      targetTable: 'scheduledPayments',
    ),
    BackupFkColumn(column: 'tagId', targetTable: 'tags'),
  ],
  'budgetAccounts': [
    BackupFkColumn(column: 'budgetId', targetTable: 'budgets'),
    BackupFkColumn(column: 'accountId', targetTable: 'accounts'),
  ],
  'budgetCategories': [
    BackupFkColumn(column: 'budgetId', targetTable: 'budgets'),
    BackupFkColumn(column: 'categoryId', targetTable: 'categories'),
  ],
  'budgetPeriodOverrides': [
    BackupFkColumn(column: 'budgetId', targetTable: 'budgets'),
  ],
  'appSettings': [
    // Soft FK: no `.references()` in Drift (see the class doc above).
    BackupFkColumn(column: 'featuredBudgetId', targetTable: 'budgets'),
  ],
};
