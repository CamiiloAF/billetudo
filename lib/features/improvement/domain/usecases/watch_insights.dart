import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/notifications/domain/repositories/notification_preferences.dart';
import '../entities/insight.dart';
import '../entities/insight_thresholds.dart';
import 'watch_goal_milestone_insights.dart';
import 'watch_pending_confirmation_insights.dart';
import 'watch_upcoming_charge_insights.dart';

/// The notification center's feed: every locally-derived terminal insight,
/// filtered by the user's per-type preferences and capped in volume.
///
/// Exposed as a stream so the (not yet built) centro de avisos can bind to it
/// directly and expire items on its own — an insight stops being derived the
/// moment its reason stops being true, which is the whole advantage this
/// surface has over a permanent card in Inicio.
///
/// Ordering is by usefulness, not by recency: what needs an action first
/// (pending confirmations), then what is about to happen (upcoming charges),
/// then what is worth celebrating (milestones).
@injectable
class WatchInsights {
  const WatchInsights(
    this._upcomingCharges,
    this._pendingConfirmations,
    this._goalMilestones,
    this._preferences,
  );

  final WatchUpcomingChargeInsights _upcomingCharges;
  final WatchPendingConfirmationInsights _pendingConfirmations;
  final WatchGoalMilestoneInsights _goalMilestones;
  final NotificationPreferences _preferences;

  static const Map<InsightType, int> _priority = <InsightType, int>{
    InsightType.pendingConfirmation: 0,
    InsightType.upcomingCharge: 1,
    InsightType.goalMilestone: 2,
  };

  Stream<Result<List<Insight>>> call() {
    final combined = _combineLatest([
      _pendingConfirmations(),
      _upcomingCharges(),
      _goalMilestones(),
    ]);
    return combined.asyncMap((result) async {
      if (result case Left(value: final failure)) {
        return Left<Failure, List<Insight>>(failure);
      }
      final all = result.getOrElse((_) => const <Insight>[]);
      final enabled = await _preferences.readAll();
      final visible = [
        for (final insight in all)
          if (enabled[insight.type.notificationKind] ?? true) insight,
      ]..sort(_byUsefulness);
      // The frequency cap. Whatever does not fit is not lost — it is simply
      // not worth the attention right now, and it will still be there (or
      // gone) next time.
      return Right<Failure, List<Insight>>(
        visible.take(InsightThresholds.maxInsights).toList(),
      );
    });
  }

  int _byUsefulness(Insight a, Insight b) {
    final byType = (_priority[a.type] ?? 99).compareTo(_priority[b.type] ?? 99);
    if (byType != 0) {
      return byType;
    }
    return a.relevantOn.compareTo(b.relevantOn);
  }

  /// Minimal combineLatest over N insight sources — the project has no
  /// rxdart dependency, same hand-rolled pattern as `WatchHomeAiInsight`.
  /// Emits once every source has produced a value, then on every subsequent
  /// emission; a `Left` from any source short-circuits the whole feed, since
  /// a partial list would silently hide insights.
  Stream<Result<List<Insight>>> _combineLatest(
    List<Stream<Result<List<Insight>>>> sources,
  ) {
    late final StreamController<Result<List<Insight>>> controller;
    final subscriptions = <StreamSubscription<Result<List<Insight>>>>[];
    final latest = List<Result<List<Insight>>?>.filled(sources.length, null);
    var openSources = sources.length;

    void emit() {
      if (latest.any((value) => value == null)) {
        return;
      }
      final merged = <Insight>[];
      for (final value in latest) {
        if (value! case Left(value: final failure)) {
          controller.add(Left(failure));
          return;
        }
        merged.addAll(value.getOrElse((_) => const <Insight>[]));
      }
      controller.add(Right(merged));
    }

    controller = StreamController<Result<List<Insight>>>.broadcast(
      onListen: () {
        for (var i = 0; i < sources.length; i++) {
          final index = i;
          subscriptions.add(
            sources[index].listen(
              (event) {
                latest[index] = event;
                emit();
              },
              onError: controller.addError,
              onDone: () {
                openSources--;
                if (openSources == 0) {
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
        subscriptions.clear();
      },
    );

    return controller.stream;
  }
}
