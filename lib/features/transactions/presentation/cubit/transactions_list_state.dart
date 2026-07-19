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
