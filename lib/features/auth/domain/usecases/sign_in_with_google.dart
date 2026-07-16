import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// HU-02: signs the user in with Google.
@injectable
class SignInWithGoogle {
  const SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  FutureResult<AuthUser> call() => _repository.signInWithGoogle();
}
