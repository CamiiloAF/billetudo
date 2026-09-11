import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/capture_learning_repository.dart';
import '../services/merchant_key.dart';

/// Remembers the category the user picked for a merchant (HU-06), so the next
/// capture from the same place arrives pre-categorized.
///
/// Only ever called from a confirmation the user went through: the app learns
/// from decisions, never from its own guesses, otherwise a bad suggestion
/// would reinforce itself. A merchant that normalizes to nothing, or a
/// confirmation with no category (a transfer), teaches nothing and is a
/// silent no-op rather than an error — the user confirmed their transaction
/// either way.
@injectable
class LearnMerchantCategory {
  const LearnMerchantCategory(this._repository);

  final CaptureLearningRepository _repository;

  FutureResult<Unit> call({
    required String? merchantRaw,
    required String? categoryId,
  }) async {
    final key = merchantKeyFor(merchantRaw);
    final category = categoryId?.trim();
    if (key == null || category == null || category.isEmpty) {
      return const Right(unit);
    }
    return _repository.learnMerchantCategory(
      merchantKey: key,
      categoryId: category,
    );
  }
}
