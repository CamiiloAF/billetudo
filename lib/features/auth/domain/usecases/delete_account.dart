import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// HU-07 paso 1: deletes the user's account and all of their data in
/// Supabase. Irreversible; does not touch local data on its own.
@injectable
class DeleteAccount {
  const DeleteAccount(this._repository);

  final AuthRepository _repository;

  FutureResult<Unit> call() => _repository.deleteAccount();
}
