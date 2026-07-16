import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// HU-03: signs the user in with Apple. iOS only.
@injectable
class SignInWithApple {
  const SignInWithApple(this._repository);

  final AuthRepository _repository;

  FutureResult<AuthUser> call() => _repository.signInWithApple();
}
