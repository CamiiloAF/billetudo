import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../scheduled_payments/domain/repositories/scheduled_payment_repository.dart';

/// How many scheduled-payment occurrences are due for confirmation right
/// now, for `QuickAccessRow`'s "Pagos programados" badge (`njGBt`).
///
/// Counts the exact same set `GetPendingOccurrences` surfaces to the "por
/// confirmar" screen — due today or earlier, across every manual-mode
/// template — so the badge and the list it points to never disagree. The
/// "9+" cap and the "no badge on zero" rule both belong to the widget, not
/// here: this only ever returns the true count.
@injectable
class WatchPendingScheduledPaymentCount {
  const WatchPendingScheduledPaymentCount(this._repository);

  final ScheduledPaymentRepository _repository;

  Stream<Result<int>> call() => _repository.watchPendingOccurrences().map(
        (result) => result.map(
          (items) => items
              .where((item) => item.occurrence.isDueOn(DateTime.now()))
              .length,
        ),
      );
}
