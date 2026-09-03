import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/ai_access.dart';
import '../repositories/ai_repository.dart';

/// Asks the server whether the assistant is available for this user.
@injectable
class CheckAiAccess {
  const CheckAiAccess(this._repository);

  final AiRepository _repository;

  FutureResult<AiAccess> call() => _repository.checkAccess();
}
