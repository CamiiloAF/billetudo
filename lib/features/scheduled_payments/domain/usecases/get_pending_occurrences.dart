import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/pending_scheduled_occurrence.dart';
import '../repositories/scheduled_payment_repository.dart';

/// HU-03/HU-04: reactive list of pending occurrences across every
/// manual-mode template, ordered by effective due date ascending, for the
/// "Por confirmar" subpantalla and the list's "Zona de pendientes".
///
/// Only occurrences that are actually due (today or earlier) count as
/// "pendiente para confirmar" — a future one (e.g. snoozed past today) does
/// not surface here yet, even though it still sits `pending`/`snoozed` in
/// the ledger. With zero due occurrences the caller sees an empty list, and
/// "Zona de pendientes" does not render at all (spec: "0 pendientes: la
/// zona no se renderiza").
@injectable
class GetPendingOccurrences {
  const GetPendingOccurrences(this._repository);

  final ScheduledPaymentRepository _repository;

  Stream<Result<List<PendingScheduledOccurrence>>> call() =>
      _repository.watchPendingOccurrences().map(
            (result) => result.map(
              (items) => items
                  .where((item) => item.occurrence.isDueOn(DateTime.now()))
                  .toList(),
            ),
          );
}
