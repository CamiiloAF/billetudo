import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/result.dart';
import '../../../accounts/data/models/account_mapper.dart';
import '../../../accounts/domain/entities/account_balance.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_contribution.dart';
import '../../domain/entities/goal_contribution_draft.dart';
import '../../domain/entities/goal_detail.dart';
import '../../domain/entities/goal_draft.dart';
import '../../domain/entities/goal_with_progress.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/services/goal_coherence_calculator.dart';
import '../../domain/services/goal_milestone_tracker.dart';
import '../../domain/services/goal_momentum_calculator.dart';
import '../../domain/services/goal_progress_calculator.dart';
import '../../domain/services/goal_projection_calculator.dart';
import '../datasources/goals_local_datasource.dart';
import '../models/goal_contribution_mapper.dart';
import '../models/goal_mapper.dart';

/// Drift implementation of [GoalRepository].
///
/// Owns the cross-cutting rules that `updatedAt` is stamped on every write,
/// that `savedMinor` is never stored (always derived by
/// [GoalProgressCalculator]), and that a goal's `completedAt`/
/// `lastMilestonePct` are reconciled here — the single place that both
/// writes a movement AND recomputes the goal's business state against it, so
/// the two can never drift apart.
@LazySingleton(as: GoalRepository)
class GoalRepositoryImpl implements GoalRepository {
  const GoalRepositoryImpl(
    this._local,
    this._progressCalculator,
    this._milestoneTracker,
    this._projectionCalculator,
    this._momentumCalculator,
    this._coherenceCalculator,
    this._crash,
  );

  final GoalsLocalDatasource _local;
  final GoalProgressCalculator _progressCalculator;
  final GoalMilestoneTracker _milestoneTracker;
  final GoalProjectionCalculator _projectionCalculator;
  final GoalMomentumCalculator _momentumCalculator;
  final GoalCoherenceCalculator _coherenceCalculator;
  final CrashReporter _crash;

  @override
  Stream<Result<List<GoalWithProgress>>> watchGoals() => _guardStream(
        _combineLatest<Result<List<GoalWithProgress>>>(
          [_local.watchActiveGoals(), _local.watchActiveContributions()],
          (values) {
            final goals = values[0]! as List<db.Goal>;
            final contributions = values[1]! as List<db.GoalContribution>;
            final byGoal = _groupContributions(contributions);
            final withProgress = goals.map((row) {
              final goal = GoalMapper.toEntity(row);
              return _progressCalculator.calculate(
                goal: goal,
                contributions: byGoal[goal.id] ?? const [],
              );
            }).toList();
            return Right<Failure, List<GoalWithProgress>>(withProgress);
          },
        ).asyncMap((result) async {
          if (result case Left(value: final failure)) {
            return Left<Failure, List<GoalWithProgress>>(failure);
          }
          final list = result.getOrElse((_) => const []);
          final signals = await _coherenceSignals(list);
          return Right<Failure, List<GoalWithProgress>>(
            list
                .map(
                  (g) => g.goal.accountId == null
                      ? g
                      : g.copyWith(coherence: signals[g.goal.accountId]),
                )
                .toList(),
          );
        }),
      );

  @override
  Stream<Result<List<GoalWithProgress>>> watchArchivedGoals() => _guardStream(
        _combineLatest<Result<List<GoalWithProgress>>>(
          [_local.watchArchivedGoals(), _local.watchActiveContributions()],
          (values) {
            final goals = values[0]! as List<db.Goal>;
            final contributions = values[1]! as List<db.GoalContribution>;
            final byGoal = _groupContributions(contributions);
            final withProgress = goals.map((row) {
              final goal = GoalMapper.toEntity(row);
              return _progressCalculator.calculate(
                goal: goal,
                contributions: byGoal[goal.id] ?? const [],
              );
            }).toList();
            // HU-12: coherence is never computed for archived goals.
            return Right<Failure, List<GoalWithProgress>>(withProgress);
          },
        ),
      );

  @override
  Stream<Result<GoalDetail>> watchGoalDetail(String goalId) => _guardStream(
        _combineLatest<Result<GoalDetail>>(
          [_local.watchGoal(goalId), _local.watchContributions(goalId)],
          (values) {
            final goalRow = values[0] as db.Goal?;
            if (goalRow == null) {
              return Left<Failure, GoalDetail>(
                NotFoundFailure('goal "$goalId" does not exist'),
              );
            }
            final contributions = (values[1]! as List<db.GoalContribution>)
                .map(GoalContributionMapper.toEntity)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
            final goal = GoalMapper.toEntity(goalRow);
            final progress = _progressCalculator.calculate(
              goal: goal,
              contributions: contributions,
            );
            final projection = _projectionCalculator.calculate(
              goal: goal,
              contributions: contributions,
              savedMinor: progress.savedMinor,
            );
            final momentum = _momentumCalculator.calculate(
              goal: goal,
              contributions: contributions,
              savedMinor: progress.savedMinor,
            );
            return Right<Failure, GoalDetail>(
              GoalDetail(
                progress: progress,
                projection: projection,
                momentum: momentum,
                history: contributions,
              ),
            );
          },
        ).asyncMap((result) async {
          if (result case Left(value: final failure)) {
            return Left<Failure, GoalDetail>(failure);
          }
          final detail = result.getOrElse((_) => throw StateError('unreachable'));
          final coherence = await _coherenceForGoal(detail.progress.goal);
          if (coherence == null) {
            return Right<Failure, GoalDetail>(detail);
          }
          return Right<Failure, GoalDetail>(
            GoalDetail(
              progress: detail.progress.copyWith(coherence: coherence),
              projection: detail.projection,
              momentum: detail.momentum,
              history: detail.history,
            ),
          );
        }),
      );

  @override
  FutureResult<Goal> getGoal(String id) => _guard(() async {
        final row = await _local.getGoal(id);
        if (row == null) {
          return Left(NotFoundFailure('goal "$id" does not exist'));
        }
        return Right(GoalMapper.toEntity(row));
      });

  @override
  FutureResult<int> getSavedMinor(String goalId) => _guard(() async {
        final contributions = (await _local.getContributions(goalId))
            .map(GoalContributionMapper.toEntity)
            .toList();
        return Right(_progressCalculator.deriveSavedMinor(contributions));
      });

  @override
  FutureResult<bool> hasContributions(String goalId) => _guard(() async {
        final contributions = await _local.getContributions(goalId);
        return Right(contributions.isNotEmpty);
      });

  @override
  FutureResult<Goal> createGoal(GoalDraft draft) => _guard(() async {
        final now = DateTime.now();
        final goalCompanion = GoalMapper.toInsertCompanion(draft, now: now);
        final initialAmount = draft.initialSavedMinor;
        final initialContribution = (initialAmount == null || initialAmount <= 0)
            ? null
            : db.GoalContributionsCompanion.insert(
                // Overwritten with the real id by the datasource once the
                // goal is inserted, in the same atomic write.
                goalId: '',
                amountMinor: initialAmount,
                direction: db.GoalMovementDirection.contribution,
                date: now,
                createdAt: Value(now),
                updatedAt: Value(now.millisecondsSinceEpoch),
              );
        final row = await _local.insertGoalWithInitialContribution(
          goalCompanion: goalCompanion,
          initialContribution: initialContribution,
        );
        var goal = GoalMapper.toEntity(row);

        if (initialContribution != null) {
          // HU-06/HU-07: a declared starting progress can itself already
          // reach a milestone or complete the goal on day one.
          await _reconcileProgressState(
            goal: goal,
            savedMinor: initialAmount!,
            now: now,
          );
          final refreshed = await _local.getGoal(goal.id);
          if (refreshed != null) {
            goal = GoalMapper.toEntity(refreshed);
          }
        }

        return Right(goal);
      });

  @override
  FutureResult<Goal> updateGoal(GoalDraft draft) => _guard(() async {
        final id = draft.id;
        if (id == null) {
          return const Left(
            ValidationFailure(
              'cannot update a goal without an id',
              field: GoalDraft.fieldId,
            ),
          );
        }
        final existingRow = await _local.getGoal(id);
        if (existingRow == null) {
          return Left(NotFoundFailure('goal "$id" does not exist'));
        }
        final existing = GoalMapper.toEntity(existingRow);
        final now = DateTime.now();

        final updatedRow = await _local.updateGoal(
          id,
          GoalMapper.toUpdateCompanion(draft, now: now),
        );
        if (updatedRow == null) {
          return Left(NotFoundFailure('goal "$id" does not exist'));
        }
        var updated = GoalMapper.toEntity(updatedRow);

        final contributions = (await _local.getContributions(id))
            .map(GoalContributionMapper.toEntity)
            .toList();
        final savedMinor = _progressCalculator.deriveSavedMinor(contributions);

        // HU-07: raising `targetMinor` above `savedMinor` is the ONLY thing
        // that clears a completed goal; a withdrawal never does. Lowering it
        // below `savedMinor` (or simply reaching it here) marks completion.
        DateTime? completedAt = updated.completedAt;
        final raisedTarget = draft.targetMinor > existing.targetMinor;
        if (completedAt != null && raisedTarget && savedMinor < updated.targetMinor) {
          completedAt = null;
        } else if (completedAt == null && savedMinor >= updated.targetMinor) {
          completedAt = now;
        }

        final rawPercent = updated.targetMinor <= 0
            ? 0
            : (savedMinor * 100) / updated.targetMinor;
        final lastMilestonePct = _milestoneTracker.reconcileAfterTargetChange(
          currentLastMilestonePct: updated.lastMilestonePct,
          newRawPercent: rawPercent,
        );

        if (completedAt != updated.completedAt ||
            lastMilestonePct != updated.lastMilestonePct) {
          final reconciled = await _local.updateGoal(
            id,
            GoalMapper.progressStateCompanion(
              completedAt: completedAt,
              lastMilestonePct: lastMilestonePct,
              now: now,
            ),
          );
          if (reconciled != null) {
            updated = GoalMapper.toEntity(reconciled);
          }
        }

        return Right(updated);
      });

  @override
  FutureResult<Unit> archiveGoal(String id) => _setArchivedAt(id, DateTime.now());

  @override
  FutureResult<Unit> unarchiveGoal(String id) => _setArchivedAt(id, null);

  FutureResult<Unit> _setArchivedAt(String id, DateTime? archivedAt) =>
      _guard(() async {
        final now = DateTime.now();
        final row = await _local.updateGoal(
          id,
          GoalMapper.archiveCompanion(archivedAt: archivedAt, now: now),
        );
        if (row == null) {
          return Left(NotFoundFailure('goal "$id" does not exist'));
        }
        return const Right(unit);
      });

  @override
  FutureResult<Unit> deleteGoal(String id) => _guard(() async {
        final now = DateTime.now();
        final row = await _local.updateGoal(
          id,
          GoalMapper.softDeleteCompanion(now: now),
        );
        if (row == null) {
          return Left(NotFoundFailure('goal "$id" does not exist'));
        }
        await _local.setContributionsDeletedAt(
          id,
          deletedAt: now,
          updatedAt: now.millisecondsSinceEpoch,
        );
        return const Right(unit);
      });

  @override
  FutureResult<Unit> restoreGoal(String id) => _guard(() async {
        final now = DateTime.now();
        final row = await _local.restoreGoal(
          id,
          GoalMapper.restoreCompanion(now: now),
        );
        if (row == null) {
          return Left(NotFoundFailure('goal "$id" does not exist'));
        }
        await _local.setContributionsDeletedAt(
          id,
          deletedAt: null,
          updatedAt: now.millisecondsSinceEpoch,
        );
        return const Right(unit);
      });

  @override
  FutureResult<Unit> purgeGoal(String id) => _guard(() async {
        final now = DateTime.now();
        final row = await _local.tombstoneGoal(
          id,
          GoalMapper.tombstoneCompanion(now: now),
        );
        if (row == null) {
          return Left(NotFoundFailure('goal "$id" does not exist'));
        }
        await _local.setContributionsTombstonedAt(
          id,
          tombstonedAt: now,
          updatedAt: now.millisecondsSinceEpoch,
        );
        return const Right(unit);
      });

  @override
  FutureResult<(GoalContribution, int?)> contribute(
    GoalContributionDraft draft,
  ) =>
      _writeMovement(draft);

  @override
  FutureResult<(GoalContribution, int?)> withdraw(
    GoalContributionDraft draft,
  ) =>
      _writeMovement(draft);

  FutureResult<(GoalContribution, int?)> _writeMovement(
    GoalContributionDraft draft,
  ) =>
      _guard(() async {
        final goalRow = await _local.getGoal(draft.goalId);
        if (goalRow == null) {
          return Left(NotFoundFailure('goal "${draft.goalId}" does not exist'));
        }
        final goal = GoalMapper.toEntity(goalRow);
        final now = DateTime.now();

        db.GoalContribution contributionRow;
        if (draft.moveMoney) {
          final (_, contribution) = await _local.insertMovementWithTransfer(
            transactionCompanion: db.TransactionsCompanion.insert(
              accountId: draft.originAccountId!,
              transferAccountId: Value(draft.destinationAccountId),
              categoryId: Value(draft.categoryId),
              amountMinor: draft.amountMinor,
              currency: draft.currency,
              type: db.EntryType.transfer,
              date: draft.date,
              note: Value(draft.note),
              source: const Value(db.TxSource.manual),
              goalId: Value(draft.goalId),
              countsInBudget: Value(draft.countsInBudget),
              createdAt: Value(now),
              updatedAt: Value(now.millisecondsSinceEpoch),
            ),
            contributionCompanionBuilder: (transactionId) =>
                GoalContributionMapper.toInsertCompanion(
              draft,
              now: now,
              transactionId: transactionId,
            ),
          );
          contributionRow = contribution;
        } else {
          contributionRow = await _local.insertContribution(
            GoalContributionMapper.toInsertCompanion(draft, now: now),
          );
        }

        final savedMinor = await _savedMinorOf(draft.goalId);
        final crossedMilestonePct = await _reconcileProgressState(
          goal: goal,
          savedMinor: savedMinor,
          now: now,
        );

        return Right((
          GoalContributionMapper.toEntity(contributionRow),
          crossedMilestonePct,
        ));
      });

  @override
  FutureResult<GoalContribution> linkExistingTransaction({
    required String goalId,
    required String transactionId,
    required GoalMovementDirection direction,
    String? note,
  }) =>
      _guard(() async {
        final goalRow = await _local.getGoal(goalId);
        if (goalRow == null) {
          return Left(NotFoundFailure('goal "$goalId" does not exist'));
        }
        final transactionRow = await _local.getTransaction(transactionId);
        if (transactionRow == null) {
          return Left(
            NotFoundFailure('transaction "$transactionId" does not exist'),
          );
        }
        final now = DateTime.now();
        final row = await _local.insertContribution(
          GoalContributionMapper.toLinkedInsertCompanion(
            goalId: goalId,
            amountMinor: transactionRow.amountMinor,
            direction: direction,
            date: transactionRow.date,
            now: now,
            transactionId: transactionId,
            note: note,
          ),
        );

        final goal = GoalMapper.toEntity(goalRow);
        final savedMinor = await _savedMinorOf(goalId);
        await _reconcileProgressState(goal: goal, savedMinor: savedMinor, now: now);

        return Right(GoalContributionMapper.toEntity(row));
      });

  @override
  FutureResult<Unit> syncContributionForTransactionAmount({
    required String transactionId,
    required int amountMinor,
  }) =>
      _guard(() async {
        final contributionRow = await _local.getContributionByTransaction(
          transactionId,
        );
        if (contributionRow == null) {
          return const Right(unit);
        }
        final now = DateTime.now();
        await _local.updateContributionAmountForTransaction(
          transactionId: transactionId,
          amountMinor: amountMinor,
          updatedAt: now.millisecondsSinceEpoch,
        );
        await _reconcileAfterExternalMovementChange(
          contributionRow.goalId,
          now: now,
        );
        return const Right(unit);
      });

  @override
  FutureResult<Unit> removeContributionForTransaction(String transactionId) =>
      _guard(() async {
        final contributionRow = await _local.getContributionByTransaction(
          transactionId,
        );
        if (contributionRow == null) {
          return const Right(unit);
        }
        await _local.deleteContributionForTransaction(transactionId);
        await _reconcileAfterExternalMovementChange(
          contributionRow.goalId,
          now: DateTime.now(),
        );
        return const Right(unit);
      });

  Future<void> _reconcileAfterExternalMovementChange(
    String goalId, {
    required DateTime now,
  }) async {
    final goalRow = await _local.getGoal(goalId);
    if (goalRow == null) {
      return;
    }
    final goal = GoalMapper.toEntity(goalRow);
    final savedMinor = await _savedMinorOf(goalId);
    await _reconcileProgressState(goal: goal, savedMinor: savedMinor, now: now);
  }

  Future<int> _savedMinorOf(String goalId) async {
    final contributions = (await _local.getContributions(goalId))
        .map(GoalContributionMapper.toEntity)
        .toList();
    return _progressCalculator.deriveSavedMinor(contributions);
  }

  /// HU-06/HU-07: after any movement, recompute the goal's `completedAt`/
  /// `lastMilestonePct` against the new derived `savedMinor` and persist them
  /// if they changed. A movement only ever moves these FORWARD (marks
  /// complete, celebrates a new milestone) — it never clears `completedAt`;
  /// only `UpdateGoal` (raising `targetMinor`) can do that (HU-07).
  Future<int?> _reconcileProgressState({
    required Goal goal,
    required int savedMinor,
    required DateTime now,
  }) async {
    final rawPercent =
        goal.targetMinor <= 0 ? 0 : (savedMinor * 100) / goal.targetMinor;
    final milestoneOutcome = _milestoneTracker.evaluate(
      previousLastMilestonePct: goal.lastMilestonePct,
      newRawPercent: rawPercent,
    );

    var completedAt = goal.completedAt;
    if (completedAt == null && savedMinor >= goal.targetMinor) {
      completedAt = now;
    }

    if (completedAt != goal.completedAt ||
        milestoneOutcome.lastMilestonePct != goal.lastMilestonePct) {
      await _local.updateGoal(
        goal.id,
        GoalMapper.progressStateCompanion(
          completedAt: completedAt,
          lastMilestonePct: milestoneOutcome.lastMilestonePct,
          now: now,
        ),
      );
    }
    return milestoneOutcome.crossedMilestonePct;
  }

  /// HU-12: the coherence signal (if any) for the account [goal] is linked
  /// to, computed against every other active goal sharing that account.
  /// `null` for an archived goal or one with no linked account.
  Future<GoalCoherenceSignal?> _coherenceForGoal(Goal goal) async {
    if (goal.isArchived || goal.accountId == null) {
      return null;
    }
    final activeRows = await _local.getActiveGoals();
    final activeWithProgress = <GoalWithProgress>[];
    for (final row in activeRows) {
      final entity = GoalMapper.toEntity(row);
      final contributions = (await _local.getContributions(entity.id))
          .map(GoalContributionMapper.toEntity)
          .toList();
      activeWithProgress.add(
        _progressCalculator.calculate(goal: entity, contributions: contributions),
      );
    }
    final signals = await _coherenceSignals(activeWithProgress);
    return signals[goal.accountId];
  }

  /// Builds every account's coherence signal from an already-active list of
  /// [GoalWithProgress] (HU-12: archived/trashed goals must never reach here
  /// — both callers only ever pass active ones).
  Future<Map<String, GoalCoherenceSignal>> _coherenceSignals(
    List<GoalWithProgress> activeGoals,
  ) async {
    final facts = <GoalAccountFact>[];
    final balanceCache = <String, (int, String)>{};

    for (final goalWithProgress in activeGoals) {
      final accountId = goalWithProgress.goal.accountId;
      if (accountId == null) {
        continue;
      }
      var cached = balanceCache[accountId];
      if (cached == null) {
        final accountRow = await _local.getAccount(accountId);
        if (accountRow == null) {
          continue;
        }
        final movements = await _local.getAccountMovements(accountId);
        final balance = AccountBalance.fromMovements(
          account: AccountMapper.toEntity(accountRow),
          movements:
              movements.map((m) => AccountMapper.toMovement(m, accountId)),
        );
        cached = (balance.balanceMinor, accountRow.currency);
        balanceCache[accountId] = cached;
      }
      facts.add(
        GoalAccountFact(
          goal: goalWithProgress,
          accountBalanceMinor: cached.$1,
          accountCurrency: cached.$2,
        ),
      );
    }

    return _coherenceCalculator.calculate(facts);
  }

  Map<String, List<GoalContribution>> _groupContributions(
    List<db.GoalContribution> rows,
  ) {
    final byGoal = <String, List<GoalContribution>>{};
    for (final row in rows) {
      (byGoal[row.goalId] ??= []).add(GoalContributionMapper.toEntity(row));
    }
    return byGoal;
  }

  /// Turns any infrastructure exception into a `Failure`, so nothing escapes
  /// the data layer as a raw exception.
  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'goals query');
      return Left(
        DatabaseFailure('goals query failed', cause: e, stackTrace: st),
      );
    }
  }

  /// Same for streams: a query error becomes a `Left` **emission** instead of
  /// a stream error, so the cubit can render the error state without the
  /// subscription dying.
  Stream<Result<T>> _guardStream<T>(Stream<Result<T>> source) =>
      source.transform(
        StreamTransformer<Result<T>, Result<T>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) {
            unawaited(
              _crash.recordError(error, stackTrace, context: 'goals stream'),
            );
            sink.add(
              Left(
                DatabaseFailure(
                  'goals stream failed',
                  cause: error,
                  stackTrace: stackTrace,
                ),
              ),
            );
          },
        ),
      );

  /// Hand-rolled `combineLatest` (no rxdart dependency), same helper as
  /// `DebtRepositoryImpl`/`BudgetRepositoryImpl`.
  Stream<R> _combineLatest<R>(
    List<Stream<Object?>> streams,
    R Function(List<Object?>) combine,
  ) {
    final latest = List<Object?>.filled(streams.length, null);
    final seen = List<bool>.filled(streams.length, false);
    final subscriptions = <StreamSubscription<Object?>>[];
    late final StreamController<R> controller;
    var open = streams.length;

    controller = StreamController<R>(
      onListen: () {
        for (var i = 0; i < streams.length; i++) {
          final index = i;
          subscriptions.add(
            streams[index].listen(
              (value) {
                latest[index] = value;
                seen[index] = true;
                if (seen.every((element) => element)) {
                  controller.add(combine(List<Object?>.of(latest)));
                }
              },
              onError: controller.addError,
              onDone: () {
                open--;
                if (open == 0) {
                  unawaited(controller.close());
                }
              },
            ),
          );
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );

    return controller.stream;
  }
}
