// PowerSync's client-side schema (decision #6, docs/requirements/fase-1/05-auth-sync.md).
//
// This mirrors the tables in `app_database.dart` that carry `_SyncColumns`
// — same table and column names (snake_case), matching the Postgres schema
// created for HU-04/HU-05 sync. There is no codegen deriving one schema from
// the other, so **any change to a `_SyncColumns` table in `app_database.dart`
// must be mirrored here by hand** (see `drift-migration-helper`).
//
// Two tables here are NOT synced: `ai_messages` and
// `ai_insight_conversations`, both declared with `Table.localOnly` at the
// bottom. They are still declared in this schema because PowerSync — not
// Drift — owns the physical storage of every table this app reads through,
// local-only ones included. See their comments for why the AI conversation
// (and what links to it) never leaves the device.
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
// docs/requirements/fase-1/05-auth-sync.md). Drift reads through PowerSync's *views*,
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
    // Last 4 digits of the CARD attached to this account (schemaVersion 34,
    // Fase 2 captura). Distinct from `last4`, which identifies the account;
    // this one is what a notification's `account_hint` is matched against.
    // Nullable = unknown / no card. See Accounts.cardLast4.
    Column.text('card_last4'),
    // The import batch this account was created by (schemaVersion 25).
    // Nullable = created by hand; see Accounts.importBatchId.
    Column.text('import_batch_id'),
    ..._syncColumns,
  ]),
  Table('categories', [
    Column.text('name'),
    Column.text('kind'),
    Column.text('parent_id'),
    Column.text('icon'),
    Column.text('color'),
    Column.integer('sort_order'),
    // The import batch this category was created by (schemaVersion 25).
    // Nullable = created by hand (or a `seed-*` catalog category); see
    // Categories.importBatchId.
    Column.text('import_batch_id'),
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
    Column.integer('counts_in_budget'),
    // The import batch this transaction was created by (schemaVersion 25).
    // Nullable = not from an import; see Transactions.importBatchId.
    Column.text('import_batch_id'),
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
    Column.text('currency'),
    Column.text('account_id'),
    Column.integer('target_date'),
    Column.text('icon'),
    // Completion timestamp (schemaVersion 19). Epoch seconds like every
    // DateTimeColumn. Nullable = not completed. Business-state flag; see
    // Goals.completedAt.
    Column.integer('completed_at'),
    // Archive timestamp (schemaVersion 19). Epoch seconds. Nullable =
    // active; see Goals.archivedAt.
    Column.integer('archived_at'),
    // Highest milestone percent already celebrated (schemaVersion 19); see
    // Goals.lastMilestonePct.
    Column.integer('last_milestone_pct'),
    ..._syncColumns,
  ]),
  // Ledger of contribution/withdrawal movements against a goal (schemaVersion
  // 19). A goal's saved amount is DERIVED by summing these — there is no
  // `saved_minor` column here or on `goals`; see GoalContributions.
  Table('goal_contributions', [
    Column.text('goal_id'),
    Column.integer('amount_minor'),
    Column.text('direction'),
    Column.integer('date'),
    // Soft UUID FK to the transaction this movement mirrors, when it moved
    // real money. Nullable = tracking-only movement; see
    // GoalContributions.transactionId.
    Column.text('transaction_id'),
    Column.text('note'),
    ..._syncColumns,
  ]),
  // User-defined "aporte rápido" chips per goal (schemaVersion 20). No trash
  // flow of its own — same as `tags`/`transaction_tags` — so `deleted_at`/
  // `tombstoned_at` go unused; removal is a real DELETE. See
  // GoalQuickAmounts.
  Table('goal_quick_amounts', [
    Column.text('goal_id'),
    Column.integer('amount_minor'),
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
    // The date the debt started (schemaVersion 16). Epoch seconds like every
    // DateTimeColumn (see the type comment above / due_date). Nullable; see
    // Debts.startDate.
    Column.integer('start_date'),
    // Manual closure timestamp (schemaVersion 17). Epoch seconds like every
    // DateTimeColumn. Nullable = active debt. Business-state flag, distinct
    // from deleted_at/tombstoned_at; see Debts.closedAt.
    Column.integer('closed_at'),
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
    // HU-16 (design-system/billetudo/pages/metas.md): links a template to a
    // recurring goal contribution. Nullable, exclusive with `debt_id` — see
    // `ScheduledPaymentDraft.validated()`.
    Column.text('goal_id'),
    // Days before the due date to fire a local reminder (schemaVersion 34).
    // Nullable, and NULL means "no reminder" — never backfilled, so a
    // template that predates the column stays silent. See
    // ScheduledPayments.reminderLeadDays.
    Column.integer('reminder_lead_days'),
    ..._syncColumns,
  ]),
  Table('tags', [
    Column.text('name'),
    Column.text('color'),
    // The import batch this tag was created by (schemaVersion 25). Nullable
    // = created by hand; see Tags.importBatchId.
    Column.text('import_batch_id'),
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
    Column.integer('onboarding_completed'),
    Column.text('featured_budget_id'),
    // Global on/off for contextual help minitutorials (schemaVersion 24).
    // Defaults to true; see AppSettings.showHelpOnSectionEntry.
    Column.integer('show_help_on_section_entry'),
    // Explicit resolution mode for the featured budget above: 'automatic' |
    // 'manual' | 'none' (schemaVersion 26). Nullable client-side since
    // schemaVersion 29 (decision #25, docs/requirements/fase-1/05-auth-sync.md):
    // a physical NULL (e.g. a row that synced before this column existed) is
    // treated as 'automatic' only in the read/mapping layer
    // (AppSettingsRepositoryImpl._toFeaturedBudgetMode), never backfilled
    // here. See AppSettings.featuredBudgetMode / FeaturedBudgetMode.
    Column.text('featured_budget_mode'),
    // Persisted order of the Home quick-access chips: comma-separated
    // `QuickAccessItem.name` values (schemaVersion 27). Null falls back to
    // the fixed default order. See AppSettings.quickAccessOrder.
    Column.text('quick_access_order'),
    // Consent to send data to a third-party AI model (schemaVersion 30, Apple
    // 5.1.2(i)). Epoch SECONDS like every Drift DateTimeColumn, so `bigint` in
    // Postgres — never `timestamptz` (see the type note at the top of this
    // file). Nullable = not consented yet / withdrawn; never backfilled. See
    // AppSettings.aiConsentAcceptedAt.
    Column.integer('ai_consent_accepted_at'),
    // Which version of the consent text the user accepted (schemaVersion 32).
    // Nullable; NULL is read as 0 (never backfilled), which is below the
    // current version and therefore re-asks for consent. See
    // AppSettings.aiConsentVersion.
    Column.integer('ai_consent_version'),
    // Opt-in permission for the assistant to read free-text notes
    // (schemaVersion 32). Boolean stored as integer 0/1 like every other
    // Drift BoolColumn here; non-nullable client-side, so the migration
    // backfills pre-existing rows to 0. See AppSettings.aiNotesAccessEnabled.
    Column.integer('ai_notes_access_enabled'),
    // Joint acceptance of the legal terms (privacy policy + terms of use),
    // one row/timestamp for both documents (schemaVersion 35). Epoch SECONDS
    // like every Drift DateTimeColumn, so `bigint` in Postgres — never
    // `timestamptz`. Nullable = not accepted yet on this installation; never
    // backfilled. See AppSettings.legalAcceptedAt.
    Column.integer('legal_accepted_at'),
    // Which version of the legal terms was accepted, alongside
    // `legal_accepted_at` (schemaVersion 35). This is the version of the
    // document(s) actually shown (cache or bundled fallback), never the
    // remote manifest's declared version. Nullable; NULL is read as 0
    // (never backfilled), which is below the current version and therefore
    // re-asks for acceptance. See AppSettings.legalAcceptedVersion.
    Column.integer('legal_accepted_version'),
    ..._syncColumns,
  ]),
  // Contextual help minitutorials: one row per tutorial key the user has
  // dismissed (schemaVersion 24). `id` is the tutorial's own stable key
  // (e.g. 'budgets_screen'), not a random UUID; see TutorialViews. No
  // extra columns beyond `_syncColumns` — a row's mere existence is the
  // "already seen" flag.
  Table('tutorial_views', [
    ..._syncColumns,
  ]),
  // One row per completed CSV import (schemaVersion 25,
  // docs/requirements/fase-1/11-import-export.md). Never deleted — `reverted_at`
  // marks a revert (HU-08) instead of removing the row, so the history
  // survives it.
  Table('import_batches', [
    Column.text('file_name'),
    Column.text('template_name'),
    Column.integer('imported_at'),
    Column.integer('rows_imported'),
    Column.integer('rows_skipped'),
    Column.integer('reverted_at'),
    ..._syncColumns,
  ]),
  // Review inbox of transaction candidates parsed from bank notifications
  // (schemaVersion 34, Fase 2) — see `PendingCaptures` in
  // `app_database.dart`. SYNCED on purpose (not `Table.localOnly`): the inbox
  // must survive a reinstall and a capture confirmed on one device must not
  // be re-proposed on another.
  //
  // **There is deliberately no column for the notification's literal text**
  // (`raw_text`/`title`/`big_text`), and none may be added here or in
  // Postgres: zero retention is a product decision, and anything declared
  // here would be uploaded and kept in backups. Only structured fields.
  //
  // `posted_at` is epoch SECONDS in `bigint` like every Drift DateTimeColumn
  // — never `timestamptz` on a synced table (see the type note at the top).
  Table('pending_captures', [
    Column.text('source'),
    Column.text('source_package'),
    Column.text('source_rule_id'),
    Column.integer('posted_at'),
    Column.integer('amount_minor'),
    Column.text('currency'),
    Column.text('entry_type'),
    Column.text('merchant_raw'),
    Column.text('account_hint'),
    Column.text('suggested_account_id'),
    Column.text('suggested_category_id'),
    Column.text('status'),
    Column.text('transaction_id'),
    Column.text('duplicate_of_transaction_id'),
    ..._syncColumns,
  ]),
  // Learned merchant -> category pairing (schemaVersion 34, Fase 2), so the
  // next capture from the same merchant arrives pre-categorized. Synced: the
  // learning belongs to the user and must follow them across devices. Holds
  // no notification content — a normalized merchant name and a category id.
  // `merchant_key` is UNIQUE (per user) in Postgres; see
  // `MerchantCategoryLearning` in `app_database.dart`.
  Table('merchant_category_learning', [
    Column.text('merchant_key'),
    Column.text('category_id'),
    Column.integer('hit_count'),
    ..._syncColumns,
  ]),
  // AI assistant chat history (schemaVersion 30). **The only local-only table
  // in this schema**, and the reason it exists as one is privacy, not
  // convenience: the conversation is the most sensitive text this app holds,
  // so it must never reach Postgres, the database backups, or the deletion
  // duties of `delete_account_data` (HU-07). `Table.localOnly` backs it with a
  // real local table (`ps_data_local__ai_messages`) whose writes are never
  // recorded in `ps_crud`, so there is structurally nothing to upload — see
  // `AiMessages` in `app_database.dart`.
  //
  // Consequences of local-only, both intended:
  //  - No `_syncColumns` here (no `user_id`, `deleted_at`, `tombstoned_at`);
  //    the Drift table carries none of them either.
  //  - `PowerSyncDatabase.disconnectAndClear()` DOES empty this table, because
  //    `clearLocal` defaults to `true` ("To preserve data in local-only
  //    tables, set clearLocal to false"). `LocalDataWipeDatasource.wipeAll`
  //    relies on exactly that.
  //
  // No `Index`: Fase A holds hundreds of rows at most, and every read is
  // either "the current conversation, ordered by created_at" or a full-table
  // sweep — a scan at that size is cheaper than the index it would maintain.
  // Add one here (never with a Drift `CREATE INDEX`, which fails against a
  // PowerSync view) if the history ever grows by an order of magnitude.
  Table.localOnly('ai_messages', [
    Column.text('conversation_id'),
    Column.text('role'),
    Column.text('content'),
    // Epoch MILLIS (not seconds): a Drift IntColumn, not a DateTimeColumn.
    // Local-only, so there is no Postgres counterpart to keep in step.
    Column.integer('created_at'),
    Column.text('status'),
    Column.text('proposals_json'),
  ]),
  // Links a Home AI insight chip (`HomeAiInsightType`) to the conversation it
  // started (schemaVersion 31), so the chip can reopen that exact thread
  // instead of whatever conversation is most recently active — see
  // `AiInsightConversations` in `app_database.dart`. Local-only for the same
  // reason as `ai_messages` right above: it only points at a conversation id
  // from that local-only history, so there is nothing cross-device to
  // resume. `Table.localOnly` backs it with a real local table
  // (`ps_data_local__ai_insight_conversations`) whose writes are never
  // recorded in `ps_crud`.
  //
  // No `_syncColumns` here either, and no `Index`: one row per link event
  // (never updated in place — see the Drift table's doc comment), and Fase A
  // holds at most a handful of insight types, so a full scan ordered by
  // `created_at` is cheap.
  Table.localOnly('ai_insight_conversations', [
    Column.text('insight_type'),
    Column.text('conversation_id'),
    Column.integer('created_at'),
  ]),
  // One "shown"/"dismissed" lifecycle event for a Home AI insight
  // (`HomeAiInsightType`), schemaVersion 33 — see `HomeInsightEvents` in
  // `app_database.dart`. Local-only for the same reason as
  // `ai_insight_conversations` right above: it is device-side UX
  // bookkeeping, not financial data, so there is nothing cross-device worth
  // syncing. `Table.localOnly` backs it with a real local table
  // (`ps_data_local__home_insight_events`) whose writes are never recorded
  // in `ps_crud`.
  //
  // No `_syncColumns` here either, and no `Index`: one row per event (never
  // updated in place — see the Drift table's doc comment), and this device
  // holds at most a handful of insight types times however many times a
  // month they fire, so a full scan ordered by `occurred_at` is cheap.
  Table.localOnly('home_insight_events', [
    Column.text('insight_type'),
    Column.text('kind'),
    Column.integer('occurred_at'),
  ]),
]);
