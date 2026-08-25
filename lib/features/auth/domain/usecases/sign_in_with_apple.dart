import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/sign_in_outcome.dart';
import '../repositories/auth_repository.dart';

/// HU-03: signs the user in with Apple. iOS only. May come back as
/// [AccountConflictDetected] instead of [SignedIn] — see
/// `AuthRepository.signInWithApple`.
@injectable
class SignInWithApple {
  const SignInWithApple(this._repository);

  final AuthRepository _repository;

  FutureResult<SignInOutcome> call() => _repository.signInWithApple();
}
