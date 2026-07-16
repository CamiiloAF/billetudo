import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/account_repository.dart';

/// HU-09: persists the order the user dragged the accounts into.
///
/// Takes the ids already in their final order and hands them to the repository,
/// which rewrites `sortOrder` as a contiguous 0..n-1 sequence — gaps would make
/// later inserts ambiguous.
@injectable
class ReorderAccounts {
  const ReorderAccounts(this._repository);

  static const String orderedIdsField = 'orderedIds';

  final AccountRepository _repository;

  FutureResult<Unit> call(List<String> orderedIds) {
    if (orderedIds.toSet().length != orderedIds.length) {
      return Future.value(
        const Left(
          ValidationFailure(
            'the new order cannot repeat an account',
            field: orderedIdsField,
          ),
        ),
      );
    }
    return _repository.reorderAccounts(orderedIds);
  }
}
