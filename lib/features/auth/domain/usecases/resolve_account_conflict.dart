import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Resolves a pending `AccountConflictDetected` outcome by wiping this
/// device's local data and completing the held-back sign-in. See
/// `AuthRepository.resolveAccountConflict`.
@injectable
class ResolveAccountConflict {
  const ResolveAccountConflict(this._repository);

  final AuthRepository _repository;

  FutureResult<AuthUser> call() => _repository.resolveAccountConflict();
}
