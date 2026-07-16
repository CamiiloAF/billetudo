import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/category_repository.dart';

/// HU-06: seeds the onboarding set of common categories, only the first time
/// — a user that already has any category (of any kind) keeps whatever they
/// already built, so this call is a safe no-op on every later run.
@injectable
class SeedDefaultCategories {
  const SeedDefaultCategories(this._repository);

  final CategoryRepository _repository;

  FutureResult<Unit> call() async {
    final hasAnyResult = await _repository.hasAnyCategory();
    if (hasAnyResult case Left(value: final failure)) {
      return Left(failure);
    }
    final hasAny = hasAnyResult.getOrElse(
      (_) => throw StateError('unreachable: hasAnyResult is Left'),
    );
    if (hasAny) {
      return const Right(unit);
    }
    return _repository.seedDefaultCategories();
  }
}
