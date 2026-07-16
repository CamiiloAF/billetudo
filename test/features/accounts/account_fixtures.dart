import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/account_draft.dart';
import 'package:billetudo/features/accounts/domain/entities/account_number_edit.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';

/// Shared builders so each test only states what it is actually about.
final DateTime testInstant = DateTime(2026, 7, 15, 10, 30);

Account buildAccount({
  String id = 'acc-1',
  String name = 'Cuenta de prueba',
  AccountType type = AccountType.bank,
  String currency = 'COP',
  int initialBalanceMinor = 0,
  bool archived = false,
  int sortOrder = 0,
  String? institution,
  String? last4,
  int? interestRateBps,
  int? creditLimitMinor,
  int? statementDay,
  int? paymentDueDay,
  CardBalanceView? cardBalancePrimary,
  DateTime? updatedAt,
}) =>
    Account(
      id: id,
      name: name,
      type: type,
      currency: currency,
      initialBalanceMinor: initialBalanceMinor,
      archived: archived,
      sortOrder: sortOrder,
      createdAt: testInstant,
      updatedAt: updatedAt ?? testInstant,
      institution: institution,
      last4: last4,
      interestRateBps: interestRateBps,
      creditLimitMinor: creditLimitMinor,
      statementDay: statementDay,
      paymentDueDay: paymentDueDay,
      cardBalancePrimary: cardBalancePrimary,
    );

/// A credit card with the fields HU-02 makes mandatory already filled in.
Account buildCard({
  String id = 'card-1',
  String name = 'Tarjeta',
  String currency = 'COP',
  int initialBalanceMinor = 0,
  required int creditLimitMinor,
  int statementDay = 15,
  int paymentDueDay = 5,
  CardBalanceView cardBalancePrimary = CardBalanceView.debt,
}) =>
    buildAccount(
      id: id,
      name: name,
      type: AccountType.card,
      currency: currency,
      initialBalanceMinor: initialBalanceMinor,
      creditLimitMinor: creditLimitMinor,
      statementDay: statementDay,
      paymentDueDay: paymentDueDay,
      cardBalancePrimary: cardBalancePrimary,
    );

AccountWithBalance buildAccountWithBalance({
  required Account account,
  required int balanceMinor,
}) =>
    AccountWithBalance(
      account: account,
      balance: AccountBalance.fromBalance(
        account: account,
        balanceMinor: balanceMinor,
      ),
    );

/// A valid draft: tests override only the field under test.
AccountDraft buildDraft({
  String? id,
  String name = 'Cuenta nueva',
  AccountType type = AccountType.bank,
  String currency = 'COP',
  int initialBalanceMinor = 0,
  String? institution,
  AccountNumberEdit numberEdit = const KeepAccountNumber(),
  String? last4,
  int? interestRateBps,
  int? creditLimitMinor,
  int? statementDay,
  int? paymentDueDay,
  CardBalanceView? cardBalancePrimary,
}) =>
    AccountDraft(
      id: id,
      name: name,
      type: type,
      currency: currency,
      initialBalanceMinor: initialBalanceMinor,
      institution: institution,
      numberEdit: numberEdit,
      last4: last4,
      interestRateBps: interestRateBps,
      creditLimitMinor: creditLimitMinor,
      statementDay: statementDay,
      paymentDueDay: paymentDueDay,
      cardBalancePrimary: cardBalancePrimary,
    );

/// A card draft that passes HU-02 validation unless a test breaks it on
/// purpose.
AccountDraft buildCardDraft({
  String? id,
  String name = 'Tarjeta nueva',
  String currency = 'COP',
  int? creditLimitMinor = 500000,
  int? statementDay = 15,
  int? paymentDueDay = 5,
  AccountNumberEdit numberEdit = const KeepAccountNumber(),
  String? last4,
}) =>
    buildDraft(
      id: id,
      name: name,
      type: AccountType.card,
      currency: currency,
      creditLimitMinor: creditLimitMinor,
      statementDay: statementDay,
      paymentDueDay: paymentDueDay,
      numberEdit: numberEdit,
      last4: last4,
    );
