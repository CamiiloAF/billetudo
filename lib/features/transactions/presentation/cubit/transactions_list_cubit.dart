import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
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
@injectable
class TransactionsListCubit extends Cubit<TransactionsListState> {
  TransactionsListCubit(
    this._watchTransactions,
    this._deleteTransaction,
    this._restoreTransaction,
  ) : super(TransactionsListState());

  final WatchTransactions _watchTransactions;
  final DeleteTransaction _deleteTransaction;
  final RestoreTransaction _restoreTransaction;

  StreamSubscription<Result<List<TransactionWithDetails>>>? _subscription;

  /// Subscribes with the current (or default) filter. Safe to call again to
  /// retry after an error.
  Future<void> start() async {
    await _subscription?.cancel();
    emit(TransactionsListState(filter: state.filter));
    _subscribe();
  }

  /// HU-06: free-text search over note and category name.
  Future<void> searchChanged(String text) =>
      updateFilter(state.filter.copyWith(searchText: text));

  /// Replaces the active filter (any combination of HU-06/HU-06a/HU-06b) and
  /// re-subscribes. A no-op when nothing actually changed, so a re-emission of
  /// the same filter from a sheet does not restart the stream.
  Future<void> updateFilter(TransactionFilter filter) async {
    if (filter == state.filter) {
      return;
    }
    await _subscription?.cancel();
    emit(state.copyWith(filter: filter));
    _subscribe();
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
    return super.close();
  }
}
