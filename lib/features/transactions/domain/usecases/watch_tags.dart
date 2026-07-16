import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/tag.dart';
import '../repositories/tag_repository.dart';

/// HU-07/HU-06: reactive list of tags, feeding both the assignment picker on
/// the transaction form and the tag filter.
@injectable
class WatchTags {
  const WatchTags(this._repository);

  final TagRepository _repository;

  Stream<Result<List<Tag>>> call() => _repository.watchTags();
}
