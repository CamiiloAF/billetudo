import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';

enum AccountFilterStatus { loading, ready, failure }

/// HU-06a: the account filter bottom sheet's own selection, edited freely and
/// only handed back to `TransactionsListCubit` when the user taps "Aplicar" —
/// so opening the sheet and dismissing it never mutates the active filter.
class AccountFilterState extends Equatable {
  AccountFilterState({
    this.status = AccountFilterStatus.loading,
    this.accounts = const <AccountWithBalance>[],
    Set<String> selected = const <String>{},
    this.failure,
  }) : selected = Set.unmodifiable(selected);

  final AccountFilterStatus status;
  final List<AccountWithBalance> accounts;

  /// Empty means "all accounts", the default with no badge (HU-06a).
  final Set<String> selected;

  final Failure? failure;

  AccountFilterState copyWith({
    AccountFilterStatus? status,
    List<AccountWithBalance>? accounts,
    Set<String>? selected,
    Failure? failure,
  }) =>
      AccountFilterState(
        status: status ?? this.status,
        accounts: accounts ?? this.accounts,
        selected: selected ?? this.selected,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, accounts, selected, failure];
}

/// Drives the account filter sheet of HU-06a: multiple selection over the
/// live account list, with a symmetric "Todas"/"Ninguna" and per-row toggle.
@injectable
class AccountFilterCubit extends Cubit<AccountFilterState> {
  AccountFilterCubit(this._watchAccounts) : super(AccountFilterState());

  final WatchAccounts _watchAccounts;

  StreamSubscription<Result<List<AccountWithBalance>>>? _subscription;

  /// Opens the sheet with [initialSelected] (the filter's current value).
  Future<void> start(Set<String> initialSelected) async {
    await _subscription?.cancel();
    emit(AccountFilterState(selected: initialSelected));
    _subscription = _watchAccounts().listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) => state.copyWith(
            status: AccountFilterStatus.failure,
            failure: failure,
          ),
          (accounts) => state.copyWith(
            status: AccountFilterStatus.ready,
            accounts: accounts,
          ),
        ),
      );
    });
  }

  void toggle(String accountId) {
    final next = Set<String>.of(state.selected);
    if (!next.remove(accountId)) {
      next.add(accountId);
    }
    emit(state.copyWith(selected: next));
  }

  /// Ticks every account's checkbox.
  void selectAll() => emit(
        state.copyWith(
          selected: {for (final entry in state.accounts) entry.account.id},
        ),
      );

  /// Clears every checkbox, back to the HU-06a default (all accounts, no
  /// badge — an empty selection means "no filter").
  void selectNone() => emit(state.copyWith(selected: const <String>{}));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
