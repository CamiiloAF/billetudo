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
enum TxSource { manual, voice, ocr, notification, imported, recurring }

enum BudgetPeriod { weekly, monthly, yearly, custom }

enum DebtDirection { iOwe, owedToMe }

enum RecurFrequency { daily, weekly, monthly, yearly }

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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

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
  IntColumn get initialBalanceMinor =>
      integer().withDefault(const Constant(0))();

  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  // -- Bank identification and card data (all nullable so existing accounts
  //    are not broken; see docs/requirements/01-cuentas.md). --

  /// Bank name (e.g. 'Bancolombia', 'Nu'). Applies to every account type.
  TextColumn get institution => text().nullable().withLength(max: 100)();

  /// Full account number, ENCRYPTED at the app level (Keychain/Keystore).
  /// EXCLUDE from PowerSync sync — local only, it never reaches Supabase.
  /// Does not apply to credit cards (app-level business rule, HU-03).
  TextColumn get accountNumberEnc => text().nullable()();

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
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
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
  TextColumn get source =>
      textEnum<TxSource>().withDefault(Constant(TxSource.manual.name))();

  /// Only for type == transfer: destination account.
  @ReferenceName('transactionsAsTransferAccount')
  TextColumn get transferAccountId =>
      text().nullable().references(Accounts, #id)();

  /// Optional links.
  TextColumn get recurringId => text().nullable().references(Recurrings, #id)();
  TextColumn get goalId => text().nullable().references(Goals, #id)();
  TextColumn get debtId => text().nullable().references(Debts, #id)();
}

/// Budgets. categoryId null = global budget (all expenses).
class Budgets extends Table with _SyncColumns {
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  TextColumn get period => textEnum<BudgetPeriod>()();
  DateTimeColumn get startDate => dateTime()();

  /// Whether the leftover/overspend carries into the next period
  /// (zero-based style).
  BoolColumn get rollover => boolean().withDefault(const Constant(false))();
}

/// Savings goals.
class Goals extends Table with _SyncColumns {
  TextColumn get name => text()();
  IntColumn get targetMinor => integer()();

  /// Saved so far (optional: can be derived from transactions with goalId).
  IntColumn get savedMinor => integer().withDefault(const Constant(0))();
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

/// Templates for recurring transactions / planned payments.
class Recurrings extends Table with _SyncColumns {
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  TextColumn get type => textEnum<EntryType>()();
  TextColumn get note => text().nullable()();

  TextColumn get frequency => textEnum<RecurFrequency>()();

  /// How many [frequency] units between repeats. E.g. interval=2 + weekly =
  /// every 2 weeks.
  IntColumn get interval => integer().withDefault(const Constant(1))();
  DateTimeColumn get nextDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
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
    Recurrings,
    Tags,
    TransactionTags,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v1 -> v2: bank identification and card data columns on Accounts
          // (all nullable). See docs/requirements/01-cuentas.md.
          if (from < 2) {
            await m.addColumn(accounts, accounts.institution);
            await m.addColumn(accounts, accounts.accountNumberEnc);
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
            await m.addColumn(recurrings, recurrings.tombstonedAt);
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
        },
      );

  // Once PowerSync is integrated, instead of opening our own NativeDatabase we
  // open Drift on top of the PowerSync database, and define a PowerSync Schema
  // mirroring these same tables/columns. PowerSync then handles bidirectional
  // sync with Supabase Postgres.
}
