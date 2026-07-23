import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../domain/entities/debt_detail.dart';

/// The three states the debt detail renders (frames `cUzp6`/`ZQIPe`/`tVUoU`).
/// There is no "empty ledger": a debt always has at least its opening row.
enum DebtDetailStatus { loading, ready, failure }

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
    this.accounts = const [],
    this.failure,
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

  /// Active accounts, for the retro-link account picker (item 2). Loaded once
  /// when the detail cubit starts.
  final List<AccountWithBalance> accounts;

  final Failure? failure;

  bool get isLoading => status == DebtDetailStatus.loading;

  DebtDetailState copyWith({
    DebtDetailStatus? status,
    DebtDetail? detail,
    List<int>? runningBalances,
    int? dailyGrowthMinor,
    DebtInstallmentView? installment,
    List<AccountWithBalance>? accounts,
    Failure? failure,
  }) =>
      DebtDetailState(
        status: status ?? this.status,
        detail: detail ?? this.detail,
        runningBalances: runningBalances ?? this.runningBalances,
        dailyGrowthMinor: dailyGrowthMinor,
        installment: installment,
        accounts: accounts ?? this.accounts,
        failure: failure,
      );

  @override
  List<Object?> get props => [
        status,
        detail,
        runningBalances,
        dailyGrowthMinor,
        installment,
        accounts,
        failure,
      ];
}
