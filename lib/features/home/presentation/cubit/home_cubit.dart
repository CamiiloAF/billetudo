import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/sync/domain/entities/sync_state.dart';
import '../../../../core/sync/domain/usecases/watch_sync_status.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/domain/usecases/watch_auth_session.dart';
import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../budgets/domain/usecases/watch_global_monthly_budget_progress.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../../../transactions/domain/usecases/restore_transaction.dart';
import '../../domain/entities/home_snapshot.dart';
import '../../domain/usecases/watch_month_transactions.dart';
import 'home_state.dart';

/// Orchestrates the Home (HU-03/HU-04/HU-05): it watches the active accounts,
/// the visible month's transactions and the qualifying global-monthly budget
/// (`aOhoY`), then folds the latest emissions into a [HomeSnapshot] (pure
/// aggregation lives in the entity).
///
/// Talks only to use cases — never a repository or a DAO. The month is the
/// Home's navigation unit (HU-04); changing it re-subscribes the transactions
/// stream while the accounts and budget-progress streams stay put.
@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
    this._watchAccounts,
    this._watchMonthTransactions,
    this._watchAuthSession,
    this._watchSyncStatus,
    this._restoreTransaction,
    this._watchGlobalMonthlyBudgetProgress,
  ) : super(HomeState.initial(DateTime.now()));

  final WatchAccounts _watchAccounts;
  final WatchMonthTransactions _watchMonthTransactions;
  final WatchAuthSession _watchAuthSession;
  final WatchSyncStatus _watchSyncStatus;
  final RestoreTransaction _restoreTransaction;
  final WatchGlobalMonthlyBudgetProgress _watchGlobalMonthlyBudgetProgress;

  StreamSubscription<Result<List<AccountWithBalance>>>? _accountsSub;
  StreamSubscription<Result<List<TransactionWithDetails>>>? _transactionsSub;
  StreamSubscription<AuthSession>? _authSub;
  StreamSubscription<SyncState>? _syncSub;
  StreamSubscription<Result<BudgetWithProgress?>>? _budgetProgressSub;

  Result<List<AccountWithBalance>>? _lastAccounts;
  Result<List<TransactionWithDetails>>? _lastTransactions;
  Result<BudgetWithProgress?>? _lastBudgetProgress;

  /// Subscribes with the current month. Safe to call again to retry after a
  /// failure.
  Future<void> start() async {
    await _accountsSub?.cancel();
    await _authSub?.cancel();
    await _syncSub?.cancel();
    await _budgetProgressSub?.cancel();
    _accountsSub = _watchAccounts().listen(_onAccounts);
    _authSub = _watchAuthSession().listen(_onAuthSession);
    _syncSub = _watchSyncStatus().listen(_onSyncState);
    _budgetProgressSub =
        _watchGlobalMonthlyBudgetProgress().listen(_onBudgetProgress);
    await _subscribeTransactions(state.month);
  }

  /// HU-07: the session updates the greeting/avatar only — it never gates the
  /// Home's loading/ready status (that stays on accounts + transactions).
  void _onAuthSession(AuthSession session) {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(user: session.user, updateUser: true));
  }

  /// HU-10: the sync indicator is passive and independent of [HomeStatus] —
  /// being offline or mid-merge never turns the Home into an error screen.
  void _onSyncState(SyncState syncState) {
    if (isClosed) {
      return;
    }
    final syncStatus = switch (syncState) {
      SyncState.synced => HomeSyncStatus.synced,
      SyncState.syncing => HomeSyncStatus.syncing,
      SyncState.offline => HomeSyncStatus.offline,
    };
    // `failure` is re-passed on purpose: `copyWith` drops it when omitted, and
    // a sync tick must not clear a failure the body is still rendering.
    emit(state.copyWith(syncStatus: syncStatus, failure: state.failure));
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
    _transactionsSub = _watchMonthTransactions(month).listen(_onTransactions);
  }

  void _onAccounts(Result<List<AccountWithBalance>> result) {
    _lastAccounts = result;
    _recompute();
  }

  void _onTransactions(Result<List<TransactionWithDetails>> result) {
    _lastTransactions = result;
    _recompute();
  }

  void _onBudgetProgress(Result<BudgetWithProgress?> result) {
    _lastBudgetProgress = result;
    _recompute();
  }

  void _recompute() {
    if (isClosed) {
      return;
    }
    final accounts = _lastAccounts;
    final transactions = _lastTransactions;
    final budgetProgress = _lastBudgetProgress;
    if (accounts == null || transactions == null || budgetProgress == null) {
      return;
    }

    final failure = accounts.getLeft().toNullable() ??
        transactions.getLeft().toNullable() ??
        budgetProgress.getLeft().toNullable();
    if (failure != null) {
      emit(state.copyWith(status: HomeStatus.failure, failure: failure));
      return;
    }

    // The budget's progress is always computed against its real current
    // window (`now`), so it is only meaningful while viewing today's month —
    // browsing a past month would otherwise show a stale "current" bar for a
    // window that does not cover it (HU-03/HU-04 boundary; not a documented
    // edge case, kept deterministic).
    final isViewingCurrentMonth = state.month == state.currentMonth;

    final snapshot = HomeSnapshot.from(
      month: state.month,
      transactions: transactions.getRight().toNullable() ?? const [],
      accounts: accounts.getRight().toNullable() ?? const [],
      budgetProgress:
          isViewingCurrentMonth ? budgetProgress.getRight().toNullable() : null,
    );
    emit(state.copyWith(status: HomeStatus.ready, snapshot: snapshot));
  }

  /// HU-05: offers the "Deshacer" snackbar for a delete that happened in the
  /// transaction detail page opened from Home's recent activity. The month's
  /// transactions stream itself removes the row once `deletedAt` lands, so
  /// this only tracks the undo affordance.
  void notifyExternalDelete(String id) {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(pendingUndoId: id));
  }

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
  void dismissUndo() {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(clearPendingUndo: true));
  }

  @override
  Future<void> close() async {
    await _accountsSub?.cancel();
    await _transactionsSub?.cancel();
    await _authSub?.cancel();
    await _syncSub?.cancel();
    await _budgetProgressSub?.cancel();
    return super.close();
  }
}
