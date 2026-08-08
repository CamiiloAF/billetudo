import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/sync/domain/entities/sync_state.dart';
import '../../../../core/sync/domain/entities/sync_status_snapshot.dart';
import '../../../../core/sync/domain/usecases/watch_sync_status_details.dart';
import '../../../../core/sync/presentation/utils/sync_freshness.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/domain/usecases/watch_auth_session.dart';
import '../../../budgets/domain/entities/budget_detail_data.dart';
import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../budgets/domain/usecases/get_budget_by_id.dart';
import '../../../budgets/domain/usecases/get_budget_progress.dart';
import '../../../budgets/domain/usecases/watch_featured_budget_progress.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../../../transactions/domain/usecases/restore_transaction.dart';
import '../../domain/entities/home_snapshot.dart';
import '../../domain/usecases/watch_month_transactions.dart';
import '../../domain/usecases/watch_recent_transactions.dart';
import 'home_state.dart';

/// Orchestrates the Home (HU-03/HU-04/HU-05): it watches the active accounts,
/// "Movimientos recientes" (a literal, period-unbound activity feed — see
/// `WatchRecentTransactions`) and the featured budget's progress for its
/// **navigable** period window (the user's manual pick from Ajustes, or the
/// qualifying global-monthly budget as fallback — see
/// `WatchFeaturedBudgetProgress`), then folds the latest emissions into a
/// [HomeSnapshot] (pure aggregation lives in the entity).
///
/// Talks only to use cases — never a repository or a DAO. Two independent
/// things can change what the hero shows: which budget is featured (an
/// external event — Ajustes, or the budget being archived/deleted) and the
/// period index the user is navigating within it (HU-05's stepper, same
/// pattern as `BudgetDetailCubit`: [_getBudgetById] + [_getBudgetProgress]).
/// "Movimientos recientes" is decoupled from both — it never re-subscribes on
/// either change.
@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
    this._watchAccounts,
    this._watchMonthTransactions,
    this._watchRecentTransactions,
    this._watchAuthSession,
    this._watchSyncStatusDetails,
    this._restoreTransaction,
    this._watchFeaturedBudgetProgress,
    this._getBudgetById,
    this._getBudgetProgress,
  ) : super(HomeState.initial(clock.now()));

  final WatchAccounts _watchAccounts;

  /// Fallback-only: the visible calendar month's transactions, feeding the
  /// hero's spending total when no budget is featured (criterion 5). HU-04's
  /// month picker (`MonthSelectorChip`/`MonthPickerSheet`) navigates it via
  /// [selectMonth], which re-subscribes this stream to the picked month —
  /// mirrors [previousPeriod]/[nextPeriod]'s re-subscription for the
  /// featured-budget case, just against a plain calendar month instead of a
  /// `BudgetPeriodWindow`.
  final WatchMonthTransactions _watchMonthTransactions;
  final WatchRecentTransactions _watchRecentTransactions;
  final WatchAuthSession _watchAuthSession;
  final WatchSyncStatusDetails _watchSyncStatusDetails;
  final RestoreTransaction _restoreTransaction;
  final WatchFeaturedBudgetProgress _watchFeaturedBudgetProgress;
  final GetBudgetById _getBudgetById;
  final GetBudgetProgress _getBudgetProgress;

  StreamSubscription<Result<List<AccountWithBalance>>>? _accountsSub;
  StreamSubscription<Result<List<TransactionWithDetails>>>? _monthTxSub;
  StreamSubscription<Result<List<TransactionWithDetails>>>? _recentTxSub;
  StreamSubscription<AuthSession>? _authSub;
  StreamSubscription<SyncStatusSnapshot>? _syncSub;
  StreamSubscription<Result<BudgetWithProgress?>>? _featuredBudgetSub;
  StreamSubscription<Result<BudgetDetailData>>? _featuredBudgetDataSub;

  Result<List<AccountWithBalance>>? _lastAccounts;
  Result<List<TransactionWithDetails>>? _lastMonthTransactions;
  Result<List<TransactionWithDetails>>? _lastRecentTransactions;

  /// HU-04: the calendar month [_watchMonthTransactions] is currently
  /// subscribed to — "now"'s month until [selectMonth] moves it. Only
  /// meaningful for the no-featured-budget fallback; it plays no part once a
  /// budget is featured (that case navigates its own period window instead,
  /// see [_periodIndex]).
  late DateTime _visibleMonth;

  /// The featured budget's id currently driving [_featuredBudgetDataSub], or
  /// `null` when none is featured. Tracked so a change of *which* budget is
  /// featured resets the navigated period back to "current".
  String? _featuredBudgetId;

  /// The navigated period index for the featured budget; `null` follows the
  /// current period until the user steps away from it — same convention as
  /// `BudgetDetailCubit`.
  int? _periodIndex;

  BudgetDetailData? _featuredBudgetData;

  /// `Right(null)` when no budget is featured, `Right(view)` once the
  /// featured budget's navigated window has been computed, `Left` on
  /// failure. `null` only until the featured-budget stream's first emission
  /// (kept out of [_recompute]'s readiness check, same convention as the
  /// accounts/transactions results).
  Result<BudgetWithProgress?>? _lastFeaturedResult;

  /// Subscribes every stream once. Safe to call again to retry after a
  /// failure.
  Future<void> start() async {
    await _accountsSub?.cancel();
    await _monthTxSub?.cancel();
    await _recentTxSub?.cancel();
    await _authSub?.cancel();
    await _syncSub?.cancel();
    await _featuredBudgetSub?.cancel();
    await _featuredBudgetDataSub?.cancel();
    _featuredBudgetId = null;
    _periodIndex = null;
    _featuredBudgetData = null;
    _lastFeaturedResult = null;

    final now = clock.now();
    _visibleMonth = DateTime(now.year, now.month);
    _accountsSub = _watchAccounts().listen(_onAccounts);
    _monthTxSub =
        _watchMonthTransactions(_visibleMonth).listen(_onMonthTransactions);
    _recentTxSub = _watchRecentTransactions().listen(_onRecentTransactions);
    _authSub = _watchAuthSession().listen(_onAuthSession);
    _syncSub = _watchSyncStatusDetails().listen(_onSyncSnapshot);
    _featuredBudgetSub =
        _watchFeaturedBudgetProgress().listen(_onFeaturedBudgetProgress);
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
  ///
  /// HU-08 adds the fourth state. Two conditions map to it, both amber:
  /// writes held back in the quarantine, and a last successful sync older
  /// than 24 h. The second one is the incident itself — "syncing" and
  /// "syncing since three days ago" must not render the same, and the
  /// indicator only has four states to say it with.
  void _onSyncSnapshot(SyncStatusSnapshot snapshot) {
    if (isClosed) {
      return;
    }
    final isStale =
        SyncFreshness.isStale(snapshot.lastSyncedAt, now: clock.now());
    final syncStatus = switch (snapshot.state) {
      SyncState.stalled => HomeSyncStatus.attention,
      _ when isStale => HomeSyncStatus.attention,
      SyncState.synced => HomeSyncStatus.synced,
      SyncState.syncing => HomeSyncStatus.syncing,
      SyncState.offline => HomeSyncStatus.offline,
    };
    // `failure` is re-passed on purpose: `copyWith` drops it when omitted, and
    // a sync tick must not clear a failure the body is still rendering.
    emit(
      state.copyWith(
        syncStatus: syncStatus,
        syncSnapshot: snapshot,
        failure: state.failure,
      ),
    );
  }

  void _onAccounts(Result<List<AccountWithBalance>> result) {
    _lastAccounts = result;
    _recompute();
  }

  void _onMonthTransactions(Result<List<TransactionWithDetails>> result) {
    _lastMonthTransactions = result;
    _recompute();
  }

  void _onRecentTransactions(Result<List<TransactionWithDetails>> result) {
    _lastRecentTransactions = result;
    _recompute();
  }

  /// Tracks *which* budget (if any) is featured. This use case deliberately
  /// only answers the "current window" question (see its own class docs); the
  /// moment the featured id changes — including from/to `null`, e.g. the
  /// previous pick got archived or deleted — the navigated period resets and
  /// this cubit takes over navigation via [_getBudgetById]/[_getBudgetProgress].
  void _onFeaturedBudgetProgress(Result<BudgetWithProgress?> result) {
    if (isClosed) {
      return;
    }
    final newId = result.getRight().toNullable()?.budget.id;
    // `_lastFeaturedResult == null` guards the very first emission: with no
    // budget featured, `newId` reads `null`, same as the untouched
    // `_featuredBudgetId` default — without this guard that first "no
    // budget" emission would be mistaken for "unchanged, nothing to do" and
    // never reach `_recompute`, leaving the cubit stuck in loading forever.
    if (_lastFeaturedResult != null && newId == _featuredBudgetId) {
      // Same budget still featured: a failure here still needs to surface,
      // but a benign re-emission (e.g. the settings stream ticking) must not
      // reset the period the user is navigating.
      if (result.isLeft()) {
        _lastFeaturedResult = result;
        _recompute();
      }
      return;
    }

    _featuredBudgetId = newId;
    _periodIndex = null;
    _featuredBudgetData = null;
    unawaited(_featuredBudgetDataSub?.cancel());

    if (newId == null) {
      _lastFeaturedResult = const Right(null);
      _recompute();
      return;
    }

    if (result.isLeft()) {
      _lastFeaturedResult = result;
      _recompute();
      return;
    }

    _featuredBudgetDataSub =
        _getBudgetById(newId).listen(_onFeaturedBudgetData);
  }

  void _onFeaturedBudgetData(Result<BudgetDetailData> result) {
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) {
        _lastFeaturedResult = Left(failure);
        _recompute();
      },
      (data) {
        _featuredBudgetData = data;
        _emitFeaturedView();
      },
    );
  }

  /// Recomputes the featured budget's view for [_periodIndex] (or the current
  /// period when `null`) and folds it into [_lastFeaturedResult] as a
  /// [BudgetWithProgress] — the same shape `WatchFeaturedBudgetProgress`
  /// produces for the "current" case, so downstream (the snapshot, the hero)
  /// never needs to know navigation happened.
  void _emitFeaturedView() {
    final data = _featuredBudgetData;
    if (data == null) {
      return;
    }
    final view =
        _getBudgetProgress(data, now: clock.now(), index: _periodIndex);
    // Keep the resolved index so navigation is relative to what is shown.
    _periodIndex = view.window.index;
    _lastFeaturedResult = Right(
      BudgetWithProgress(
        budget: data.budget,
        scope: data.scope,
        window: view.window,
        progress: view.progress,
      ),
    );
    _recompute();
  }

  /// HU-05: step the hero's stepper to the previous period of the featured
  /// budget, if any.
  void previousPeriod() {
    final window = _lastFeaturedResult?.getRight().toNullable()?.window;
    if (window == null || !window.hasPrevious) {
      return;
    }
    _periodIndex = window.index - 1;
    _emitFeaturedView();
  }

  /// HU-05: step the hero's stepper to the next period of the featured
  /// budget, if any.
  void nextPeriod() {
    final window = _lastFeaturedResult?.getRight().toNullable()?.window;
    if (window == null || !window.hasNext) {
      return;
    }
    _periodIndex = window.index + 1;
    _emitFeaturedView();
  }

  /// HU-04: jumps the fallback hero's visible calendar month straight to
  /// [month] (any day within it), picked from `MonthPickerSheet`'s grid.
  /// Only meaningful without a featured budget — see [_visibleMonth]'s docs.
  ///
  /// Re-subscribes [_watchMonthTransactions] to the new month and resets
  /// [_lastMonthTransactions] until its first emission, same convention
  /// [_onFeaturedBudgetProgress] uses when [_featuredBudgetId] changes:
  /// [_recompute] must not emit against the outgoing month's stale data
  /// while the new stream is still catching up.
  void selectMonth(DateTime month) {
    if (isClosed) {
      return;
    }
    final normalized = DateTime(month.year, month.month);
    if (normalized == _visibleMonth) {
      return;
    }
    _visibleMonth = normalized;
    _lastMonthTransactions = null;
    unawaited(_monthTxSub?.cancel());
    _monthTxSub =
        _watchMonthTransactions(normalized).listen(_onMonthTransactions);
  }

  void _recompute() {
    if (isClosed) {
      return;
    }
    final accounts = _lastAccounts;
    final monthTransactions = _lastMonthTransactions;
    final recentTransactions = _lastRecentTransactions;
    final featured = _lastFeaturedResult;
    if (accounts == null ||
        monthTransactions == null ||
        recentTransactions == null ||
        featured == null) {
      return;
    }

    final failure = accounts.getLeft().toNullable() ??
        monthTransactions.getLeft().toNullable() ??
        recentTransactions.getLeft().toNullable() ??
        featured.getLeft().toNullable();
    if (failure != null) {
      emit(state.copyWith(status: HomeStatus.failure, failure: failure));
      return;
    }

    final snapshot = HomeSnapshot.from(
      month: _visibleMonth,
      transactions: monthTransactions.getRight().toNullable() ?? const [],
      accounts: accounts.getRight().toNullable() ?? const [],
      recentTransactions: recentTransactions.getRight().toNullable(),
      budgetProgress: featured.getRight().toNullable(),
    );
    emit(state.copyWith(status: HomeStatus.ready, snapshot: snapshot));
  }

  /// HU-05: offers the "Deshacer" snackbar for a delete that happened in the
  /// transaction detail page opened from Home's recent activity. The recent
  /// feed itself removes the row once `deletedAt` lands, so this only tracks
  /// the undo affordance.
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
    await _monthTxSub?.cancel();
    await _recentTxSub?.cancel();
    await _authSub?.cancel();
    await _syncSub?.cancel();
    await _featuredBudgetSub?.cancel();
    await _featuredBudgetDataSub?.cancel();
    return super.close();
  }
}
