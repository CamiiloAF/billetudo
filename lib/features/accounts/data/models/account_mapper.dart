import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/account.dart';
import '../../domain/entities/account_balance.dart';
import '../../domain/entities/account_draft.dart';

/// Translates between Drift's generated rows and the domain entities. The only
/// place where `*Data`/`*Companion` types meet the domain, so no generated type
/// ever escapes `data/`.
///
/// Enums are mapped explicitly (not by index) because they are stored as text
/// for parity with Postgres: the domain owns its own enum, and the two are
/// matched by meaning, not by declaration order.
abstract final class AccountMapper {
  static Account toEntity(db.Account row) => Account(
        id: row.id,
        name: row.name,
        type: _typeToDomain(row.type),
        currency: row.currency,
        initialBalanceMinor: row.initialBalanceMinor,
        archived: row.archived,
        sortOrder: row.sortOrder,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        institution: row.institution,
        last4: row.last4,
        interestRateBps: row.interestRateBps,
        creditLimitMinor: row.creditLimitMinor,
        statementDay: row.statementDay,
        paymentDueDay: row.paymentDueDay,
        cardBalancePrimary: _cardViewToDomain(row.cardBalancePrimary),
      );

  /// A transaction row as seen from [accountId]: the same transfer is an
  /// outgoing movement for its source account and an incoming one for its
  /// destination.
  static AccountMovement toMovement(db.Transaction row, String accountId) =>
      AccountMovement(
        amountMinor: row.amountMinor,
        kind: _movementKind(row, accountId),
        deletedAt: row.deletedAt,
      );

  static MovementKind _movementKind(db.Transaction row, String accountId) =>
      switch (row.type) {
        db.EntryType.income => MovementKind.income,
        db.EntryType.expense => MovementKind.expense,
        db.EntryType.transfer => row.accountId == accountId
            ? MovementKind.transferOut
            : MovementKind.transferIn,
      };

  /// Insert companion. The full account number is **never** persisted here:
  /// it lives only in secure storage (HU-03). `id` is left to Drift's
  /// `clientDefault` (UUID).
  static db.AccountsCompanion toInsertCompanion(
    AccountDraft draft, {
    required int sortOrder,
    required DateTime now,
  }) =>
      db.AccountsCompanion.insert(
        name: draft.name,
        type: _typeToDb(draft.type),
        currency: draft.currency,
        initialBalanceMinor: Value(draft.initialBalanceMinor),
        archived: const Value(false),
        sortOrder: Value(sortOrder),
        createdAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
        institution: Value(draft.institution),
        last4: Value(draft.last4),
        interestRateBps: Value(draft.interestRateBps),
        creditLimitMinor: Value(draft.creditLimitMinor),
        statementDay: Value(draft.statementDay),
        paymentDueDay: Value(draft.paymentDueDay),
        cardBalancePrimary: Value(_cardViewToDb(draft.cardBalancePrimary)),
      );

  /// Update companion. Every nullable field is written explicitly (`Value(null)`
  /// rather than `absent()`) so leaving a type actually clears its old data
  /// (HU-06) instead of silently keeping it.
  static db.AccountsCompanion toUpdateCompanion(
    AccountDraft draft, {
    required DateTime now,
  }) =>
      db.AccountsCompanion(
        name: Value(draft.name),
        type: Value(_typeToDb(draft.type)),
        currency: Value(draft.currency),
        initialBalanceMinor: Value(draft.initialBalanceMinor),
        updatedAt: Value(now.millisecondsSinceEpoch),
        institution: Value(draft.institution),
        last4: Value(draft.last4),
        interestRateBps: Value(draft.interestRateBps),
        creditLimitMinor: Value(draft.creditLimitMinor),
        statementDay: Value(draft.statementDay),
        paymentDueDay: Value(draft.paymentDueDay),
        cardBalancePrimary: Value(_cardViewToDb(draft.cardBalancePrimary)),
      );

  static db.AccountType _typeToDb(AccountType type) => switch (type) {
        AccountType.cash => db.AccountType.cash,
        AccountType.bank => db.AccountType.bank,
        AccountType.card => db.AccountType.card,
        AccountType.savings => db.AccountType.savings,
        AccountType.investment => db.AccountType.investment,
        AccountType.other => db.AccountType.other,
      };

  static AccountType _typeToDomain(db.AccountType type) => switch (type) {
        db.AccountType.cash => AccountType.cash,
        db.AccountType.bank => AccountType.bank,
        db.AccountType.card => AccountType.card,
        db.AccountType.savings => AccountType.savings,
        db.AccountType.investment => AccountType.investment,
        db.AccountType.other => AccountType.other,
      };

  /// HU-07. Like every write, it stamps `updatedAt`.
  static db.AccountsCompanion archivedCompanion({
    required bool archived,
    required DateTime now,
  }) =>
      db.AccountsCompanion(
        archived: Value(archived),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-08: logical delete. Stamps `tombstonedAt`, not `deletedAt`: the row
  /// stays so `Transactions.accountId` keeps pointing at something real, and
  /// that is exactly what the tombstone column means. `deletedAt` is reserved
  /// for the reversible UX trash, which Accounts does not offer.
  static db.AccountsCompanion tombstonedCompanion({required DateTime now}) =>
      db.AccountsCompanion(
        tombstonedAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// HU-04: presentation preference of a card.
  static db.AccountsCompanion cardBalancePrimaryCompanion({
    required CardBalanceView view,
    required DateTime now,
  }) =>
      db.AccountsCompanion(
        cardBalancePrimary: Value(cardViewToDb(view)),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );

  /// Also used by the repository's `setCardBalancePrimary`.
  static db.CardBalanceView cardViewToDb(CardBalanceView view) =>
      switch (view) {
        CardBalanceView.debt => db.CardBalanceView.debt,
        CardBalanceView.available => db.CardBalanceView.available,
      };

  static db.CardBalanceView? _cardViewToDb(CardBalanceView? view) =>
      view == null ? null : cardViewToDb(view);

  static CardBalanceView? _cardViewToDomain(db.CardBalanceView? view) =>
      switch (view) {
        null => null,
        db.CardBalanceView.debt => CardBalanceView.debt,
        db.CardBalanceView.available => CardBalanceView.available,
      };
}
