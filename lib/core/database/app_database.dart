// Data model (Drift / SQLite) for the personal finance app.
// Local-first: this DB is the source of truth. PowerSync keeps it in sync with
// Supabase Postgres (same table and column names).
//
// Key conventions:
//  - IDs: UUID as text (clientDefault). Essential so PowerSync can sync rows
//    created offline across devices without collisions.
//  - Money: ALWAYS integers = minor units (cents). Never double, to avoid
//    rounding errors. E.g. $12.34 -> 1234.
//  - Timestamps: createdAt / updatedAt on every table. Update updatedAt on
//    each write (do it in the repository or with triggers).
//  - Deletion is TWO distinct columns, never one. See _SyncColumns:
//      * deletedAt: soft delete for "trash / undo" (a UX feature). Reversible.
//        PowerSync syncs real DELETEs on its own; deletedAt is only for the
//        user-facing trash, not for sync.
//      * tombstonedAt: referential-integrity tombstone. Irreversible. The row
//        must survive because other tables reference its id.
//
// Dependencies (pubspec):
//   drift, sqlite3_flutter_libs, uuid  (+ drift_dev, build_runner in dev)
//   For sync: powersync + drift integration (open Drift on the PowerSync DB).
//
// Generate the code with:  dart run build_runner build

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Enums (stored as text -> readable, and with parity in Postgres)
// ---------------------------------------------------------------------------

enum AccountType { cash, bank, card, savings, investment, other }

/// The nature of a transaction.
enum EntryType { income, expense, transfer }

/// What a category is for.
enum CategoryKind { income, expense }

/// How the transaction was created. Used to measure AI usage and calibrate
/// quotas: 'manual' and 'imported' cost nothing; voice/ocr/notification do.
enum TxSource { manual, voice, ocr, notification, imported, scheduled }

/// How often a budget repeats. `biweekly` is the es-CO semi-monthly fortnight
/// (two periods per month anchored to the start day), NOT a rolling 14 days.
enum BudgetPeriod { weekly, biweekly, monthly, yearly, custom }

enum DebtDirection { iOwe, owedToMe }

/// How often a scheduled payment repeats. `once` is a one-time future payment
/// (no repetition): it generates a single transaction on its date and then
/// goes inactive. See docs/requirements/09-pagos-programados.md.
enum ScheduleFrequency { once, daily, weekly, monthly, yearly }

/// Lifecycle of a single occurrence of a scheduled payment (as opposed to the
/// template itself). One row per due date that has been processed by the
/// catch-up generator (HU-02), used as the idempotency ledger so a due date
/// is never generated twice and never silently lost if the app closes
/// mid-run. See `ScheduledPaymentOccurrences` and
/// docs/requirements/09-pagos-programados.md.
///  - `pending`: manual-confirmation template (HU-03), due date reached, not
///    yet applied to the balance.
///  - `confirmed`: applied — a `Transaction` was generated (auto mode
///    reaches this directly; manual mode reaches it via user confirmation).
///  - `skipped`: user discarded it (HU-03), no transaction generated.
///  - `snoozed`: user moved only this occurrence to [snoozedToDate] (HU-07);
///    the template's cadence/`nextDate` is untouched.
enum ScheduledOccurrenceStatus { pending, confirmed, skipped, snoozed }

/// Which figure to highlight on a credit card (HU-04): 'debt' = show the
/// current debt as the headline; 'available' = the available credit. Affects
/// presentation only, never the balance calculation.
/// Stored as text (textEnum) for readable parity with Postgres.
enum CardBalanceView { debt, available }

// ---------------------------------------------------------------------------
// Mixin with the shared sync columns (UUID id + timestamps + soft delete)
// ---------------------------------------------------------------------------

mixin _SyncColumns on Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();

  /// `clientDefault`, not `.withDefault(currentDateAndTime)`: every
  /// `_SyncColumns` table is physically a PowerSync-managed view (see
  /// decision #14, docs/requirements/05-auth-sync.md), which has no real SQL
  /// column defaults — any column a raw or Drift-builder INSERT statement
  /// doesn't list explicitly comes back NULL, not this default. `clientDefault`
  /// computes the value in Dart and always includes it in the generated
  /// INSERT, so it survives being written through the view.
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  /// Epoch millis (NOT a Drift `DateTimeColumn`), unlike [createdAt].
  ///
  /// PowerSync/Supabase need a monotonic, sub-second-resolution value to
  /// resolve sync conflicts ("last write wins"); `DateTimeColumn` here is
  /// persisted as whole seconds, which is not fine-grained enough. Stamp it
  /// with `DateTime.now().millisecondsSinceEpoch` on every write.
  IntColumn get updatedAt =>
      integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch)();

  /// Soft delete for the user-facing **trash / undo**. null = not trashed.
  ///
  /// REVERSIBLE by design: the user can restore a trashed row, so an un-delete
  /// simply clears this column. It is a UX affordance and nothing else — it is
  /// not how deletion is propagated: PowerSync syncs real DELETEs on its own.
  ///
  /// Never use this column to keep a row alive for referential integrity; that
  /// is [tombstonedAt]. Conflating the two is what this pair of columns exists
  /// to prevent.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// **Referential-integrity tombstone**. null = not tombstoned.
  ///
  /// Stamped when the user deletes a row that other tables still reference by
  /// id (e.g. `Transactions.accountId` -> `Accounts.id`). The row must physically
  /// survive so those foreign keys keep pointing at something real, so it is
  /// hidden from every query instead of being removed.
  ///
  /// IRREVERSIBLE by design: there is no un-tombstone path, and the deletion may
  /// destroy data that lives outside this DB (e.g. the account number in secure
  /// storage), which no restore could bring back. Do not build undo on top of
  /// it — that is what [deletedAt] is for.
  DateTimeColumn get tombstonedAt => dateTime().nullable()();

  /// Logical (non-FK) reference to `auth.users.id` in Supabase. There is no
  /// local `users` table, so this cannot be a real SQLite foreign key.
  ///
  /// Nullable: the app is local-first, so rows created without a session have
  /// no owner yet. It is filled once the user signs in and the local-data
  /// merge (HU-04) runs. This is the prerequisite for RLS policies in
  /// Postgres and per-user PowerSync sync rules. See
  /// docs/requirements/05-auth-sync.md, decision #7 (2026-07-17).
  TextColumn get userId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Tables
// ---------------------------------------------------------------------------

/// Accounts: cash, bank, card, savings, investment...
class Accounts extends Table with _SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => textEnum<AccountType>()();

  /// ISO-4217 code, e.g. 'USD', 'COP', 'MXN'.
  TextColumn get currency => text().withLength(min: 3, max: 3)();

  /// Opening balance in cents. The current balance is derived by summing
  /// transactions.
  IntColumn get initialBalanceMinor => integer().clientDefault(() => 0)();

  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  BoolColumn get archived => boolean().clientDefault(() => false)();
  IntColumn get sortOrder => integer().clientDefault(() => 0)();

  // -- Bank identification and card data (all nullable so existing accounts
  //    are not broken; see docs/requirements/01-cuentas.md). --

  /// Bank name (e.g. 'Bancolombia', 'Nu'). Applies to every account type.
  TextColumn get institution => text().nullable().withLength(max: 100)();

  /// Last 4 digits, for identification only. The only syncable fragment.
  TextColumn get last4 => text().nullable().withLength(max: 4)();

  /// Annual interest rate in whole basis points (24.5% -> 2450).
  /// Never double: this is a scaled percentage, not an amount.
  IntColumn get interestRateBps => integer().nullable()();

  /// Card credit limit in cents.
  IntColumn get creditLimitMinor => integer().nullable()();

  /// Card statement day (1-31).
  IntColumn get statementDay => integer().nullable()();

  /// Card payment due day (1-31).
  IntColumn get paymentDueDay => integer().nullable()();

  /// Which figure to highlight on a card ('debt'/'available', HU-04).
  /// Stored as text via textEnum for parity with Postgres.
  TextColumn get cardBalancePrimary => textEnum<CardBalanceView>().nullable()();
}

/// Hierarchical categories (parentId points to another category = subcategory).
class Categories extends Table with _SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get kind => textEnum<CategoryKind>()();

  /// null = root category; otherwise it is a subcategory of parentId.
  TextColumn get parentId => text().nullable().references(Categories, #id)();

  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get sortOrder => integer().clientDefault(() => 0)();
}

/// Transactions (income, expenses and transfers between accounts).
class Transactions extends Table with _SyncColumns {
  @ReferenceName('transactionsAsAccount')
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  /// Amount in cents, always positive. The sign is determined by [type].
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();

  TextColumn get type => textEnum<EntryType>()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();

  /// Capture origin (to measure AI usage). Defaults to manual.
  TextColumn get source => textEnum<TxSource>().clientDefault(
        () => TxSource.manual.name,
      )();

  /// Only for type == transfer: destination account.
  @ReferenceName('transactionsAsTransferAccount')
  TextColumn get transferAccountId =>
      text().nullable().references(Accounts, #id)();

  /// Optional links.
  TextColumn get scheduledPaymentId =>
      text().nullable().references(ScheduledPayments, #id)();
  TextColumn get goalId => text().nullable().references(Goals, #id)();
  TextColumn get debtId => text().nullable().references(Debts, #id)();
}

/// User-named budgets with a configurable scope (accounts + categories via the
/// `BudgetAccounts` / `BudgetCategories` join tables). No `categoryId` column:
/// a budget is a named entity, not a per-category breakdown. An empty scope on
/// both join tables = the global budget (all expenses). See
/// docs/requirements/06-presupuestos.md.
class Budgets extends Table with _SyncColumns {
  /// Custom name the user gives the budget (e.g. 'Tarjeta de crédito'). HU-01.
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Optional icon to recognize the budget at a glance. No `color`: the
  /// icon-wrap stays neutral (`$muted`) by design. HU-01.
  TextColumn get icon => text().nullable()();

  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  TextColumn get period => textEnum<BudgetPeriod>()();
  DateTimeColumn get startDate => dateTime()();

  /// true = periodic (repeats each [period] from [startDate]), false = a single
  /// one-off window. Defaults to true (periodic is the common case). HU-03.
  BoolColumn get recurring => boolean().clientDefault(() => true)();

  /// End of the window. Mandatory when `recurring = false` or `period = custom`;
  /// on periodic budgets, null = "forever", a set value = stop-renewing date.
  /// Must be after [startDate]. HU-03.
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Closed-to-history timestamp (HU-10/11). Non-null = closed. Distinct from
  /// `deletedAt` (trash) and `tombstonedAt` (not used here).
  DateTimeColumn get archivedAt => dateTime().nullable()();

  /// Early-alert threshold as a whole percent (1-100). null = "don't alert me".
  /// HU-08.
  IntColumn get alertThresholdPct =>
      integer().nullable().clientDefault(() => 80)();

  /// Whether the leftover/overspend carries into the next period
  /// (zero-based style). Logic deferred (HU-07); the column exists from Phase 0.
  BoolColumn get rollover => boolean().clientDefault(() => false)();
}

/// Savings goals.
class Goals extends Table with _SyncColumns {
  TextColumn get name => text()();
  IntColumn get targetMinor => integer()();

  /// Saved so far (optional: can be derived from transactions with goalId).
  IntColumn get savedMinor => integer().clientDefault(() => 0)();
  TextColumn get currency => text().withLength(min: 3, max: 3)();

  /// Goal tied to a specific account (a pain point we fix vs. Wallet).
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
}

/// Debts and loans (I owe / owed to me).
class Debts extends Table with _SyncColumns {
  TextColumn get name => text()();
  TextColumn get direction => textEnum<DebtDirection>()();
  IntColumn get principalMinor => integer()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();

  /// Annual interest rate in whole basis points (24.5% -> 2450), optional.
  /// Never double, same rule as `Accounts.interestRateBps`: a scaled
  /// percentage, not an amount.
  IntColumn get interestRateBps => integer().nullable()();
  TextColumn get counterparty => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
}

/// Templates for scheduled payments: one-time or repeating planned
/// transactions (rent, subscriptions, a one-off future payment).
class ScheduledPayments extends Table with _SyncColumns {
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  TextColumn get type => textEnum<EntryType>()();
  TextColumn get note => text().nullable()();

  /// Only set when [type] is `transfer`: the destination account, same rule as
  /// a normal transfer transaction (see docs/requirements/03-transacciones.md).
  TextColumn get transferAccountId =>
      text().nullable().references(Accounts, #id)();

  TextColumn get frequency => textEnum<ScheduleFrequency>()();

  /// How many [frequency] units between repeats. E.g. interval=2 + weekly =
  /// every 2 weeks. Ignored when [frequency] is `once`.
  IntColumn get interval => integer().clientDefault(() => 1)();
  DateTimeColumn get nextDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();

  /// When true, reaching [nextDate] generates an editable draft the user must
  /// confirm before it applies to the balance, instead of applying it
  /// automatically (HU-03). Lets variable amounts (utilities) be adjusted.
  BoolColumn get requiresConfirmation => boolean().clientDefault(() => false)();
}

/// Free-form tags (a complement to categories).
class Tags extends Table with _SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get color => text().nullable()();
}

/// N:N relation between transactions and tags.
/// Carries its own id (from the mixin) because PowerSync needs a
/// single-column PK.
class TransactionTags extends Table with _SyncColumns {
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {transactionId, tagId},
      ];
}

/// N:N relation between scheduled payment templates and tags. Twin of
/// `TransactionTags`, same mechanics: its own id (from the mixin) because
/// PowerSync needs a single-column PK. Never populated when the template's
/// `type` is `transfer` (enforced in `data/`, mirrors the transaction rule).
class ScheduledPaymentTags extends Table with _SyncColumns {
  TextColumn get scheduledPaymentId =>
      text().references(ScheduledPayments, #id)();
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {scheduledPaymentId, tagId},
      ];
}

/// One row per due date of a scheduled payment template that has been
/// processed by the catch-up generator (HU-02) or acted on by the user
/// (confirm/skip/snooze, HU-03/HU-07). This is the idempotency ledger: the
/// unique key on (scheduledPaymentId, occurrenceDate) guarantees a due date
/// is generated at most once, even if the app closes mid-catch-up, and that
/// no due date is silently skipped.
///
/// [occurrenceDate] is the template's original anchor date for this
/// occurrence and is never mutated — the next occurrence's date is always
/// computed from the template's own `frequency`/`interval`/`nextDate`, never
/// from a snoozed date (see docs/requirements/09-pagos-programados.md,
/// HU-07 "nota de dominio"). Snoozing only records where the user wants
/// *this* occurrence to land, in [snoozedToDate].
class ScheduledPaymentOccurrences extends Table with _SyncColumns {
  TextColumn get scheduledPaymentId =>
      text().references(ScheduledPayments, #id)();

  /// The due date per the template's original cadence. Combined with
  /// [scheduledPaymentId] as the idempotency key; see class doc.
  DateTimeColumn get occurrenceDate => dateTime()();

  TextColumn get status => textEnum<ScheduledOccurrenceStatus>().clientDefault(
        () => ScheduledOccurrenceStatus.pending.name,
      )();

  /// Set only when [status] is `snoozed`: the later date the user chose.
  /// Null for every other status. The effective due date to display is this
  /// value when present, [occurrenceDate] otherwise.
  DateTimeColumn get snoozedToDate => dateTime().nullable()();

  /// The transaction generated when this occurrence was confirmed (auto or
  /// manual mode). Null while `pending`, `skipped` or `snoozed`.
  TextColumn get generatedTransactionId =>
      text().nullable().references(Transactions, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {scheduledPaymentId, occurrenceDate},
      ];
}

/// Budget scope by account (N:N). No rows for a budget = all accounts. Carries
/// its own id (from the mixin) because PowerSync needs a single-column PK, just
/// like `TransactionTags`. See docs/requirements/06-presupuestos.md.
class BudgetAccounts extends Table with _SyncColumns {
  TextColumn get budgetId => text().references(Budgets, #id)();
  TextColumn get accountId => text().references(Accounts, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {budgetId, accountId},
      ];
}

/// Budget scope by category (N:N). No rows for a budget = all expense
/// categories; a root category expands to its subcategories in the progress
/// calculation. Carries its own id (from the mixin) for the single-column PK.
class BudgetCategories extends Table with _SyncColumns {
  TextColumn get budgetId => text().references(Budgets, #id)();
  TextColumn get categoryId => text().references(Categories, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {budgetId, categoryId},
      ];
}

/// Account-level app settings that must sync across the user's devices
/// (zero-based mode, default currency...). Device-local prefs like the
/// light/dark theme do NOT belong here — they go in a separate local store.
///
/// DEVIATION FROM `_SyncColumns` (documented on purpose): this is a singleton.
/// The [id] is overridden to a well-known constant (`'app'`) instead of a
/// random per-row UUID. Two offline devices generating random UUIDs would
/// each create a row and PowerSync would duplicate them on merge; with a
/// constant id the row is a true singleton and the merge is last-write-wins
/// over `updatedAt`. The default singleton row is inserted by the
/// migration/onCreate (see `_seedAppSettings`).
class AppSettings extends Table with _SyncColumns {
  @override
  TextColumn get id => text().clientDefault(() => 'app')();

  /// Global zero-based ("Modo sobres") flag (HU-06).
  BoolColumn get zeroBasedEnabled => boolean().clientDefault(() => false)();

  /// One-shot latch: the onboarding default categories (HU-06) have been seeded
  /// once for this installation. Set to true after the first (and only) seed and
  /// never cleared, so wiping every category does NOT trigger a re-seed on the
  /// next launch. This is the install-lifetime guarantee — `hasAnyCategory` only
  /// reflects the current row count, which is not enough.
  BoolColumn get categoriesSeeded => boolean().clientDefault(() => false)();
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    Budgets,
    Goals,
    Debts,
    ScheduledPayments,
    Tags,
    TransactionTags,
    ScheduledPaymentTags,
    ScheduledPaymentOccurrences,
    BudgetAccounts,
    BudgetCategories,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 11;

  /// Inserts the single `AppSettings` row (id 'app'). Idempotent via
  /// `InsertMode.insertOrIgnore`.
  ///
  /// Goes through Drift's typed insert API, NOT a raw `customStatement`, on
  /// purpose: every `_SyncColumns` table is physically a PowerSync-managed
  /// view (decision #14, docs/requirements/05-auth-sync.md), which has no SQL
  /// column defaults of its own — a raw INSERT that only lists a couple of
  /// columns leaves every other column NULL. The typed API fills every
  /// `clientDefault` column (id, createdAt, updatedAt, zeroBasedEnabled,
  /// categoriesSeeded) explicitly, so the row comes out fully populated
  /// however it gets written.
  Future<void> _seedAppSettings() => into(appSettings).insert(
        const AppSettingsCompanion(),
        mode: InsertMode.insertOrIgnore,
      );

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedAppSettings();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v1 -> v2: bank identification and card data columns on Accounts
          // (all nullable). See docs/requirements/01-cuentas.md.
          if (from < 2) {
            await m.addColumn(accounts, accounts.institution);
            // `account_number_enc` no longer exists on the table class (see
            // v4 -> v5 below, which drops it), so a from-v1 upgrade adds it
            // by raw name instead of `accounts.accountNumberEnc`. It is
            // dropped again a few lines down, in the same upgrade run.
            await m.database.customStatement(
              'ALTER TABLE accounts ADD COLUMN account_number_enc TEXT NULL',
            );
            await m.addColumn(accounts, accounts.last4);
            await m.addColumn(accounts, accounts.interestRateBps);
            await m.addColumn(accounts, accounts.creditLimitMinor);
            await m.addColumn(accounts, accounts.statementDay);
            await m.addColumn(accounts, accounts.paymentDueDay);
            await m.addColumn(accounts, accounts.cardBalancePrimary);
          }

          // v2 -> v3: Debts.interestRate (REAL, annual %) becomes
          // interestRateBps (INTEGER, basis points), for parity with
          // Accounts.interestRateBps and with Postgres under PowerSync. The old
          // percentage is scaled by 100 and backfilled before the old column
          // goes, which is referenced by its SQL name because it no longer
          // exists in the table class.
          if (from < 3) {
            await m.addColumn(debts, debts.interestRateBps);
            await m.database.customStatement(
              'UPDATE debts SET interest_rate_bps = '
              'CAST(ROUND(interest_rate * 100) AS INTEGER) '
              'WHERE interest_rate IS NOT NULL',
            );
            await m.dropColumn(debts, 'interest_rate');
          }

          // v3 -> v4: split the two meanings of deletion. `deletedAt` used to
          // carry both the UX trash and the referential-integrity tombstone;
          // the latter now has its own `tombstonedAt` on every table (see
          // _SyncColumns).
          if (from < 4) {
            await m.addColumn(accounts, accounts.tombstonedAt);
            await m.addColumn(categories, categories.tombstonedAt);
            await m.addColumn(transactions, transactions.tombstonedAt);
            await m.addColumn(budgets, budgets.tombstonedAt);
            await m.addColumn(goals, goals.tombstonedAt);
            await m.addColumn(debts, debts.tombstonedAt);
            // The table was still named `recurrings` at this schema version
            // (renamed to `scheduled_payments` in v5 -> v6 below), so its
            // `tombstoned_at` column is added by raw SQL against the old name.
            await m.database.customStatement(
              'ALTER TABLE recurrings ADD COLUMN tombstoned_at INTEGER NULL',
            );
            await m.addColumn(tags, tags.tombstonedAt);
            await m.addColumn(transactionTags, transactionTags.tombstonedAt);

            // Backfill: every `deletedAt` on Accounts was written by
            // softDeleteAccount (HU-08), which is a tombstone, not trash —
            // Accounts has no trash flow. Those stamps move to the new column
            // so `deletedAt` keeps its single documented meaning. No other
            // table has a delete flow yet, so there is nothing else to move.
            await m.database.customStatement(
              'UPDATE accounts SET tombstoned_at = deleted_at, '
              'deleted_at = NULL WHERE deleted_at IS NOT NULL',
            );
          }

          // v4 -> v5:
          //  1. `updatedAt` moves from DateTimeColumn (whole seconds) to
          //     IntColumn epoch millis, on every table, so PowerSync/Supabase
          //     get enough resolution to resolve "last write wins" conflicts.
          //     `createdAt` is unaffected. Existing values (seconds) are
          //     backfilled by scaling by 1000.
          //  2. `Accounts.accountNumberEnc` is dropped: dead column, always
          //     NULL by design (the full account number only ever lives in
          //     secure storage, HU-03; see `AccountMapper.toInsertCompanion`).
          if (from < 5) {
            for (final table in [
              'accounts',
              'categories',
              'transactions',
              'budgets',
              'goals',
              'debts',
              'recurrings',
              'tags',
              'transaction_tags',
            ]) {
              await m.database.customStatement(
                'UPDATE $table SET updated_at = updated_at * 1000',
              );
            }

            await m.dropColumn(accounts, 'account_number_enc');
          }

          // v5 -> v6: the "recurring transactions" feature is renamed to
          // "scheduled payments" end to end (docs/requirements/
          // 09-pagos-programados.md). No data-shape change: the table and the
          // FK column are renamed in place, and the `recurring` capture source
          // becomes `scheduled`. The feature has no repository yet, so
          // `scheduled_payments` is empty; the source UPDATE is a no-op today
          // (nothing has generated a scheduled transaction) but keeps any
          // stray value consistent.
          if (from < 6) {
            await m.database.customStatement(
              'ALTER TABLE recurrings RENAME TO scheduled_payments',
            );
            await m.database.customStatement(
              'ALTER TABLE transactions '
              'RENAME COLUMN recurring_id TO scheduled_payment_id',
            );
            await m.database.customStatement(
              "UPDATE transactions SET source = 'scheduled' "
              "WHERE source = 'recurring'",
            );
          }

          // v6 -> v7: Budgets feature. See docs/requirements/06-presupuestos.md.
          //  1. Budgets gains name/icon/recurring/endDate/archivedAt/
          //     alertThresholdPct and drops `categoryId` (scope now lives in the
          //     BudgetAccounts / BudgetCategories join tables).
          //  2. New tables: BudgetAccounts, BudgetCategories, AppSettings.
          //  3. AppSettings gets its singleton row (id 'app') seeded.
          // `biweekly` is additive to the BudgetPeriod enum (stored as text), so
          // no data migration is needed for existing `period` values.
          if (from < 7) {
            // `name` is NOT NULL without a Drift default, so `addColumn` would
            // reject it. Add it by raw SQL with a temporary DEFAULT '' so any
            // pre-existing rows stay valid (this is a local dev DB with no
            // production data); new inserts always supply a real name.
            await m.database.customStatement(
              'ALTER TABLE budgets ADD COLUMN name TEXT NOT NULL DEFAULT \'\'',
            );
            await m.addColumn(budgets, budgets.icon);
            await m.addColumn(budgets, budgets.recurring);
            await m.addColumn(budgets, budgets.endDate);
            await m.addColumn(budgets, budgets.archivedAt);
            await m.addColumn(budgets, budgets.alertThresholdPct);
            await m.dropColumn(budgets, 'category_id');

            await m.createTable(budgetAccounts);
            await m.createTable(budgetCategories);
            await m.createTable(appSettings);
            await _seedAppSettings();
          }

          // v7 -> v8: scheduled payments gain a one-time frequency and two
          // fields. `once` is additive to the ScheduleFrequency enum (stored as
          // text), so no data migration is needed. See
          // docs/requirements/09-pagos-programados.md.
          //  - `transferAccountId`: destination for a transfer-type scheduled
          //    payment (nullable).
          //  - `requiresConfirmation`: opt-in confirmation flow (HU-03).
          if (from < 8) {
            await m.addColumn(
              scheduledPayments,
              scheduledPayments.transferAccountId,
            );
            await m.addColumn(
              scheduledPayments,
              scheduledPayments.requiresConfirmation,
            );
          }

          // v8 -> v9: AppSettings gains `categoriesSeeded`, a one-shot latch so
          // the onboarding default categories are seeded once per installation
          // and never re-seeded, even if the user deletes every category (the
          // old `hasAnyCategory` check re-seeded in that case). Additive nullable
          // -> defaults to false via the column default; the singleton row keeps
          // its value. See seed_default_categories.dart.
          if (from < 9) {
            await m.addColumn(appSettings, appSettings.categoriesSeeded);
          }

          // v9 -> v10: every `_SyncColumns` table gains `userId`, a nullable
          // logical reference to `auth.users.id` in Supabase (no local FK).
          // Rows created offline/without a session keep it NULL until the
          // user signs in and the local-data merge (HU-04) fills it in; this
          // is what unlocks RLS in Postgres and per-user PowerSync sync
          // rules. Additive nullable column -> no backfill needed. See
          // docs/requirements/05-auth-sync.md, decision #7 (2026-07-17).
          if (from < 10) {
            await m.addColumn(accounts, accounts.userId);
            await m.addColumn(categories, categories.userId);
            await m.addColumn(transactions, transactions.userId);
            await m.addColumn(budgets, budgets.userId);
            await m.addColumn(goals, goals.userId);
            await m.addColumn(debts, debts.userId);
            await m.addColumn(scheduledPayments, scheduledPayments.userId);
            await m.addColumn(tags, tags.userId);
            await m.addColumn(transactionTags, transactionTags.userId);
            await m.addColumn(budgetAccounts, budgetAccounts.userId);
            await m.addColumn(budgetCategories, budgetCategories.userId);
            await m.addColumn(appSettings, appSettings.userId);
          }

          // v10 -> v11: Scheduled Payments feature (docs/requirements/
          // 09-pagos-programados.md). Two new tables, both additive (no
          // existing data to migrate):
          //  - `ScheduledPaymentTags`: N:N bridge between templates and
          //    `Tags`, twin of `TransactionTags` (HU-01).
          //  - `ScheduledPaymentOccurrences`: idempotency ledger for the
          //    catch-up generator plus per-occurrence state (pending
          //    confirmation, skipped, snoozed) that never mutates the
          //    template's own cadence (HU-02/HU-03/HU-07).
          if (from < 11) {
            await m.createTable(scheduledPaymentTags);
            await m.createTable(scheduledPaymentOccurrences);
          }
        },
      );

  // Drift opens on top of the PowerSync-managed connection instead of its own
  // NativeDatabase (see `core/database/database_connection.dart` and decision
  // #6, docs/requirements/05-auth-sync.md). The mirrored PowerSync `Schema`
  // lives in `core/database/powersync_schema.dart` and must be kept in sync
  // by hand with any change to a `_SyncColumns` table here.
}
