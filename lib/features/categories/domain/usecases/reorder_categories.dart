import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/category_repository.dart';

/// HU-05: persists the order the user dragged the categories into.
///
/// Same pattern as `ReorderAccounts`: takes the ids already in their final
/// order and hands them to the repository, which rewrites `sortOrder` as a
/// contiguous 0..n-1 sequence within their kind — gaps would make later
/// inserts ambiguous.
@injectable
class ReorderCategories {
  const ReorderCategories(this._repository);

  static const String orderedIdsField = 'orderedIds';

  final CategoryRepository _repository;

  FutureResult<Unit> call(List<String> orderedIds) {
    if (orderedIds.toSet().length != orderedIds.length) {
      return Future.value(
        const Left(
          ValidationFailure(
            'the new order cannot repeat a category',
            field: orderedIdsField,
          ),
        ),
      );
    }
    return _repository.reorderCategories(orderedIds);
  }
}
