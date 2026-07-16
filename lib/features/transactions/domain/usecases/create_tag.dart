import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/tag.dart';
import '../repositories/tag_repository.dart';

/// HU-07: creates a tag on the fly from the transaction form.
///
/// Validates the name (non-blank, within the schema's 60-character limit)
/// and reuses an existing tag of the same name (case-insensitive) instead of
/// creating a near-duplicate — the picker should never show "viaje" and
/// "Viaje" as two different tags because of how the user happened to type it.
@injectable
class CreateTag {
  const CreateTag(this._repository);

  final TagRepository _repository;

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
