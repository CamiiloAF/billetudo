import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/scheduled_payment_repository.dart';

/// HU-05: deletes a template, stopping future generation while preserving
/// `scheduledPaymentId` as a historical reference on transactions already
/// generated from it.
///
/// Stamps `tombstonedAt`, never `deletedAt`: `Transactions.scheduledPaymentId`
/// references this row by foreign key (see `_SyncColumns.tombstonedAt`), so
/// this is the referential-integrity tombstone, not the reversible UX trash
/// — this feature offers no "restore a deleted template" flow.
@injectable
class DeleteScheduledPayment {
  const DeleteScheduledPayment(this._repository);

  final ScheduledPaymentRepository _repository;

  FutureResult<Unit> call(String id) => _repository.deleteScheduledPayment(id);
}
