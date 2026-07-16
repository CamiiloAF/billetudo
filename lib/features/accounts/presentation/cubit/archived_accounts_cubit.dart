import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/account_with_balance.dart';
import '../../domain/usecases/unarchive_account.dart';
import '../../domain/usecases/watch_archived_accounts.dart';
import 'archived_accounts_state.dart';

/// HU-07: the archived accounts list and the way back from it.
///
/// Unarchiving needs no local bookkeeping: the account leaves this stream on
/// its own once the write lands.
@injectable
class ArchivedAccountsCubit extends Cubit<ArchivedAccountsState> {
  ArchivedAccountsCubit(this._watchArchivedAccounts, this._unarchiveAccount)
      : super(const ArchivedAccountsState());

  final WatchArchivedAccounts _watchArchivedAccounts;
  final UnarchiveAccount _unarchiveAccount;

  StreamSubscription<Result<List<AccountWithBalance>>>? _subscription;

  Future<void> start() async {
    await _subscription?.cancel();
    emit(const ArchivedAccountsState());
    _subscription = _watchArchivedAccounts().listen(_onAccounts);
  }

  void _onAccounts(Result<List<AccountWithBalance>> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: ArchivedAccountsStatus.failure,
          failure: failure,
        ),
        (accounts) => state.copyWith(
          status: ArchivedAccountsStatus.ready,
          accounts: accounts,
        ),
      ),
    );
  }

  Future<void> unarchive(String id) async {
    final result = await _unarchiveAccount(id);
    if (isClosed) {
      return;
    }
    if (result case Left(value: final failure)) {
      emit(
        state.copyWith(
          status: ArchivedAccountsStatus.failure,
          failure: failure,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
