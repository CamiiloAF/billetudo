import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../../domain/entities/home_snapshot.dart';
import '../../domain/entities/month_spending.dart';

/// The three states the Home body renders: [loading] (skeletons), [ready]
/// (data or the welcome/empty state), and [failure]. There is deliberately no
/// full-screen error: the Home is local-first (HU-10).
enum HomeStatus { loading, ready, failure }

/// The passive sync indicator (HU-10). Informative only, never a tap target.
/// Mirrors `core/sync`'s `SyncState`, which the cubit maps from the live sync
/// engine; the default only holds until that stream's first emission.
enum HomeSyncStatus { synced, syncing, offline }

class HomeState extends Equatable {
  const HomeState({
    required this.month,
    required this.currentMonth,
    this.status = HomeStatus.loading,
    this.snapshot,
    this.syncStatus = HomeSyncStatus.synced,
    this.failure,
    this.user,
    this.pendingUndoId,
  });

  /// The month currently visible (first day, at midnight). Defaults to
  /// [currentMonth] (HU-04).
  factory HomeState.initial(DateTime now) {
    final month = DateTime(now.year, now.month);
    return HomeState(month: month, currentMonth: month);
  }

  final HomeStatus status;

  /// The visible month (HU-04). Drives both the hero and the recent feed.
  final DateTime month;

  /// The current calendar month: the ceiling of the month picker (future
  /// months are disabled, HU-04).
  final DateTime currentMonth;

  /// Present once data has landed for [month].
  final HomeSnapshot? snapshot;

  final HomeSyncStatus syncStatus;
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

  List<TransactionWithDetails> get recentActivity =>
      snapshot?.recentActivity ?? const [];

  bool get isLoading => status == HomeStatus.loading;

  /// HU-08: welcome/empty state — no movements at all in [month].
  bool get isEmpty => status == HomeStatus.ready && (snapshot?.isEmpty ?? true);

  HomeState copyWith({
    HomeStatus? status,
    DateTime? month,
    HomeSnapshot? snapshot,
    HomeSyncStatus? syncStatus,
    Failure? failure,
    AuthUser? user,
    bool clearSnapshot = false,
    bool updateUser = false,
    String? pendingUndoId,
    bool clearPendingUndo = false,
  }) =>
      HomeState(
        status: status ?? this.status,
        month: month ?? this.month,
        currentMonth: currentMonth,
        snapshot: clearSnapshot ? null : (snapshot ?? this.snapshot),
        syncStatus: syncStatus ?? this.syncStatus,
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
        month,
        currentMonth,
        snapshot,
        syncStatus,
        failure,
        user,
        pendingUndoId,
      ];
}
