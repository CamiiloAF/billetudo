import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/transaction_with_details.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/watch_transaction_detail.dart';
import 'transaction_detail_state.dart';

/// Drives HU-08's detail screen: the enriched, reactive detail plus the
/// delete confirmation flow of HU-05 launched from here.
@injectable
class TransactionDetailCubit extends Cubit<TransactionDetailState> {
  TransactionDetailCubit(
    this._watchTransactionDetail,
    this._deleteTransaction,
  ) : super(const TransactionDetailState());

  final WatchTransactionDetail _watchTransactionDetail;
  final DeleteTransaction _deleteTransaction;

  StreamSubscription<Result<TransactionWithDetails>>? _subscription;

  Future<void> start(String id) async {
    await _subscription?.cancel();
    emit(const TransactionDetailState());
    _subscription = _watchTransactionDetail(id).listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) => state.copyWith(
            status: TransactionDetailStatus.failure,
            failure: failure,
          ),
          (entry) => state.copyWith(
              status: TransactionDetailStatus.ready, entry: entry),
        ),
      );
    });
  }

  void requestDelete() => emit(state.copyWith(deletePrompt: true));

  void cancelDelete() => emit(state.copyWith(deletePrompt: false));

  /// HU-05: soft-deletes and closes the confirmation prompt in the very same
  /// emission that flags [TransactionDetailState.deleted] — a separate emit
  /// that clears the prompt only after would let the sheet flash open again
  /// while the page is navigating away.
  Future<void> confirmDelete() async {
    final id = state.entry?.transaction.id;
    if (id == null) {
      return;
    }
    final result = await _deleteTransaction(id);
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
          state.copyWith(
            status: TransactionDetailStatus.failure,
            failure: failure,
            deletePrompt: false,
          ),
        );
      case Right():
        emit(state.copyWith(deletePrompt: false, deleted: true));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
