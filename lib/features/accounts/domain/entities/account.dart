import 'package:equatable/equatable.dart';

/// Kind of account. Mirrors the `AccountType` stored as text in Drift, but is
/// declared here so the domain never depends on the database layer.
enum AccountType {
  cash,
  bank,
  card,
  savings,
  investment,
  other;

  bool get isCard => this == AccountType.card;

  /// Whether the account may store the **full** account number (HU-03).
  ///
  /// Cash has no number at all, and a credit card must never store its PAN:
  /// keeping it out of the app is what keeps us outside PCI-DSS scope. Only
  /// `last4` is captured for cards.
  bool get allowsFullAccountNumber =>
      this != AccountType.cash && this != AccountType.card;
}

/// Which figure a credit card highlights (HU-04). Presentation preference only:
/// it never changes how the balance is computed.
enum CardBalanceView { debt, available }

/// A user account: cash, bank, card, savings, investment or other.
///
/// Pure domain entity: no Drift types, no `double`. Money is always an integer
/// of minor units (cents) and the interest rate an integer of basis points.
///
/// The **full account number is deliberately absent**: it never leaves the
/// device's secure storage, so it is not part of the syncable entity (HU-03).
/// Only [last4] is kept here.
class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.initialBalanceMinor,
    required this.archived,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.institution,
    this.last4,
    this.interestRateBps,
    this.creditLimitMinor,
    this.statementDay,
    this.paymentDueDay,
    this.cardBalancePrimary,
  });

  /// UUID as text.
  final String id;
  final String name;
  final AccountType type;

  /// ISO-4217 code, e.g. 'COP', 'USD'.
  final String currency;

  /// Opening balance in cents. The current balance derives from this plus the
  /// account's transactions (see `AccountBalance`).
  final int initialBalanceMinor;

  final bool archived;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Bank/entity name, e.g. 'Bancolombia'. Applies to every type.
  final String? institution;

  /// Last 4 digits of the account number. The only syncable fragment (HU-03).
  final String? last4;

  /// Annual interest rate in whole basis points (24.5% -> 2450). Informative in
  /// phase 0.
  final int? interestRateBps;

  /// Card credit limit in cents. Required when [type] is `card`.
  final int? creditLimitMinor;

  /// Card statement day (1-31).
  final int? statementDay;

  /// Card payment due day (1-31).
  final int? paymentDueDay;

  /// Which figure to highlight on a card (HU-04).
  final CardBalanceView? cardBalancePrimary;

  bool get isCard => type.isCard;

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        currency,
        initialBalanceMinor,
        archived,
        sortOrder,
        createdAt,
        updatedAt,
        institution,
        last4,
        interestRateBps,
        creditLimitMinor,
        statementDay,
        paymentDueDay,
        cardBalancePrimary,
      ];
}
