import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/capture_learning_repository.dart';
import '../services/merchant_key.dart';

/// The category the user has been choosing for this merchant (HU-06).
///
/// Category is never inferred from the text of a notification: `RAPPI` does
/// not say whether it was groceries or a restaurant. The only source is what
/// the user themselves picked before, normalized through `merchantKeyFor` so
/// `Éxito Calle 80` and `EXITO  CALLE 80` are the same merchant.
///
/// Returns `null` when nothing was learned yet — the confirmation form then
/// asks for a category, which stays mandatory for income/expense. The result
/// is a visible suggestion, never a value imposed in silence.
@injectable
class SuggestCategoryForMerchant {
  const SuggestCategoryForMerchant(this._repository);

  final CaptureLearningRepository _repository;

  FutureResult<String?> call(String? merchantRaw) async {
    final key = merchantKeyFor(merchantRaw);
    if (key == null) {
      return const Right(null);
    }
    return _repository.suggestedCategoryFor(key);
  }
}
