import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// Resolves a pending `AccountConflictDetected` outcome by closing the
/// just-exchanged session entirely, without touching this device's existing
/// local data and without completing the sign-in. See
/// `AuthRepository.cancelAccountConflict`.
@injectable
class CancelAccountConflict {
  const CancelAccountConflict(this._repository);

  final AuthRepository _repository;

  FutureResult<Unit> call() => _repository.cancelAccountConflict();
}
