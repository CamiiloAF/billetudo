import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_detail.dart';

/// The three states the debt detail renders (frames `cUzp6`/`ZQIPe`/`tVUoU`).
/// There is no "empty ledger": a debt always has at least its opening row.
/// `deleted` is a fourth, transient state (extension, HU-07's menu):
/// `DeleteDebt` succeeded and the page is about to pop, so `build` renders
/// nothing further for it.
enum DebtDetailStatus { loading, ready, failure, deleted }

/// The felicitación sheet's content (extension, HU-07, `C28Zt`), computed once
/// the balance crosses to settled — never re-derives a sign, only projects
/// `Debt`/`DebtBalance` fields the domain already resolved.
class DebtSettledCelebration extends Equatable {
  const DebtSettledCelebration({
    required this.debt,
    required this.totalPaidMinor,
    required this.settledAt,
  });

  final Debt debt;

  /// Everything that reduced the debt (`balance.totalDecreasesMinor`) — "Total
  /// pagado"/"Total cobrado".
  final int totalPaidMinor;

  /// The moment the balance crossed to settled — the end bound for
  /// `DebtFormat.duration(l10n, debt.effectiveStartDate, settledAt)`, which the
  /// sheet uses to render "8 meses" / "3 días".
  final DateTime settledAt;

  @override
  List<Object?> get props => [debt, totalPaidMinor, settledAt];
}

/// The linked installment shown in the "Próxima cuota" card. It comes from a
/// `ScheduledPayment` carrying this debt's id (HU-03), a cross-link that
/// `WatchDebtDetail` does not yet expose — so this stays `null` until the
/// Configurar-cuota flow wires it in.
class DebtInstallmentView extends Equatable {
  const DebtInstallmentView({
    required this.scheduledPaymentId,
    required this.amountMinor,
    required this.date,
    required this.currency,
  });

  final String scheduledPaymentId;
  final int amountMinor;
  final DateTime date;
  final String currency;

  @override
  List<Object?> get props => [scheduledPaymentId, amountMinor, date, currency];
}

class DebtDetailState extends Equatable {
  const DebtDetailState({
    this.status = DebtDetailStatus.loading,
    this.detail,
    this.runningBalances = const [],
    this.dailyGrowthMinor,
    this.installment,
    this.failure,
    this.actionFailure,
    this.celebration,
  });

  final DebtDetailStatus status;

  /// The debt, its derived balance and its newest-first unified ledger.
  final DebtDetail? detail;

  /// The running debt balance after each ledger row, aligned index-for-index
  /// with `detail.ledger` (newest-first). Derived from the domain's signed
  /// effects and the domain's outstanding total — never re-deriving any sign.
  final List<int> runningBalances;

  /// The estimated interest the debt accrues in one day, for the "Crece
  /// ~$X/día · estimado" line. `null` unless the debt accrues automatically
  /// with a positive rate over a positive balance.
  final int? dailyGrowthMinor;

  /// The linked installment card, or `null` when the debt has no cuota (or the
  /// linkage is not wired yet — see [DebtInstallmentView]).
  final DebtInstallmentView? installment;

  final Failure? failure;

  /// Set when "Cerrar deuda" (extension, HU-07) or the direct "Eliminar
  /// deuda" from the overflow menu fails — surfaced as a snackbar, distinct
  /// from [failure] (a load failure, which replaces the whole screen).
  /// Cleared once the page has consumed it via `DebtDetailCubit.
  /// dismissActionFailure`.
  final Failure? actionFailure;

  /// Set once, the moment a ready detail's balance crosses from not-settled to
  /// settled (extension, HU-07) — triggers the felicitación sheet. Cleared
  /// once the page has consumed it via `DebtDetailCubit.dismissCelebration`;
  /// the cubit itself never re-sets it for the same crossing.
  final DebtSettledCelebration? celebration;

  bool get isLoading => status == DebtDetailStatus.loading;

  DebtDetailState copyWith({
    DebtDetailStatus? status,
    DebtDetail? detail,
    List<int>? runningBalances,
    int? dailyGrowthMinor,
    DebtInstallmentView? installment,
    Failure? failure,
    Failure? Function()? actionFailure,
    DebtSettledCelebration? Function()? celebration,
  }) =>
      DebtDetailState(
        status: status ?? this.status,
        detail: detail ?? this.detail,
        runningBalances: runningBalances ?? this.runningBalances,
        dailyGrowthMinor: dailyGrowthMinor,
        installment: installment,
        failure: failure,
        actionFailure:
            actionFailure == null ? this.actionFailure : actionFailure(),
        celebration: celebration == null ? this.celebration : celebration(),
      );

  @override
  List<Object?> get props => [
        status,
        detail,
        runningBalances,
        dailyGrowthMinor,
        installment,
        failure,
        actionFailure,
        celebration,
      ];
}
