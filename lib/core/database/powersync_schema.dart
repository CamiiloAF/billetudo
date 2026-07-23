// PowerSync's client-side schema (decision #6, docs/requirements/05-auth-sync.md).
//
// This mirrors the 15 tables in `app_database.dart` that carry `_SyncColumns`
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
//
// **Postgres must match these types, not the other way around** (decision #15,
// docs/requirements/05-auth-sync.md). Drift reads through PowerSync's *views*,
// where every column is a `CAST(json_extract(data,'$.col') AS <type>)`. A date
// column typed `timestamptz` in Postgres arrives as text, and SQLite's
// `CAST('2026-07-17...' AS INTEGER)` silently yields `2026` — every server-born
// row then reads as 1970 on device, while device-born rows are rejected on
// upload and dropped as a fatal `22xxx`. So in Postgres a `DateTimeColumn` is
// `bigint` in unix SECONDS and `updatedAt` is `bigint` in MILLIseconds. Never
// `timestamptz` on a synced table.
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
    Column.text('accrual_mode'),
    // Soft UUID FK to the disbursement transaction holding the opening balance
    // (schemaVersion 15). Nullable; see Debts.initialTransactionId.
    Column.text('initial_transaction_id'),
    ..._syncColumns,
  ]),
  // Solo-deuda ledger entries (schemaVersion 14). The outstanding balance is
  // derived, so there is no balance column here or in Postgres.
  Table('debt_entries', [
    Column.text('debt_id'),
    Column.text('kind'),
    Column.integer('amount_minor'),
    Column.integer('entry_date'),
    Column.text('note'),
    Column.integer('rate_bps_snapshot'),
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
    Column.integer('first_payment_date'),
    Column.integer('next_date'),
    Column.integer('end_date'),
    Column.integer('requires_confirmation'),
    Column.text('debt_id'),
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
  Table('budget_period_overrides', [
    Column.text('budget_id'),
    Column.integer('period_start'),
    Column.integer('amount_minor'),
    ..._syncColumns,
  ]),
  Table('app_settings', [
    Column.integer('zero_based_enabled'),
    Column.integer('categories_seeded'),
    ..._syncColumns,
  ]),
]);
