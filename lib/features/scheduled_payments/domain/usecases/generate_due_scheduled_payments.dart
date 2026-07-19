import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/scheduled_payment_repository.dart';

/// HU-02: catch-up run, meant to be called once when the app opens. Every
/// due date since the last run is processed exactly once — none lost, none
/// duplicated if the app closes mid-run (criterion 5) — either generating a
/// transaction (automatic mode) or accumulating a pending occurrence
/// (manual mode).
@injectable
class GenerateDueScheduledPayments {
  const GenerateDueScheduledPayments(this._repository);

  final ScheduledPaymentRepository _repository;

  FutureResult<Unit> call({DateTime? now}) =>
      _repository.generateDueScheduledPayments(now: now ?? DateTime.now());
}
