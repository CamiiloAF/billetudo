import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/capture_learning_repository.dart';
import '../services/merchant_key.dart';

/// Forgets what the app learned about one merchant (HU-06/HU-08).
///
/// The user must be able to undo a wrong association without wiping
/// everything, so this is the per-association counterpart of
/// `DeleteAllCaptureData`. Transactions already categorized keep their
/// category: those are recorded facts, not suggestions.
@injectable
class ForgetCaptureLearning {
  const ForgetCaptureLearning(this._repository);

  final CaptureLearningRepository _repository;

  FutureResult<Unit> call(String merchantRaw) async {
    final key = merchantKeyFor(merchantRaw);
    if (key == null) {
      return const Right(unit);
    }
    return _repository.forgetMerchant(key);
  }
}
