import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/pending_capture.dart';
import '../repositories/pending_capture_repository.dart';

/// The capture inbox (HU-04): every candidate waiting for a decision, most
/// recent first.
///
/// These are proposals, not movements: nothing in this list counts towards a
/// balance, a budget, a goal or a chart until the user confirms it.
@injectable
class WatchPendingCaptures {
  const WatchPendingCaptures(this._repository);

  final PendingCaptureRepository _repository;

  Stream<Result<List<PendingCapture>>> call() =>
      _repository.watchPendingCaptures();
}
