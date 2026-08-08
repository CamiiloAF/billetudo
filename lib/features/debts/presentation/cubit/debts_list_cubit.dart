import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debts_summary.dart';
import '../../domain/usecases/accrue_interest.dart';
import '../../domain/usecases/watch_debts.dart';
import 'debts_list_state.dart';

/// Drives the debts list (HU-04) and its per-currency summary card.
///
/// Talks only to the `WatchDebts` use case, which already folds the
/// per-currency totals so the anti-cross-currency rule stays in the domain,
/// and to `AccrueInterest` (HU-06) so an auto-accrual debt's balance is
/// current the instant this list opens.
@injectable
class DebtsListCubit extends Cubit<DebtsListState> {
  DebtsListCubit(this._watchDebts, this._accrueInterest)
      : super(const DebtsListState());

  final WatchDebts _watchDebts;
  final AccrueInterest _accrueInterest;

  StreamSubscription<Result<DebtsSummary>>? _subscription;

  /// Re-entrancy guard: `true` while an `_accrueAutoDebts()` pass is in
  /// flight. Without it, a second `start()` (double tap on retry,
  /// pull-to-refresh) firing before the first pass finishes would read the
  /// same pre-write `lastAccrualDate`/balance for every open auto debt and
  /// post a duplicate `interestAccrual` row for each — this only guards
  /// re-entrancy *within this cubit*; the atomic transaction in
  /// `AccrueInterest`/`DebtRepositoryImpl.accrueInterestAtomic` is what
  /// guards a concurrent call from a different cubit instance (e.g.
  /// `DebtDetailCubit` open on the same debt).
  bool _accruing = false;

  /// Subscribes to the stream. Safe to call again to retry after an error.
  Future<void> start() async {
    await _subscription?.cancel();
    emit(const DebtsListState());
    if (!_accruing) {
      _accruing = true;
      try {
        await _accrueAutoDebts();
      } finally {
        _accruing = false;
      }
    }
    if (isClosed) {
      return;
    }
    _subscription = _watchDebts().listen(_onSummary);
  }

  /// Brings every auto-accrual, still-open debt's interest up to date
  /// (HU-06) before the list renders, so a debt the user has not opened in
  /// days already shows today's balance instead of a stale one. A one-shot
  /// peek at the stream's first emission, not a subscription — the `listen`
  /// above then simply sees whatever these writes changed on its own, since
  /// `watchDebts` is a reactive query. Manual-mode debts are filtered out
  /// here rather than left to `AccrueInterest`'s own guard, so this pass
  /// touches only the debts it actually needs to.
  Future<void> _accrueAutoDebts() async {
    Result<DebtsSummary>? result;
    try {
      result = await _watchDebts().first;
    } catch (_) {
      return;
    }
    final summary = result.fold((failure) => null, (summary) => summary);
    if (summary == null) {
      return;
    }
    final now = clock.now();
    for (final item in summary.openDebts) {
      if (item.debt.accrualMode != DebtAccrualMode.auto) {
        continue;
      }
      final accrualResult =
          await _accrueInterest(debtId: item.debt.id, upTo: now);
      accrualResult.fold(
        // A failed accrual is not fatal — the list still renders with
        // whatever balance is already persisted — but it must not be
        // silently swallowed, or a real bug here (e.g. a rejected write)
        // would go unnoticed.
        (failure) => debugPrint(
          'DebtsListCubit: AccrueInterest failed for debt '
          '${item.debt.id}: $failure',
        ),
        (_) {},
      );
    }
  }

  /// Switches the "Activas"/"Cerradas" tab (extension, HU-07). Local UI state
  /// only — the summary is already fully loaded, this just picks which half
  /// of it to render.
  void tabChanged(DebtsListTab tab) => emit(state.copyWith(tab: tab));

  void _onSummary(Result<DebtsSummary> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: DebtsListStatus.failure,
          failure: failure,
        ),
        (summary) => state.copyWith(
          status: DebtsListStatus.ready,
          summary: summary,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
