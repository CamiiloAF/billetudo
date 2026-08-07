import 'package:injectable/injectable.dart';

import '../entities/delete_account_scope.dart';
import '../repositories/auth_repository.dart';

/// Decides, once, what "Eliminar cuenta" (HU-07) can actually delete on this
/// run — before paso 1 renders, so a signed-out device that used to have a
/// cloud account is warned instead of being shown a false "tu cuenta en la
/// nube fue eliminada" later in the flow.
@injectable
class GetDeleteAccountScope {
  const GetDeleteAccountScope(this._repository);

  final AuthRepository _repository;

  Future<DeleteAccountScope> call() async {
    if (_repository.currentSession.isSignedIn) {
      return DeleteAccountScope.cloudAndLocal;
    }
    final everSignedIn = await _repository.hasEverSignedIn();
    return everSignedIn
        ? DeleteAccountScope.localOnlySignedOut
        : DeleteAccountScope.localOnlyNeverSignedIn;
  }
}
