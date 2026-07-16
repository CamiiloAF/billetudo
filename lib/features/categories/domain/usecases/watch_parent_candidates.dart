import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// Parent category picker (`Q55fEz`): root categories of `kind` only, not
/// tombstoned nor deleted, so a subcategory is only ever offered a valid
/// parent (HU-02/HU-03). `excludingId` omits a given id, so editing a root
/// category never offers itself as its own parent.
@injectable
class WatchParentCandidates {
  const WatchParentCandidates(this._repository);

  final CategoryRepository _repository;

  Stream<Result<List<Category>>> call(
    CategoryKind kind, {
    String? excludingId,
  }) =>
      _repository.watchParentCandidates(kind, excludingId: excludingId);
}
