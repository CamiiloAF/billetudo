import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/preferences/account_filter_preference_datasource.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/transaction_with_details.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/restore_transaction.dart';
import '../../domain/usecases/watch_transactions.dart';
import 'transactions_list_state.dart';

/// Drives the transaction list: search, every combinable filter of HU-06,
/// and the delete/"Deshacer" flow of HU-05.
///
/// Talks only to use cases. Every filter change re-subscribes to
/// `watchTransactions`, since the filter itself is part of the query.
///
/// Registered as a `@lazySingleton` (behaviour-equivalent to the previous
/// factory, since the Movimientos branch already holds its single instance
/// alive for the whole app session inside the shell's `IndexedStack`): this
/// lets Inicio reach the live filter through DI and set it before switching to
/// the tab (bugfix item 8, [filterByAccount]).
@lazySingleton
class TransactionsListCubit extends Cubit<TransactionsListState> {
  TransactionsListCubit(
    this._watchTransactions,
    this._deleteTransaction,
    this._restoreTransaction,
    this._watchAccounts,
    this._accountFilterPreferences,
  ) : super(TransactionsListState());

  final WatchTransactions _watchTransactions;
  final DeleteTransaction _deleteTransaction;
  final RestoreTransaction _restoreTransaction;
  final WatchAccounts _watchAccounts;
  final AccountFilterPreferenceDatasource _accountFilterPreferences;

  StreamSubscription<Result<List<TransactionWithDetails>>>? _subscription;

  /// Kept only to resolve the account chip's name/icon (`B3GGa`/`xAk6Y`)
  /// when exactly one account is the active filter.
  StreamSubscription<Result<List<AccountWithBalance>>>? _accountsSubscription;

  /// Whether the persisted account filter has already been checked against
  /// the current active accounts (see [_pruneStaleAccountFilter]) — only
  /// needs doing once per `start()`, on the first accounts emission.
  bool _prunedStaleAccountFilter = false;

  /// Subscribes with the current (or default) filter. Safe to call again to
  /// retry after an error.
  ///
  /// The account filter (HU-06a) is restored from device storage here, so it
  /// survives closing and reopening the app — every other filter dimension
  /// resets with the cubit, by design.
  Future<void> start() async {
    await _subscription?.cancel();
    await _accountsSubscription?.cancel();
    _prunedStaleAccountFilter = false;
    final persistedAccountIds =
        await _accountFilterPreferences.readAccountIds();
    emit(
      TransactionsListState(
        filter: state.filter.copyWith(accountIds: persistedAccountIds),
      ),
    );
    _subscribe();
    _accountsSubscription = _watchAccounts().listen((result) {
      if (isClosed) {
        return;
      }
      result.fold(
        // The account chip simply falls back to the count/id it already has
        // when the accounts stream fails — not worth surfacing as a list-wide
        // error.
        (failure) {},
        (accounts) {
          emit(state.copyWith(accounts: accounts));
          if (!_prunedStaleAccountFilter) {
            _prunedStaleAccountFilter = true;
            _pruneStaleAccountFilter(accounts);
          }
        },
      );
    });
  }

  /// Drops any account id in the (possibly persisted) filter that no longer
  /// belongs to an active account — the account was archived or deleted
  /// since the filter was saved. Falls back to "todas las cuentas" for those
  /// ids instead of silently keeping a ghost account the user can no longer
  /// see or deselect in the filter sheet (`AccountFilterCubit` only lists
  /// active accounts too).
  void _pruneStaleAccountFilter(List<AccountWithBalance> accounts) {
    final current = state.filter.accountIds;
    if (current.isEmpty) {
      return;
    }
    final activeIds = accounts.map((entry) => entry.account.id).toSet();
    final validated = current.intersection(activeIds);
    if (validated.length != current.length) {
      unawaited(updateFilter(state.filter.copyWith(accountIds: validated)));
    }
  }

  /// Bugfix item 8: pins the account filter to exactly [accountId] (dropping
  /// every other selected account), used when the user taps that account's
  /// mini-card in Inicio's "Mis cuentas" strip. Routes through [updateFilter]
  /// so the HU-06a persisted preference and the live stream stay a single
  /// source of truth — no duplicated filter state.
  Future<void> filterByAccount(String accountId) =>
      updateFilter(state.filter.copyWith(accountIds: {accountId}));

  /// HU-06: free-text search over note and category name.
  Future<void> searchChanged(String text) =>
      updateFilter(state.filter.copyWith(searchText: text));

  /// Replaces the active filter (any combination of HU-06/HU-06a/HU-06b) and
  /// re-subscribes. A no-op when nothing actually changed, so a re-emission of
  /// the same filter from a sheet does not restart the stream.
  Future<void> updateFilter(TransactionFilter filter) async {
    final previous = state.filter;
    if (filter == previous) {
      return;
    }
    await _subscription?.cancel();
    emit(state.copyWith(filter: filter));
    _subscribe();
    final accountIdsChanged =
        filter.accountIds.length != previous.accountIds.length ||
            !filter.accountIds.containsAll(previous.accountIds);
    if (accountIdsChanged) {
      unawaited(_accountFilterPreferences.writeAccountIds(filter.accountIds));
    }
  }

  void _subscribe() {
    _subscription = _watchTransactions(state.filter).listen(_onTransactions);
  }

  void _onTransactions(Result<List<TransactionWithDetails>> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: TransactionsListStatus.failure,
          failure: failure,
        ),
        (items) =>
            state.copyWith(status: TransactionsListStatus.ready, items: items),
      ),
    );
  }

  /// HU-05: soft-deletes into the trash and offers "Deshacer" via
  /// [TransactionsListState.pendingUndoId]. The list stream itself removes the
  /// row once `deletedAt` lands, so this only tracks the undo affordance.
  Future<void> deleteTransaction(String id) async {
    final result = await _deleteTransaction(id);
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
          state.copyWith(
            status: TransactionsListStatus.failure,
            failure: failure,
          ),
        );
      case Right():
        emit(state.copyWith(pendingUndoId: id));
    }
  }

  /// HU-05: offers the same "Deshacer" snackbar for a delete that already
  /// happened elsewhere (`TransactionDetailCubit.confirmDelete`) — unlike
  /// [deleteTransaction], this does not call the use case again, since the
  /// row is already soft-deleted; it only surfaces the undo affordance.
  void notifyExternalDelete(String id) =>
      emit(state.copyWith(pendingUndoId: id));

  /// HU-05: "Deshacer" from the snackbar.
  Future<void> undoDelete() async {
    final id = state.pendingUndoId;
    if (id == null) {
      return;
    }
    emit(state.copyWith(clearPendingUndo: true));
    await _restoreTransaction(id);
  }

  /// The snackbar timed out or the user dismissed it without undoing.
  void dismissUndo() => emit(state.copyWith(clearPendingUndo: true));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _accountsSubscription?.cancel();
    return super.close();
  }
}
