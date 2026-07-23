import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/debts_summary.dart';

/// The three states the debts list renders (frames `rPgbX`/`qfpUI`/`hp9rU`/
/// `d64hv`). `ready` splits into "with data" and "empty" through
/// [DebtsListState.isEmpty] — the difference is the content, not the load.
enum DebtsListStatus { loading, ready, failure }

class DebtsListState extends Equatable {
  const DebtsListState({
    this.status = DebtsListStatus.loading,
    this.summary = DebtsSummary.empty,
    this.failure,
  });

  final DebtsListStatus status;

  /// Active debts with their derived balances, plus one "Yo debo / Me deben"
  /// total per currency (never a cross-currency sum, HU-04).
  final DebtsSummary summary;

  final Failure? failure;

  bool get isLoading => status == DebtsListStatus.loading;

  /// Empty is only meaningful once loaded: no debts before that just means the
  /// first emission has not arrived.
  bool get isEmpty =>
      status == DebtsListStatus.ready && summary.debts.isEmpty;

  DebtsListState copyWith({
    DebtsListStatus? status,
    DebtsSummary? summary,
    Failure? failure,
  }) =>
      DebtsListState(
        status: status ?? this.status,
        summary: summary ?? this.summary,
        // A new state carrying data is a state without an error: the caller
        // clears the failure by simply not passing one.
        failure: failure,
      );

  @override
  List<Object?> get props => [status, summary, failure];
}
