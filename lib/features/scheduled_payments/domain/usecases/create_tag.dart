import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/tag.dart';
import '../repositories/scheduled_payment_repository.dart';

/// Creates a tag on the fly from the template form, reusing an existing tag
/// of the same name (case-insensitive) instead of creating a near-duplicate.
///
/// Split out from `GetTags` on purpose: CLAUDE.md requires one use case per
/// business action even for a pair as small as "list" and "create" — the
/// same reason Transacciones keeps `WatchTags`/`CreateTag` separate. Mirrors
/// `transactions/domain/usecases/create_tag.dart`.
@injectable
class CreateTag {
  const CreateTag(this._repository);

  final ScheduledPaymentRepository _repository;

  static const int maxNameLength = 60;

  FutureResult<Tag> call(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Left(ValidationFailure('tag name is required'));
    }
    if (trimmed.length > maxNameLength) {
      return const Left(
        ValidationFailure('tag name exceeds $maxNameLength characters'),
      );
    }

    final existingResult = await _repository.findTagByName(trimmed);
    if (existingResult case Left(value: final failure)) {
      return Left(failure);
    }
    final existing = existingResult.getOrElse((_) => null);
    if (existing != null) {
      return Right(existing);
    }
    return _repository.createTag(trimmed);
  }
}
