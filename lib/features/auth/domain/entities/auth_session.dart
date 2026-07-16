import 'package:equatable/equatable.dart';

import 'auth_user.dart';

enum AuthSessionStatus { signedOut, signedIn }

/// The app's current backup/sync session (HU-01, HU-06).
///
/// Signing out never touches local data — it only stops sync going forward —
/// so this entity has no bearing on whether the rest of the app has data to
/// show; it only decides whether Ajustes/Más show "Respaldar en la nube" or
/// the signed-in session card.
class AuthSession extends Equatable {
  const AuthSession.signedOut()
      : status = AuthSessionStatus.signedOut,
        user = null;

  const AuthSession.signedIn(AuthUser this.user)
      : status = AuthSessionStatus.signedIn;

  final AuthSessionStatus status;
  final AuthUser? user;

  bool get isSignedIn => status == AuthSessionStatus.signedIn;

  @override
  List<Object?> get props => [status, user];
}
