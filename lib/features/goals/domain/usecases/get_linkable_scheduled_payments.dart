import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import '../../../scheduled_payments/domain/usecases/get_linkable_scheduled_payments.dart'
    as scheduled_payments;

/// HU-16 "Enlazar existente" picker: Metas-owned wrapper over Pagos
/// Programados' [scheduled_payments.GetLinkableScheduledPayments], so the
/// presentation layer of this feature never imports another feature's
/// use case directly — same cross-feature pattern as `LinkTransactionToGoal`.
@injectable
class GetLinkableScheduledPayments {
  const GetLinkableScheduledPayments(this._delegate);

  final scheduled_payments.GetLinkableScheduledPayments _delegate;

  Stream<Result<List<ScheduledPaymentSummary>>> call() => _delegate();
}
