import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

/// HU-07 paso 2: wipes every local row on this device, when the user
/// explicitly picks "Borrar también los datos de este dispositivo" after the
/// cloud account is already gone.
@injectable
class WipeLocalData {
  const WipeLocalData(this._repository);

  final AuthRepository _repository;

  FutureResult<Unit> call() => _repository.wipeLocalData();
}
