import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/sign_in_outcome.dart';
import '../repositories/auth_repository.dart';

/// HU-02: signs the user in with Google. May come back as
/// [AccountConflictDetected] instead of [SignedIn] — see
/// `AuthRepository.signInWithGoogle`.
@injectable
class SignInWithGoogle {
  const SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  FutureResult<SignInOutcome> call() => _repository.signInWithGoogle();
}
