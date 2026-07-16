import '../../../../core/error/result.dart';
import '../entities/tag.dart';

/// Contract for the free-form Tags feature (HU-07). Implemented in `data/`
/// over Drift.
abstract class TagRepository {
  /// All tags, alphabetically ordered — feeds both the tag picker on the
  /// transaction form and the tag filter of HU-06.
  Stream<Result<List<Tag>>> watchTags();

  /// A tag by (case-insensitive) name, if one already exists. Lets
  /// `CreateTag` reuse an existing tag instead of creating a near-duplicate
  /// when the user types a name that already exists.
  FutureResult<Tag?> findTagByName(String name);

  /// Persists a new tag (HU-07: created on the fly from the transaction
  /// form).
  FutureResult<Tag> createTag(String name);
}
