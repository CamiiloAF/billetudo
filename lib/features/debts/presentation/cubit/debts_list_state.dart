import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/debt_with_balance.dart';
import '../../domain/entities/debts_summary.dart';

/// The three states the debts list renders (frames `rPgbX`/`qfpUI`/`hp9rU`/
/// `d64hv`). `ready` splits into "with data" and "empty" through
/// [DebtsListState.isEmpty] — the difference is the content, not the load.
enum DebtsListStatus { loading, ready, failure }

/// The list's "Activas"/"Cerradas" tab (extension, HU-07, `vaNHd`). A
/// presentation-only filter over the one summary the cubit already streams —
/// closing a debt does not change *what* is fetched, only which half of it
/// this screen shows.
enum DebtsListTab { active, closed }

class DebtsListState extends Equatable {
  const DebtsListState({
    this.status = DebtsListStatus.loading,
    this.summary = DebtsSummary.empty,
    this.tab = DebtsListTab.active,
    this.failure,
  });

  final DebtsListStatus status;

  /// Active debts with their derived balances, plus one "Yo debo / Me deben"
  /// total per currency (never a cross-currency sum, HU-04).
  final DebtsSummary summary;

  /// The selected tab (extension, HU-07). Defaults to "Activas" on every
  /// fresh visit to the list.
  final DebtsListTab tab;

  final Failure? failure;

  bool get isLoading => status == DebtsListStatus.loading;

  /// The debts the current tab shows.
  List<DebtWithBalance> get tabDebts =>
      tab == DebtsListTab.active ? summary.openDebts : summary.closedDebts;

  /// Empty is only meaningful once loaded: no debts before that just means the
  /// first emission has not arrived. Scoped to the active tab — an empty
  /// "Cerradas" tab with debts still in "Activas" is not the same empty state
  /// as a brand new account with no debts at all.
  bool get isEmpty => status == DebtsListStatus.ready && tabDebts.isEmpty;

  DebtsListState copyWith({
    DebtsListStatus? status,
    DebtsSummary? summary,
    DebtsListTab? tab,
    Failure? failure,
  }) =>
      DebtsListState(
        status: status ?? this.status,
        summary: summary ?? this.summary,
        tab: tab ?? this.tab,
        // A new state carrying data is a state without an error: the caller
        // clears the failure by simply not passing one.
        failure: failure,
      );

  @override
  List<Object?> get props => [status, summary, tab, failure];
}
