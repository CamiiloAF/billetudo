import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../domain/entities/goal_with_progress.dart';

enum ArchivedGoalsStatus { loading, ready, failure }

/// HU-09: state for the "Metas archivadas" list.
class ArchivedGoalsState extends Equatable {
  const ArchivedGoalsState({
    this.status = ArchivedGoalsStatus.loading,
    this.goals = const [],
    this.accounts = const [],
    this.failure,
  });

  final ArchivedGoalsStatus status;
  final List<GoalWithProgress> goals;

  /// Every account, so each row (`G8lQvl`) can resolve its own linked
  /// account's name for "Ahorros Bancolombia · archivada el 5 ene" without
  /// the domain entity carrying denormalized account data.
  final List<AccountWithBalance> accounts;
  final Failure? failure;

  bool get isEmpty => status == ArchivedGoalsStatus.ready && goals.isEmpty;

  ArchivedGoalsState copyWith({
    ArchivedGoalsStatus? status,
    List<GoalWithProgress>? goals,
    List<AccountWithBalance>? accounts,
    Failure? failure,
  }) =>
      ArchivedGoalsState(
        status: status ?? this.status,
        goals: goals ?? this.goals,
        accounts: accounts ?? this.accounts,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, goals, accounts, failure];
}
