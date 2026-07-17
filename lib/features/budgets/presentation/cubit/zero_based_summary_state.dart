import 'package:equatable/equatable.dart';

import '../../domain/entities/zero_based_summary.dart';

/// State of the "Modo sobres" hero (HU-06). [summary] is `null` until the first
/// value arrives, or whenever there is nothing to show (no active budget and no
/// income this month).
class ZeroBasedSummaryState extends Equatable {
  const ZeroBasedSummaryState({this.summary});

  final ZeroBasedSummary? summary;

  ZeroBasedSummaryState copyWith({ZeroBasedSummary? summary}) =>
      ZeroBasedSummaryState(summary: summary);

  @override
  List<Object?> get props => [summary];
}
