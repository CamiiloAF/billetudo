import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_balance.dart';
import '../../domain/entities/debt_detail.dart';
import '../../domain/services/debt_interest_calculator.dart';
import '../../domain/usecases/close_debt.dart';
import '../../domain/usecases/delete_debt.dart';
import '../../domain/usecases/watch_debt_detail.dart';
import 'debt_detail_state.dart';

/// Drives one debt's detail (HU-04): the hero, the meta card's estimated daily
/// growth, and the running-balance ledger. Also owns the overflow menu's two
/// direct actions (extension, HU-07) — "Cerrar deuda" and "Eliminar deuda" —
/// and the felicitación sheet's trigger.
///
/// The running balance and the daily-growth figure are derived here from the
/// domain's already-signed effects and its own interest calculator — the cubit
/// re-derives no sign and does no money rounding of its own.
@injectable
class DebtDetailCubit extends Cubit<DebtDetailState> {
  DebtDetailCubit(
    this._watchDebtDetail,
    this._interestCalculator,
    this._closeDebt,
    this._deleteDebt,
  ) : super(const DebtDetailState());

  final WatchDebtDetail _watchDebtDetail;
  final DebtInterestCalculator _interestCalculator;
  final CloseDebt _closeDebt;
  final DeleteDebt _deleteDebt;

  StreamSubscription<Result<DebtDetail>>? _subscription;
  String? _debtId;

  /// The previous ready emission's settled flag, to detect the exact moment
  /// the balance *crosses* to settled (extension, HU-07) rather than firing
  /// the felicitación sheet every time an already-settled debt is reopened.
  /// `null` until the first ready emission, so loading an already-settled
  /// debt never celebrates on arrival.
  bool? _wasSettled;

  /// Subscribes to the debt's detail stream. Safe to call again to retry.
  Future<void> start(String debtId) async {
    _debtId = debtId;
    _wasSettled = null;
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
          installment: _installmentView(detail),
          celebration: () => _celebrationFor(detail),
        ),
      ),
    );
  }

  /// Reveals one more page of the ledger, following
  /// `BudgetDetailCubit.loadMoreActivity()`'s exact pattern.
  void loadMoreLedger() => emit(
        state.copyWith(
          visibleLedgerCount:
              state.visibleLedgerCount + DebtDetailState.ledgerPageSize,
        ),
      );

  /// Extension (HU-07): manually closes the debt from any of its three call
  /// sites (the fixed CTA, the overflow menu's "Cerrar deuda"/"Completar
  /// deuda", or the felicitación sheet's "Completar" button). The detail
  /// stream reflects the new `closedAt` on its own; a failure only surfaces
  /// via [DebtDetailState.actionFailure], and a success fires
  /// [DebtDetailState.closeSuccess] once so the page can snackbar it
  /// regardless of which call site triggered it.
  Future<void> closeDebt() async {
    final id = _debtId;
    if (id == null) {
      return;
    }
    final result = await _closeDebt(id);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(actionFailure: () => failure)),
      (_) => emit(
        state.copyWith(closeSuccess: () => const DebtCloseSuccess()),
      ),
    );
  }

  /// The overflow menu's direct "Eliminar deuda" (extension, HU-07) — the
  /// same reversible papelera delete HU-05 already has in the form, just
  /// reachable without navigating there first. On success the page pops via
  /// `status == deleted`.
  Future<void> delete() async {
    final id = _debtId;
    if (id == null) {
      return;
    }
    final result = await _deleteDebt(id);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(state.copyWith(actionFailure: () => failure)),
      (_) => emit(state.copyWith(status: DebtDetailStatus.deleted)),
    );
  }

  /// Clears a consumed [DebtDetailState.actionFailure] after its snackbar
  /// shows, so the same failure cannot re-trigger on an unrelated rebuild.
  void dismissActionFailure() =>
      emit(state.copyWith(actionFailure: () => null));

  /// Clears a consumed [DebtDetailState.closeSuccess] after its snackbar
  /// shows, so it cannot re-trigger on an unrelated rebuild.
  void dismissCloseSuccess() =>
      emit(state.copyWith(closeSuccess: () => null));

  /// Clears a consumed [DebtDetailState.celebration] once the page has opened
  /// its sheet, so navigating back to an already-settled-but-not-closed debt
  /// does not reopen it.
  void dismissCelebration() => emit(state.copyWith(celebration: () => null));

  /// Builds the felicitación payload the instant [detail]'s balance crosses
  /// from not-settled to settled — `null` on every other emission (already
  /// settled on arrival, still not settled, or already closed: closing a debt
  /// with `Completar` should not immediately re-trigger the same sheet).
  DebtSettledCelebration? _celebrationFor(DebtDetail detail) {
    final settledNow = detail.balance.settled;
    final crossed = _wasSettled == false && settledNow && !detail.debt.isClosed;
    _wasSettled = settledNow;
    if (!crossed) {
      return null;
    }
    return DebtSettledCelebration(
      debt: detail.debt,
      totalPaidMinor: detail.balance.totalDecreasesMinor,
      settledAt: DateTime.now(),
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

  /// The linked cuota's presentation view (HU-03), or null when the debt has
  /// no cuota configured. Only a projection of the domain's `DebtInstallment`;
  /// the cubit derives nothing new.
  DebtInstallmentView? _installmentView(DebtDetail detail) {
    final installment = detail.installment;
    if (installment == null) {
      return null;
    }
    return DebtInstallmentView(
      scheduledPaymentId: installment.scheduledPaymentId,
      amountMinor: installment.amountMinor,
      date: installment.nextDate,
      currency: installment.currency,
    );
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
