import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/tag.dart';
import '../repositories/scheduled_payment_repository.dart';

/// Reactive list of tags, alphabetically ordered, feeding the tag picker on
/// the template form. Mirrors `transactions/domain/usecases/watch_tags.dart`.
@injectable
class GetTags {
  const GetTags(this._repository);

  final ScheduledPaymentRepository _repository;

  Stream<Result<List<Tag>>> call() => _repository.watchTags();
}
