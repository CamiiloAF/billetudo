import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_balance.dart';
import '../../domain/entities/debt_detail.dart';
import '../../domain/services/debt_interest_calculator.dart';
import '../../domain/usecases/watch_debt_detail.dart';
import 'debt_detail_state.dart';

/// Drives one debt's detail (HU-04): the hero, the meta card's estimated daily
/// growth, and the running-balance ledger.
///
/// The running balance and the daily-growth figure are derived here from the
/// domain's already-signed effects and its own interest calculator — the cubit
/// re-derives no sign and does no money rounding of its own.
@injectable
class DebtDetailCubit extends Cubit<DebtDetailState> {
  DebtDetailCubit(this._watchDebtDetail, this._interestCalculator)
      : super(const DebtDetailState());

  final WatchDebtDetail _watchDebtDetail;
  final DebtInterestCalculator _interestCalculator;

  StreamSubscription<Result<DebtDetail>>? _subscription;
  String? _debtId;

  /// Subscribes to the debt's detail stream. Safe to call again to retry.
  Future<void> start(String debtId) async {
    _debtId = debtId;
    await _subscription?.cancel();
    emit(const DebtDetailState());
    _subscription = _watchDebtDetail(debtId).listen(_onDetail);
  }

  /// Retries the last load after a failure. The debt id lives in the route, not
  /// the state, so the cubit remembers it here for the error screen's retry.
  Future<void> retry() async {
    final id = _debtId;
    if (id != null) {
      await start(id);
    }
  }

  void _onDetail(Result<DebtDetail> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: DebtDetailStatus.failure,
          failure: failure,
        ),
        (detail) => state.copyWith(
          status: DebtDetailStatus.ready,
          detail: detail,
          runningBalances: _runningBalances(detail),
          dailyGrowthMinor: _dailyGrowth(detail.debt, detail.balance),
        ),
      ),
    );
  }

  /// The balance after each newest-first row: the newest row sits at the
  /// current raw outstanding, and each older row is that minus the newer rows'
  /// effects. Clamped to 0 for display, matching the outstanding rule.
  List<int> _runningBalances(DebtDetail detail) {
    final running = <int>[];
    var carry = detail.balance.rawOutstandingMinor;
    for (final entry in detail.ledger) {
      running.add(carry < 0 ? 0 : carry);
      carry -= entry.effectMinor;
    }
    return running;
  }

  /// The estimated interest one more day adds, shown only for a debt that
  /// grows automatically at a positive rate over a positive balance.
  int? _dailyGrowth(Debt debt, DebtBalance balance) {
    if (debt.accrualMode != DebtAccrualMode.auto) {
      return null;
    }
    final rate = debt.interestRateBps;
    if (rate == null || rate <= 0 || balance.outstandingMinor <= 0) {
      return null;
    }
    final growth = _interestCalculator.accruedInterestMinor(
      balanceMinor: balance.outstandingMinor,
      rateBps: rate,
      days: 1,
    );
    return growth > 0 ? growth : null;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
