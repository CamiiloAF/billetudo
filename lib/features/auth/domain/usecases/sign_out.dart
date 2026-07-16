import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// HU-06: stops sync on this device without touching local data.
@injectable
class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  FutureResult<Unit> call() => _repository.signOut();
}
