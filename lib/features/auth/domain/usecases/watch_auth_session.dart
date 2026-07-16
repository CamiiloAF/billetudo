import 'package:injectable/injectable.dart';

import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// The app-wide backup/sync session, watched by Ajustes, Más and Login to
/// decide what to show (HU-01: never a gate, only ever an invitation).
@injectable
class WatchAuthSession {
  const WatchAuthSession(this._repository);

  final AuthRepository _repository;

  Stream<AuthSession> call() => _repository.watchSession();

  AuthSession get current => _repository.currentSession;
}
