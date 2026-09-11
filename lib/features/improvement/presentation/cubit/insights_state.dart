import 'package:equatable/equatable.dart';

import '../../domain/entities/insight.dart';

/// State of the notice centre's "Avisos" section.
class InsightsState extends Equatable {
  const InsightsState({
    this.insights = const <Insight>[],
    this.loading = true,
    this.failed = false,
  });

  /// Already filtered by the per-kind preferences, capped and ordered by
  /// usefulness — `WatchInsights` owns all of that.
  final List<Insight> insights;

  final bool loading;

  /// A read of the local data failed. The section renders nothing rather than
  /// an error: this surface is a courtesy over data the user can reach by
  /// other means, so it never becomes the thing that breaks a screen.
  final bool failed;

  bool get isEmpty => !loading && insights.isEmpty;

  InsightsState copyWith({
    List<Insight>? insights,
    bool? loading,
    bool? failed,
  }) =>
      InsightsState(
        insights: insights ?? this.insights,
        loading: loading ?? this.loading,
        failed: failed ?? this.failed,
      );

  @override
  List<Object?> get props => [insights, loading, failed];
}
