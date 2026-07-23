import 'package:equatable/equatable.dart';

/// The scheduled payment linked to a debt as its cuota (HU-03), reduced to what
/// the detail's "Próxima cuota" card needs: which scheduled payment it is, the
/// amount, the next due date and the currency.
///
/// The cuota IS a `ScheduledPayment` (Pagos Programados owns its lifecycle);
/// this is only the Deudas-side view of it, so the debt detail never depends on
/// the Pagos Programados domain. `null` on `DebtDetail` when the debt has no
/// cuota configured yet.
class DebtInstallment extends Equatable {
  const DebtInstallment({
    required this.scheduledPaymentId,
    required this.amountMinor,
    required this.nextDate,
    required this.currency,
  });

  /// The linked `ScheduledPayment` id — the cross-link into Pagos programados.
  final String scheduledPaymentId;

  /// Always a positive integer of cents.
  final int amountMinor;

  /// The template cursor's next due date — the "próxima cuota" date shown.
  final DateTime nextDate;

  final String currency;

  @override
  List<Object?> get props => [scheduledPaymentId, amountMinor, nextDate, currency];
}
