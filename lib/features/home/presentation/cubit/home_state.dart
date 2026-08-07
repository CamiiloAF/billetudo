import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/sync/domain/entities/sync_status_snapshot.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../../domain/entities/home_snapshot.dart';
import '../../domain/entities/month_spending.dart';

/// The three states the Home body renders: [loading] (skeletons), [ready]
/// (data or the welcome/empty state), and [failure]. There is deliberately no
/// full-screen error: the Home is local-first (HU-10).
enum HomeStatus { loading, ready, failure }

/// The Home's sync indicator (HU-10 + HU-08's fourth state). Mirrors
/// `core/sync`'s `SyncState`, which the cubit maps from the live sync engine;
/// the default only holds until that stream's first emission.
enum HomeSyncStatus {
  synced,
  syncing,
  offline,

  /// Changes are held back, or the last successful sync is older than
  /// `SyncFreshness.staleAfter`. Amber, never the destructive red: the data is
  /// safe on the phone, it just is not backed up. Sharing one state with
  /// "syncing for three days" is deliberate — that is the case HU-08 exists to
  /// stop looking healthy.
  attention,
}

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.loading,
    this.snapshot,
    this.syncStatus = HomeSyncStatus.synced,
    this.syncSnapshot = const SyncStatusSnapshot.unknown(),
    this.failure,
    this.user,
    this.pendingUndoId,
  });

  /// No navigable "visible month" survives this redesign: "Movimientos
  /// recientes" is unbound (criterion 1) and the hero, without a featured
  /// budget, always shows the current calendar month with no selector
  /// (criterion 5) — there is nothing left to seed from `now` besides the
  /// zero-argument default below.
  factory HomeState.initial(DateTime now) => const HomeState();

  final HomeStatus status;

  /// Present once data has landed.
  final HomeSnapshot? snapshot;

  final HomeSyncStatus syncStatus;

  /// The detail behind [syncStatus]: when the last full sync landed and how
  /// many writes are held back. The cloud sheet needs both — showing the time
  /// in every one of its states is the literal lesson of the incident.
  final SyncStatusSnapshot syncSnapshot;

  final Failure? failure;

  /// The signed-in user (HU-07), or null when local-first with no session.
  /// Tracked independently of [status]: the auth session never gates the
  /// Home's loading/ready — only accounts + transactions do.
  final AuthUser? user;

  /// The id of the transaction a "Deshacer" snackbar is currently offered
  /// for, after a delete triggered from the transaction detail page opened
  /// from Home's recent activity. `null` once dismissed or undone.
  final String? pendingUndoId;

  MonthSpending? get spending => snapshot?.spending;

  /// The hero's "con presupuesto" progress, if any (HU-03, `aOhoY`). Its
  /// `window` is the period the hero's stepper is currently showing — the
  /// budget detail's own current window when the user has not navigated, or
  /// whatever period `HomeCubit.previousPeriod`/`HomeCubit.nextPeriod`
  /// stepped to since (HU-05).
  BudgetWithProgress? get budgetProgress => snapshot?.budgetProgress;

  List<TransactionWithDetails> get recentActivity =>
      snapshot?.recentActivity ?? const [];

  /// The active accounts with balances for the "Mis cuentas" strip (bugfix
  /// item 8). Empty until the first snapshot lands.
  List<AccountWithBalance> get accounts => snapshot?.accounts ?? const [];

  bool get isLoading => status == HomeStatus.loading;

  /// HU-08: welcome/empty state — no movements at all recently.
  bool get isEmpty => status == HomeStatus.ready && (snapshot?.isEmpty ?? true);

  HomeState copyWith({
    HomeStatus? status,
    HomeSnapshot? snapshot,
    HomeSyncStatus? syncStatus,
    SyncStatusSnapshot? syncSnapshot,
    Failure? failure,
    AuthUser? user,
    bool clearSnapshot = false,
    bool updateUser = false,
    String? pendingUndoId,
    bool clearPendingUndo = false,
  }) =>
      HomeState(
        status: status ?? this.status,
        snapshot: clearSnapshot ? null : (snapshot ?? this.snapshot),
        syncStatus: syncStatus ?? this.syncStatus,
        syncSnapshot: syncSnapshot ?? this.syncSnapshot,
        failure: failure,
        // The session updates independently: only overwrite [user] when the
        // auth stream emits (so it can also be cleared to null on sign-out).
        user: updateUser ? user : this.user,
        pendingUndoId:
            clearPendingUndo ? null : (pendingUndoId ?? this.pendingUndoId),
      );

  @override
  List<Object?> get props => [
        status,
        snapshot,
        syncStatus,
        syncSnapshot,
        failure,
        user,
        pendingUndoId,
      ];
}
