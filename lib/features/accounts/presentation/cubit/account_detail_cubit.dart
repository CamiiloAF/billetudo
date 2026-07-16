import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/security/secure_clipboard.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_with_balance.dart';
import '../../domain/usecases/archive_account.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/get_account_deletion_impact.dart';
import '../../domain/usecases/get_account_number.dart';
import '../../domain/usecases/set_card_balance_primary.dart';
import '../../domain/usecases/watch_account_detail.dart';
import 'account_detail_state.dart';

/// Drives the account detail (HU-03/HU-04/HU-07/HU-08).
///
/// Everything it does goes through a use case; [SecureClipboard] is the one
/// exception, and it is a platform service, not a repository.
@injectable
class AccountDetailCubit extends Cubit<AccountDetailState> {
  AccountDetailCubit(
    this._watchAccountDetail,
    this._getAccountNumber,
    this._setCardBalancePrimary,
    this._getDeletionImpact,
    this._archiveAccount,
    this._deleteAccount,
    this._clipboard,
  ) : super(const AccountDetailState());

  final WatchAccountDetail _watchAccountDetail;
  final GetAccountNumber _getAccountNumber;
  final SetCardBalancePrimary _setCardBalancePrimary;
  final GetAccountDeletionImpact _getDeletionImpact;
  final ArchiveAccount _archiveAccount;
  final DeleteAccount _deleteAccount;
  final SecureClipboard _clipboard;

  StreamSubscription<Result<AccountWithBalance>>? _subscription;
  late String _accountId;

  Future<void> start(String id) async {
    _accountId = id;
    await _subscription?.cancel();
    emit(const AccountDetailState());
    _subscription = _watchAccountDetail(id).listen(_onEntry);
  }

  void _onEntry(Result<AccountWithBalance> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyKeepingNumber(
          status: AccountDetailStatus.failure,
          failure: failure,
        ),
        (entry) => state.copyKeepingNumber(
          status: AccountDetailStatus.ready,
          entry: entry,
        ),
      ),
    );
  }

  /// HU-03: reads the number from secure storage. Nothing is cached — hiding
  /// drops it and revealing again reads it again.
  Future<void> revealNumber() async {
    final result = await _getAccountNumber(_accountId);
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(failure: failure));
      case Right(value: final number) when number != null:
        emit(state.copyWith(revealedNumber: number));
      case Right():
        break;
    }
  }

  /// Drops the revealed number. [AccountDetailState.copyWith] does not carry it
  /// over, so this is enough to mask it again.
  void hideNumber() => emit(state.copyWith());

  /// HU-03: copies through [SecureClipboard], which wipes the clipboard 60s
  /// later. Returns whether there was a number to copy, so the page can confirm
  /// it to the user.
  Future<bool> copyNumber() async {
    final result = await _getAccountNumber(_accountId);
    if (isClosed) {
      return false;
    }
    switch (result) {
      case Left(value: final failure):
        emit(state.copyKeepingNumber(failure: failure));
        return false;
      case Right(value: final number) when number != null:
        await _clipboard.copySensitive(number);
        return true;
      case Right():
        return false;
    }
  }

  /// HU-04: remembers which figure the card highlights. A preference: it never
  /// changes the balance.
  Future<void> cardViewChanged(CardBalanceView view) async {
    if (state.cardView == view) {
      return;
    }
    final result = await _setCardBalancePrimary(_accountId, view);
    if (isClosed) {
      return;
    }
    if (result case Left(value: final failure)) {
      emit(state.copyKeepingNumber(failure: failure));
    }
  }

  Future<void> promptArchive() async =>
      emit(state.copyKeepingNumber(prompt: AccountDetailPrompt.archive));

  /// HU-08: loads the impact first, so the sheet can state it — and so the last
  /// active account gets the blocking sheet instead of a confirmation it could
  /// never honour.
  Future<void> promptDelete() async {
    final result = await _getDeletionImpact(_accountId);
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(state.copyKeepingNumber(failure: failure));
      case Right(value: final impact):
        emit(
          state.copyKeepingNumber(
            impact: impact,
            prompt: impact.isLastAccount
                ? AccountDetailPrompt.cannotDelete
                : AccountDetailPrompt.delete,
          ),
        );
    }
  }

  void dismissPrompt() =>
      emit(state.copyKeepingNumber(prompt: AccountDetailPrompt.none));

  Future<void> confirmArchive() async =>
      _runClosing(() => _archiveAccount(_accountId));

  Future<void> confirmDelete() async =>
      _runClosing(() => _deleteAccount(_accountId));

  /// Runs an action that ends the screen: on success the page pops, on failure
  /// the prompt closes and the error surfaces.
  ///
  /// Cancels [_subscription] *before* running [action], not after. Archiving
  /// and deleting both change what `_watchAccountDetail` matches (delete
  /// tombstones the row so the join stops returning it; archive still returns
  /// it, just re-emitting the same entry), so Drift's reactive `.watch()`
  /// fires again as soon as the write commits — which can happen while
  /// `action()` is still being awaited, before this method ever reaches its
  /// own `switch`. That interim emission (`Left(NotFoundFailure)` for delete)
  /// changes `state.status` out from under this method, which re-triggers the
  /// page's `BlocConsumer` listener via its `previous.status != current.status`
  /// condition — and since `status` isn't `closed` yet, the listener replays
  /// `_handlePrompt`, silently reopening the confirmation sheet a second time
  /// (`state.prompt` is still `delete`/`archive`). The `Navigator.pop()` that
  /// eventually fires for the real `closed` status then pops that phantom
  /// second sheet instead of the page, and the page is stuck showing its
  /// spinner forever. Cancelling first makes that interim emission impossible
  /// — confirmed against a live repro, not just reasoned about.
  ///
  /// On failure the page stays open, so it resubscribes to keep receiving
  /// live updates.
  Future<void> _runClosing(FutureResult<Unit> Function() action) async {
    await _subscription?.cancel();
    _subscription = null;
    final result = await action();
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        _subscription = _watchAccountDetail(_accountId).listen(_onEntry);
        emit(
          state.copyKeepingNumber(
            prompt: AccountDetailPrompt.none,
            failure: failure,
          ),
        );
      case Right():
        emit(
          state.copyKeepingNumber(
            status: AccountDetailStatus.closed,
            prompt: AccountDetailPrompt.none,
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
