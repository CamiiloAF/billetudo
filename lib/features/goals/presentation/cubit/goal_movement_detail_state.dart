import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/goal_movement_accounts.dart';

/// The movement detail sheet's (`N8Dv2e`) own lifecycle: resolving the
/// origin/destination account names of a money-moving movement is the only
/// thing that needs a load — a tracking-only movement has nothing to fetch
/// and goes straight to [GoalMovementDetailStatus.ready].
enum GoalMovementDetailStatus { loading, ready, failure }

class GoalMovementDetailState extends Equatable {
  const GoalMovementDetailState({
    this.status = GoalMovementDetailStatus.loading,
    this.accounts,
    this.failure,
  });

  final GoalMovementDetailStatus status;

  /// `null` for a tracking-only movement, or while [status] is `loading`.
  final GoalMovementAccounts? accounts;

  final Failure? failure;

  GoalMovementDetailState copyWith({
    GoalMovementDetailStatus? status,
    GoalMovementAccounts? accounts,
    Failure? failure,
  }) =>
      GoalMovementDetailState(
        status: status ?? this.status,
        accounts: accounts ?? this.accounts,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, accounts, failure];
}
