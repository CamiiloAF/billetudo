import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../../domain/entities/home_snapshot.dart';
import '../../domain/usecases/watch_month_transactions.dart';
import 'home_state.dart';

/// Orchestrates the Home (HU-03/HU-04/HU-05): it watches the active accounts
/// and the visible month's transactions, then folds both latest emissions into
/// a [HomeSnapshot] (pure aggregation lives in the entity).
///
/// Talks only to use cases — never a repository or a DAO. The month is the
/// Home's navigation unit (HU-04); changing it re-subscribes the transactions
/// stream while the accounts stream stays put.
@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._watchAccounts, this._watchMonthTransactions)
      : super(HomeState.initial(DateTime.now()));

  final WatchAccounts _watchAccounts;
  final WatchMonthTransactions _watchMonthTransactions;

  StreamSubscription<Result<List<AccountWithBalance>>>? _accountsSub;
  StreamSubscription<Result<List<TransactionWithDetails>>>? _transactionsSub;

  Result<List<AccountWithBalance>>? _lastAccounts;
  Result<List<TransactionWithDetails>>? _lastTransactions;

  /// Subscribes with the current month. Safe to call again to retry after a
  /// failure.
  Future<void> start() async {
    await _accountsSub?.cancel();
    _accountsSub = _watchAccounts().listen(_onAccounts);
    await _subscribeTransactions(state.month);
  }

  /// HU-04: change the visible month (hero + recent feed update together).
  /// Future months are rejected — the picker disables them, this is the guard.
  Future<void> selectMonth(DateTime month) async {
    final normalized = DateTime(month.year, month.month);
    if (normalized == state.month || normalized.isAfter(state.currentMonth)) {
      return;
    }
    _lastTransactions = null;
    emit(state.copyWith(month: normalized, status: HomeStatus.loading));
    await _subscribeTransactions(normalized);
  }

  Future<void> _subscribeTransactions(DateTime month) async {
    await _transactionsSub?.cancel();
    _transactionsSub =
        _watchMonthTransactions(month).listen(_onTransactions);
  }

  void _onAccounts(Result<List<AccountWithBalance>> result) {
    _lastAccounts = result;
    _recompute();
  }

  void _onTransactions(Result<List<TransactionWithDetails>> result) {
    _lastTransactions = result;
    _recompute();
  }

  void _recompute() {
    if (isClosed) {
      return;
    }
    final accounts = _lastAccounts;
    final transactions = _lastTransactions;
    if (accounts == null || transactions == null) {
      return;
    }

    final failure = accounts.getLeft().toNullable() ??
        transactions.getLeft().toNullable();
    if (failure != null) {
      emit(state.copyWith(status: HomeStatus.failure, failure: failure));
      return;
    }

    final snapshot = HomeSnapshot.from(
      month: state.month,
      transactions: transactions.getRight().toNullable() ?? const [],
      accounts: accounts.getRight().toNullable() ?? const [],
    );
    emit(state.copyWith(status: HomeStatus.ready, snapshot: snapshot));
  }

  @override
  Future<void> close() async {
    await _accountsSub?.cancel();
    await _transactionsSub?.cancel();
    return super.close();
  }
}
