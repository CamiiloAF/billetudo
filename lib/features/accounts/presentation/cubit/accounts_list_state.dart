import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/account_with_balance.dart';
import '../../domain/entities/accounts_overview.dart';

/// The four states the accounts list renders (see the design's frames
/// `l055o`/`nwFMA`/`sh7r2`/`L6Za0`). `ready` splits into "with data" and
/// "empty" through [AccountsListState.isEmpty] — the difference is the content,
/// not the load.
enum AccountsListStatus { loading, ready, failure }

class AccountsListState extends Equatable {
  const AccountsListState({
    this.status = AccountsListStatus.loading,
    this.accounts = const [],
    this.overview = const AccountsOverview([]),
    this.failure,
  });

  final AccountsListStatus status;

  /// Active accounts with their balance, already ordered by `sortOrder`.
  final List<AccountWithBalance> accounts;

  /// Total Card aggregate: one subtotal per currency, never a cross-currency
  /// sum.
  final AccountsOverview overview;

  final Failure? failure;

  bool get isLoading => status == AccountsListStatus.loading;

  /// Empty is only meaningful once loaded: no accounts before that just means
  /// the first emission has not arrived.
  bool get isEmpty => status == AccountsListStatus.ready && accounts.isEmpty;

  AccountsListState copyWith({
    AccountsListStatus? status,
    List<AccountWithBalance>? accounts,
    AccountsOverview? overview,
    Failure? failure,
  }) =>
      AccountsListState(
        status: status ?? this.status,
        accounts: accounts ?? this.accounts,
        overview: overview ?? this.overview,
        // A new state carrying data is a state without an error: the caller
        // clears the failure by simply not passing one.
        failure: failure,
      );

  @override
  List<Object?> get props => [status, accounts, overview, failure];
}
