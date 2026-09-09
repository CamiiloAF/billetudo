/// Every table with `_SyncColumns.userId` (see `core/database/app_database.dart`),
/// mirrored in `core/database/powersync_schema.dart`.
///
/// Shared source of truth so the two flows that walk every owned table in
/// lockstep never drift apart from each other:
///
///  - HU-04's claim step (`features/auth/data/datasources/local_data_ownership_datasource.dart`):
///    stamps `user_id` on rows with `user_id IS NULL`.
///  - The account-conflict detection on login
///    (`features/auth/data/datasources/local_data_conflict_datasource.dart`):
///    looks for a row already owned by a *different* account, i.e.
///    `user_id IS NOT NULL AND user_id != <incoming id>` — the exact inverse
///    of HU-04's `IS NULL` check.
const ownedTables = [
  'accounts',
  'categories',
  'transactions',
  'budgets',
  'goals',
  'debts',
  'scheduled_payments',
  'tags',
  'transaction_tags',
  'budget_accounts',
  'budget_categories',
  'budget_period_overrides',
  'app_settings',
  // Fase 2. Both are written before the user ever signs in (a capture can land
  // while the app is still anonymous), so they must be claimed like the rest.
  'pending_captures',
  'merchant_category_learning',
];
