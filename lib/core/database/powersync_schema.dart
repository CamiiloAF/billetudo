// PowerSync's client-side schema (decision #6, docs/requirements/05-auth-sync.md).
//
// This mirrors the 14 tables in `app_database.dart` that carry `_SyncColumns`
// — same table and column names (snake_case), matching the Postgres schema
// created for HU-04/HU-05 sync. There is no codegen deriving one schema from
// the other, so **any change to a `_SyncColumns` table in `app_database.dart`
// must be mirrored here by hand** (see `drift-migration-helper`).
//
// `id` is never declared as a column: PowerSync manages it implicitly for
// every table (`Table.validate()` rejects a custom `id` column).
//
// Column types mirror how Drift actually serializes each column to SQLite,
// not just its Dart type:
//  - TextColumn -> Column.text.
//  - BoolColumn -> Column.integer (SQLite has no native boolean; Drift stores
//    0/1).
//  - IntColumn -> Column.integer.
//  - DateTimeColumn -> Column.integer. Drift's default (this database does not
//    set `storeDateTimeAsText`) stores DateTime as a Unix timestamp in whole
//    seconds. `updatedAt` is already a Drift `IntColumn` (epoch millis, see
//    `_SyncColumns.updatedAt`) rather than a `DateTimeColumn`, but it maps to
//    the same PowerSync `Column.integer`.
import 'package:powersync/powersync.dart';

/// Columns shared by every table with Drift's `_SyncColumns` mixin, minus
/// `id` (implicit). Spread into each table's column list below.
const _syncColumns = [
  Column.integer('created_at'),
  Column.integer('updated_at'),
  Column.integer('deleted_at'),
  Column.integer('tombstoned_at'),
  Column.text('user_id'),
];

/// Mirrors `AppDatabase` (`lib/core/database/app_database.dart`).
const powerSyncSchema = Schema([
  Table('accounts', [
    Column.text('name'),
    Column.text('type'),
    Column.text('currency'),
    Column.integer('initial_balance_minor'),
    Column.text('icon'),
    Column.text('color'),
    Column.integer('archived'),
    Column.integer('sort_order'),
    Column.text('institution'),
    Column.text('last4'),
    Column.integer('interest_rate_bps'),
    Column.integer('credit_limit_minor'),
    Column.integer('statement_day'),
    Column.integer('payment_due_day'),
    Column.text('card_balance_primary'),
    ..._syncColumns,
  ]),
  Table('categories', [
    Column.text('name'),
    Column.text('kind'),
    Column.text('parent_id'),
    Column.text('icon'),
    Column.text('color'),
    Column.integer('sort_order'),
    ..._syncColumns,
  ]),
  Table('transactions', [
    Column.text('account_id'),
    Column.text('category_id'),
    Column.integer('amount_minor'),
    Column.text('currency'),
    Column.text('type'),
    Column.integer('date'),
    Column.text('note'),
    Column.text('source'),
    Column.text('transfer_account_id'),
    Column.text('scheduled_payment_id'),
    Column.text('goal_id'),
    Column.text('debt_id'),
    ..._syncColumns,
  ]),
  Table('budgets', [
    Column.text('name'),
    Column.text('icon'),
    Column.integer('amount_minor'),
    Column.text('currency'),
    Column.text('period'),
    Column.integer('start_date'),
    Column.integer('recurring'),
    Column.integer('end_date'),
    Column.integer('archived_at'),
    Column.integer('alert_threshold_pct'),
    Column.integer('rollover'),
    ..._syncColumns,
  ]),
  Table('goals', [
    Column.text('name'),
    Column.integer('target_minor'),
    Column.integer('saved_minor'),
    Column.text('currency'),
    Column.text('account_id'),
    Column.integer('target_date'),
    Column.text('icon'),
    Column.text('color'),
    ..._syncColumns,
  ]),
  Table('debts', [
    Column.text('name'),
    Column.text('direction'),
    Column.integer('principal_minor'),
    Column.text('currency'),
    Column.integer('interest_rate_bps'),
    Column.text('counterparty'),
    Column.integer('due_date'),
    ..._syncColumns,
  ]),
  Table('scheduled_payments', [
    Column.text('account_id'),
    Column.text('category_id'),
    Column.integer('amount_minor'),
    Column.text('currency'),
    Column.text('type'),
    Column.text('note'),
    Column.text('transfer_account_id'),
    Column.text('frequency'),
    Column.integer('interval'),
    Column.integer('next_date'),
    Column.integer('end_date'),
    Column.integer('requires_confirmation'),
    ..._syncColumns,
  ]),
  Table('tags', [
    Column.text('name'),
    Column.text('color'),
    ..._syncColumns,
  ]),
  Table('transaction_tags', [
    Column.text('transaction_id'),
    Column.text('tag_id'),
    ..._syncColumns,
  ]),
  Table('scheduled_payment_tags', [
    Column.text('scheduled_payment_id'),
    Column.text('tag_id'),
    ..._syncColumns,
  ]),
  Table('scheduled_payment_occurrences', [
    Column.text('scheduled_payment_id'),
    Column.integer('occurrence_date'),
    Column.text('status'),
    Column.integer('snoozed_to_date'),
    Column.text('generated_transaction_id'),
    ..._syncColumns,
  ]),
  Table('budget_accounts', [
    Column.text('budget_id'),
    Column.text('account_id'),
    ..._syncColumns,
  ]),
  Table('budget_categories', [
    Column.text('budget_id'),
    Column.text('category_id'),
    ..._syncColumns,
  ]),
  Table('app_settings', [
    Column.integer('zero_based_enabled'),
    Column.integer('categories_seeded'),
    ..._syncColumns,
  ]),
]);
