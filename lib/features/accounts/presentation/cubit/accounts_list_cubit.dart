import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/account_with_balance.dart';
import '../../domain/entities/accounts_overview.dart';
import '../../domain/usecases/reorder_accounts.dart';
import '../../domain/usecases/watch_accounts.dart';
import '../../domain/usecases/watch_accounts_overview.dart';
import 'accounts_list_state.dart';

/// Drives the accounts list (HU-04/HU-09) and its Total Card.
///
/// Talks only to use cases. The list and the overview come from two streams
/// over the same source of truth, so the anti-cross-currency rule stays inside
/// `WatchAccountsOverview` instead of being re-derived here.
@injectable
class AccountsListCubit extends Cubit<AccountsListState> {
  AccountsListCubit(
    this._watchAccounts,
    this._watchAccountsOverview,
    this._reorderAccounts,
  ) : super(const AccountsListState());

  final WatchAccounts _watchAccounts;
  final WatchAccountsOverview _watchAccountsOverview;
  final ReorderAccounts _reorderAccounts;

  StreamSubscription<Result<List<AccountWithBalance>>>? _accountsSubscription;
  StreamSubscription<Result<AccountsOverview>>? _overviewSubscription;

  /// Subscribes to both streams. Safe to call again to retry after an error.
  Future<void> start() async {
    await _cancelSubscriptions();
    emit(const AccountsListState());
    _accountsSubscription = _watchAccounts().listen(_onAccounts);
    _overviewSubscription = _watchAccountsOverview().listen(_onOverview);
  }

  void _onAccounts(Result<List<AccountWithBalance>> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: AccountsListStatus.failure,
          failure: failure,
        ),
        (accounts) => state.copyWith(
          status: AccountsListStatus.ready,
          accounts: accounts,
        ),
      ),
    );
  }

  void _onOverview(Result<AccountsOverview> result) {
    if (isClosed) {
      return;
    }
    // The list stream owns the error state: a failure here would be the same
    // one, reported twice.
    if (result case Right(value: final overview)) {
      emit(state.copyWith(overview: overview));
    }
  }

  /// HU-09: persists the drag. The list is emitted right away so the row stays
  /// where the user dropped it; the stream then confirms it from the database.
  ///
  /// [oldIndex] and [newIndex] are `SliverReorderableList.onReorder`'s raw
  /// values: [newIndex] is the drop slot in the list as it stood *before* the
  /// dragged row was removed, per the framework's own contract. Removing the
  /// row from [oldIndex] shifts every later index down by one, so when
  /// [oldIndex] is before [newIndex] this adjusts [newIndex] before inserting
  /// — the caller (the widget) is not expected to do this itself.
  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex == oldIndex ||
        oldIndex >= state.accounts.length ||
        newIndex > state.accounts.length) {
      return;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final reordered = [...state.accounts];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    emit(state.copyWith(accounts: reordered));

    final result = await _reorderAccounts(
      [for (final entry in reordered) entry.account.id],
    );
    if (isClosed) {
      return;
    }
    if (result case Left(value: final failure)) {
      emit(
        state.copyWith(status: AccountsListStatus.failure, failure: failure),
      );
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _accountsSubscription?.cancel();
    await _overviewSubscription?.cancel();
    _accountsSubscription = null;
    _overviewSubscription = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    return super.close();
  }
}
