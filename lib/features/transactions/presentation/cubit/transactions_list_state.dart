import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/transaction_with_details.dart';

/// The three states the transaction list renders (HU-06). `ready` splits into
/// "with data" and "empty" through [TransactionsListState.isEmpty] — a
/// filtered/searched period with no matches is not an error (HU-06b).
enum TransactionsListStatus { loading, ready, failure }

class TransactionsListState extends Equatable {
  TransactionsListState({
    this.status = TransactionsListStatus.loading,
    this.items = const <TransactionWithDetails>[],
    this.accounts = const <AccountWithBalance>[],
    TransactionFilter? filter,
    this.failure,
    this.pendingUndoId,
  }) : filter = filter ?? TransactionFilter();

  final TransactionsListStatus status;

  /// Already filtered, searched and ordered by the repository (HU-06).
  final List<TransactionWithDetails> items;

  /// Active accounts, only kept to resolve the account chip's name/icon when
  /// exactly one is the active filter (`B3GGa`/`xAk6Y`) — the list itself
  /// never needs it.
  final List<AccountWithBalance> accounts;

  /// Persists across re-emissions/scroll: this is the single source of truth
  /// for every active filter and the search text.
  final TransactionFilter filter;

  final Failure? failure;

  /// The id of the transaction a "Deshacer" snackbar is currently offered
  /// for (HU-05). `null` once dismissed or undone.
  final String? pendingUndoId;

  bool get isLoading => status == TransactionsListStatus.loading;

  bool get isEmpty => status == TransactionsListStatus.ready && items.isEmpty;

  /// The accounts the balance carousel (Mejora #2) shows: the ones the account
  /// filter narrows to, or every active account when there is no account
  /// filter ("Todas"). Preserves [accounts]' order (the account list order).
  List<AccountWithBalance> get displayedAccounts {
    final ids = filter.accountIds;
    if (ids.isEmpty) {
      return accounts;
    }
    return accounts
        .where((entry) => ids.contains(entry.account.id))
        .toList(growable: false);
  }

  /// Sum of the shown accounts' balances, for the collapsed bar's "Saldo
  /// total" (Mejora #2). A plain sum of `balanceMinor` in cents: the app is
  /// single-currency in practice today, so — unlike Cuentas' Total Card — this
  /// does not split per currency (see `displayedCurrency`).
  int get displayedBalanceTotalMinor => displayedAccounts.fold(
        0,
        (total, entry) => total + entry.balance.balanceMinor,
      );

  /// Currency the collapsed total renders in: the first shown account's, or
  /// `'COP'` when none is shown. Mixed-currency reconciliation is out of scope
  /// for Mejora #2 (see `displayedBalanceTotalMinor`).
  String get displayedCurrency =>
      displayedAccounts.isEmpty ? 'COP' : displayedAccounts.first.account.currency;

  TransactionsListState copyWith({
    TransactionsListStatus? status,
    List<TransactionWithDetails>? items,
    List<AccountWithBalance>? accounts,
    TransactionFilter? filter,
    Failure? failure,
    String? pendingUndoId,
    bool clearPendingUndo = false,
  }) =>
      TransactionsListState(
        status: status ?? this.status,
        items: items ?? this.items,
        accounts: accounts ?? this.accounts,
        filter: filter ?? this.filter,
        // A new state carrying data is a state without an error: the caller
        // clears the failure by simply not passing one.
        failure: failure,
        pendingUndoId:
            clearPendingUndo ? null : (pendingUndoId ?? this.pendingUndoId),
      );

  @override
  List<Object?> get props =>
      [status, items, accounts, filter, failure, pendingUndoId];
}
