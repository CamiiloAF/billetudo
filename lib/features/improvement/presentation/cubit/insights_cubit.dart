import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/insight.dart';
import '../../domain/usecases/watch_insights.dart';
import 'insights_state.dart';

/// Drives the "Avisos" section of the notice centre.
///
/// Binds straight to [WatchInsights], which already filters by the user's
/// per-kind preferences, orders by usefulness and caps the volume. The cubit
/// adds only what is a presentation concern: the cards the user waved away in
/// this session.
@injectable
class InsightsCubit extends Cubit<InsightsState> {
  InsightsCubit(this._watchInsights) : super(const InsightsState());

  final WatchInsights _watchInsights;

  StreamSubscription<Result<List<Insight>>>? _subscription;

  /// Ids dismissed via "Recordar después"/"Todavía no".
  ///
  /// **In memory, on purpose.** These actions mean "not right now", not "never
  /// again": an insight stops being derived the moment its reason stops being
  /// true, so a charge still due tomorrow should come back tomorrow. Persisting
  /// the dismissal would need a store the domain deliberately does not have
  /// yet, and would silently turn "después" into "nunca".
  final Set<String> _dismissed = <String>{};

  List<Insight> _latest = const <Insight>[];

  Future<void> start() async {
    await _subscription?.cancel();
    _subscription = _watchInsights().listen((result) {
      if (isClosed) {
        return;
      }
      switch (result) {
        case Left():
          _latest = const <Insight>[];
          emit(
            const InsightsState(
              loading: false,
              failed: true,
            ),
          );
        case Right(value: final insights):
          _latest = insights;
          emit(
            InsightsState(
              insights: _visible(insights),
              loading: false,
            ),
          );
      }
    });
  }

  /// Hides [insight] for the rest of the session ("Recordar después").
  void dismiss(Insight insight) {
    _dismissed.add(insight.id);
    emit(state.copyWith(insights: _visible(_latest)));
  }

  List<Insight> _visible(List<Insight> insights) => [
        for (final insight in insights)
          if (!_dismissed.contains(insight.id)) insight,
      ];

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
